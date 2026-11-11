<#
.SYNOPSIS
  Lance une commande dbt chronometree et l'enregistre dans results\runs.csv.

.DESCRIPTION
  Chaque moteur a son dataset cible (eth_v1 / eth_v2) et son dossier d'artefacts
  (target_v1 / target_v2). Ne lancez jamais deux mesures en parallele : la collecte
  BigQuery (collect.ps1) se base sur la fenetre de temps de chaque execution.

.EXAMPLE
  .\scripts\bench.ps1 -Engine v1 -Scenario full_refresh -DbtArgs "build --full-refresh"
  .\scripts\bench.ps1 -Engine v2 -Scenario full_refresh -DbtArgs "build --full-refresh"
#>
param(
    [Parameter(Mandatory = $true)][ValidateSet('v1', 'v2')][string]$Engine,
    [Parameter(Mandatory = $true)][string]$Scenario,
    [Parameter(Mandatory = $true)][string]$DbtArgs,
    [string]$ProjectDir = (Split-Path $PSScriptRoot -Parent),
    [string]$V1Exe = '',
    [string]$V2Exe = (Join-Path $env:USERPROFILE '.local\bin\dbt.exe')
)

. (Join-Path $PSScriptRoot '_env.ps1')

if (-not $V1Exe) { $V1Exe = Join-Path $ProjectDir '.venv\Scripts\dbt.exe' }
$exe = if ($Engine -eq 'v1') { $V1Exe } else { $V2Exe }
$targetPath = "target_$Engine"
$dbtArgList = @($DbtArgs -split '\s+' | Where-Object { $_ }) + @('--target', $Engine, '--target-path', $targetPath, '--profiles-dir', $ProjectDir)

$resultsDir = Join-Path $ProjectDir 'results'
New-Item -ItemType Directory -Force $resultsDir | Out-Null
$runsFile = Join-Path $resultsDir 'runs.csv'

Push-Location $ProjectDir
try {
    $startUtc = [DateTime]::UtcNow
    & $exe @dbtArgList
    $exitCode = $LASTEXITCODE
    $endUtc = [DateTime]::UtcNow
}
finally {
    Pop-Location
}

# Statuts par noeud (success, skipped, reused...) si la commande a produit run_results.json
$statuses = ''
$runResults = Join-Path $ProjectDir "$targetPath\run_results.json"
if ((Test-Path $runResults) -and ((Get-Item $runResults).LastWriteTimeUtc -ge $startUtc.AddSeconds(-1))) {
    $parsed = Get-Content $runResults -Raw | ConvertFrom-Json
    $statuses = ($parsed.results | Group-Object status | Sort-Object Name |
        ForEach-Object { "$($_.Name)=$($_.Count)" }) -join ';'
}

$row = [pscustomobject]@{
    run_id       = $startUtc.ToString('yyyyMMdd_HHmmss')
    engine       = $Engine
    scenario     = $Scenario
    dbt_args     = $DbtArgs
    start_utc    = $startUtc.ToString('yyyy-MM-dd HH:mm:ss.fff')
    end_utc      = $endUtc.ToString('yyyy-MM-dd HH:mm:ss.fff')
    wall_seconds = [math]::Round(($endUtc - $startUtc).TotalSeconds, 2).ToString([cultureinfo]::InvariantCulture)
    exit_code    = $exitCode
    node_status  = $statuses
}
$row | Export-Csv -Path $runsFile -Append -NoTypeInformation -Encoding UTF8

Write-Host ""
Write-Host ("[{0}] {1} : {2} s (code {3}) {4}" -f $Engine, $Scenario, $row.wall_seconds, $exitCode, $statuses)
exit $exitCode
