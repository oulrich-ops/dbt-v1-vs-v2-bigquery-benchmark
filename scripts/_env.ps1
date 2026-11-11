# Charge la configuration locale (env.local.ps1 a la racine du projet) et verifie
# que les deux variables necessaires sont definies.
$envFile = Join-Path (Split-Path $PSScriptRoot -Parent) 'env.local.ps1'
if (Test-Path $envFile) { . $envFile }

foreach ($name in @('DBT_BQ_PROJECT', 'DBT_BQ_KEYFILE')) {
    if (-not [Environment]::GetEnvironmentVariable($name, 'Process')) {
        throw "Variable $name absente. Copiez env.example.ps1 vers env.local.ps1 et renseignez vos valeurs."
    }
}
