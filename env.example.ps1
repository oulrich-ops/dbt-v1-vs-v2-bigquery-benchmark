# Copiez ce fichier vers env.local.ps1 (ignore par git) et renseignez vos valeurs.
# Les scripts du dossier scripts le chargent automatiquement.
# Pour lancer dbt a la main, chargez-le d'abord :  . .\env.local.ps1

# Identifiant de votre projet Google Cloud
$env:DBT_BQ_PROJECT = 'mon-projet-gcp'

# Chemin du fichier de cle JSON du compte de service utilise par dbt
$env:DBT_BQ_KEYFILE = 'C:/chemin/vers/cle-compte-de-service.json'
