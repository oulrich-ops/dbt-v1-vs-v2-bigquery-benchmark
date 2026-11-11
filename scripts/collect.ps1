<#
.SYNOPSIS
  Complete results\runs.csv avec les statistiques BigQuery de chaque execution
  (jobs, Go factures, secondes de slot) et ecrit results\metrics.csv.

.DESCRIPTION
  Les jobs sont retrouves dans INFORMATION_SCHEMA.JOBS_BY_PROJECT par fenetre de
  temps et par compte de service dbt, en UNE seule requete (cette vue est lente :
  compter une a deux minutes). Attendez une minute apres la derniere execution :
  la vue peut avoir un leger retard.
#>
param(
    [string]$ProjectDir = (Split-Path $PSScriptRoot -Parent),
    [string]$Project = '',
    [string]$Keyfile = ''
)

. (Join-Path $PSScriptRoot '_env.ps1')
if (-not $Project) { $Project = $env:DBT_BQ_PROJECT }
if (-not $Keyfile) { $Keyfile = $env:DBT_BQ_KEYFILE }

# Le SQL passe par un fichier temporaire sans BOM : un pipe PowerShell 5.1
# ajouterait un caractere invisible en tete de requete.
function Invoke-BqQuery([string]$sql, [string]$options) {
    $tmp = [IO.Path]::GetTempFileName()
    try {
        [IO.File]::WriteAllText($tmp, $sql, (New-Object System.Text.UTF8Encoding $false))
        cmd /c "bq --quiet query --project_id=$Project --use_legacy_sql=false $options < `"$tmp`""
    }
    finally {
        Remove-Item $tmp -ErrorAction SilentlyContinue
    }
}

$runsFile = Join-Path $ProjectDir 'results\runs.csv'
$metricsFile = Join-Path $ProjectDir 'results\metrics.csv'
if (-not (Test-Path $runsFile)) { throw "Aucune execution enregistree : $runsFile est absent." }

$serviceAccount = (Get-Content $Keyfile -Raw | ConvertFrom-Json).client_email
$runs = @(Import-Csv $runsFile)

$structs = ($runs | ForEach-Object {
        "struct('$($_.run_id)_$($_.engine)' as run_key, timestamp('$($_.start_utc)') as start_ts, timestamp('$($_.end_utc)') as end_ts)"
    }) -join ",`n  "
$minStart = ($runs | ForEach-Object { $_.start_utc } | Sort-Object | Select-Object -First 1)
$maxEnd = ($runs | ForEach-Object { $_.end_utc } | Sort-Object | Select-Object -Last 1)

$sql = @"
with runs as (
  select * from unnest([
  $structs
  ])
),
jobs as (
  select creation_time, statement_type, total_bytes_billed, total_bytes_processed, total_slot_ms
  from ``region-us``.INFORMATION_SCHEMA.JOBS_BY_PROJECT
  where creation_time between timestamp_sub(timestamp('$minStart'), interval 1 minute)
                          and timestamp_add(timestamp('$maxEnd'), interval 1 minute)
    and user_email = '$serviceAccount'
    and job_type = 'QUERY'
    and (statement_type is null or statement_type != 'SCRIPT')
)
select
  runs.run_key,
  count(jobs.creation_time) as bq_jobs,
  countif(jobs.statement_type in ('CREATE_TABLE_AS_SELECT', 'CREATE_TABLE', 'CREATE_VIEW', 'MERGE', 'INSERT', 'DELETE')) as bq_write_jobs,
  round(coalesce(sum(jobs.total_bytes_billed), 0) / 1e9, 2) as gb_billed,
  round(coalesce(sum(jobs.total_bytes_processed), 0) / 1e9, 2) as gb_processed,
  round(coalesce(sum(jobs.total_slot_ms), 0) / 1000, 1) as slot_seconds
from runs
left join jobs
  on jobs.creation_time between timestamp_sub(runs.start_ts, interval 2 second)
                            and timestamp_add(runs.end_ts, interval 2 second)
group by 1
"@

Write-Host "Interrogation de l'historique des jobs BigQuery (une a deux minutes)..."
$csv = Invoke-BqQuery $sql '--location=US --format=csv --max_rows=10000'
if ($LASTEXITCODE -ne 0) { throw "Echec de la collecte : $csv" }
$stats = @{}
$csv | Where-Object { $_ } | ConvertFrom-Csv | ForEach-Object { $stats[$_.run_key] = $_ }

$rows = foreach ($run in $runs) {
    $s = $stats["$($run.run_id)_$($run.engine)"]
    [pscustomobject]@{
        run_id        = $run.run_id
        engine        = $run.engine
        scenario      = $run.scenario
        dbt_args      = $run.dbt_args
        wall_seconds  = $run.wall_seconds
        exit_code     = $run.exit_code
        node_status   = $run.node_status
        bq_jobs       = $s.bq_jobs
        bq_write_jobs = $s.bq_write_jobs
        gb_billed     = $s.gb_billed
        gb_processed  = $s.gb_processed
        slot_seconds  = $s.slot_seconds
    }
}

$rows | Export-Csv -Path $metricsFile -NoTypeInformation -Encoding UTF8
$rows | Format-Table engine, scenario, wall_seconds, bq_write_jobs, gb_billed, slot_seconds, node_status -AutoSize
Write-Host "Ecrit : $metricsFile"
