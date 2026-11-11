<#
.SYNOPSIS
  Copie une tranche de bigquery-public-data.crypto_ethereum dans le dataset brut du projet.

.DESCRIPTION
  - Cree les datasets eth_raw / eth_v1 / eth_v2 (region US) s'ils n'existent pas.
  - Pour chaque source, remplace les jours [Start, End] (rejouable sans doublons).
  - Chaque ligne recoit _loaded_at = heure du chargement (sert a la fraicheur des sources).
  - "tokens" est une petite dimension : elle est recopiee en entier a chaque appel.

.EXAMPLE
  # Estimation sans rien executer ni facturer
  .\scripts\load_raw.ps1 -Start 2024-01-01 -End 2024-01-24 -DryRun

.EXAMPLE
  # Chargement initial (~105 Go)
  .\scripts\load_raw.ps1 -Start 2024-01-01 -End 2024-01-24

.EXAMPLE
  # Simuler l'arrivee d'un jour de donnees sur UNE seule source
  .\scripts\load_raw.ps1 -Start 2024-01-25 -End 2024-01-25 -Sources token_transfers
#>
param(
    [Parameter(Mandatory = $true)][string]$Start,
    [Parameter(Mandatory = $true)][string]$End,
    [string[]]$Sources = @('transactions', 'token_transfers', 'logs', 'blocks', 'tokens'),
    [string]$Project = '',
    [string]$RawDataset = 'eth_raw',
    [switch]$DryRun
)

. (Join-Path $PSScriptRoot '_env.ps1')
if (-not $Project) { $Project = $env:DBT_BQ_PROJECT }

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

$public = 'bigquery-public-data.crypto_ethereum'

# ts = colonne de partition ; cols = colonnes copiees ; cluster = colonne de clustering
$spec = @{
    transactions    = @{ ts = 'block_timestamp'; cols = '*'; cluster = 'from_address' }
    token_transfers = @{ ts = 'block_timestamp'; cols = '*'; cluster = 'token_address' }
    logs            = @{ ts = 'block_timestamp'; cols = '*'; cluster = 'address' }
    blocks          = @{ ts = 'timestamp'; cols = '`timestamp`, number, `hash`, miner, size, gas_limit, gas_used, transaction_count, base_fee_per_gas, blob_gas_used'; cluster = 'miner' }
}

function Get-DryRunGb([string]$sql) {
    $json = Invoke-BqQuery $sql '--dry_run --format=json'
    if ($LASTEXITCODE -ne 0) { throw "Echec de l'estimation : $json" }
    $bytes = [double](($json | ConvertFrom-Json).statistics.totalBytesProcessed)
    return [math]::Round($bytes / 1e9, 2)
}

if (-not $DryRun) {
    foreach ($ds in @($RawDataset, 'eth_v1', 'eth_v2')) {
        bq mk --force --location=US --dataset "${Project}:$ds" | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "Impossible de creer le dataset $ds" }
    }
}

$totalGb = 0
foreach ($source in $Sources) {
    $target = "``$Project.$RawDataset.$source``"

    if ($source -eq 'tokens') {
        $select = "select address, symbol, name, decimals, block_number, current_timestamp() as _loaded_at from ``$public.tokens``"
        $script = "create or replace table $target as $select;"
    }
    elseif ($spec.ContainsKey($source)) {
        $s = $spec[$source]
        $base = "select $($s.cols), current_timestamp() as _loaded_at from ``$public.$source``"
        $range = "date($($s.ts)) between '$Start' and '$End'"
        $select = "$base where $range"
        $script = @"
create table if not exists $target
partition by date($($s.ts))
cluster by $($s.cluster)
as $base where false;

delete from $target where $range;

insert into $target $select;
"@
    }
    else {
        throw "Source inconnue : $source"
    }

    $gb = Get-DryRunGb $select
    $totalGb += $gb
    Write-Host ("{0,-16} {1,8} Go a lire" -f $source, $gb)

    if (-not $DryRun) {
        $started = Get-Date
        Invoke-BqQuery $script '--location=US --format=none'
        if ($LASTEXITCODE -ne 0) { throw "Echec du chargement de $source" }
        Write-Host ("{0,-16} charge en {1:n0} s" -f $source, ((Get-Date) - $started).TotalSeconds)
    }
}

Write-Host ("TOTAL            {0,8} Go" -f [math]::Round($totalGb, 2))
if ($DryRun) { Write-Host "Mode -DryRun : rien n'a ete execute." }
