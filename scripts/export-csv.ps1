param()
$ErrorActionPreference = 'Continue'

function Write-Info($msg) { Write-Host $msg }
function Write-Err($msg)  { Write-Host $msg; exit 1 }

$projectDir = Split-Path -Parent $PSScriptRoot
$exportDir  = Join-Path $projectDir 'exports'
if (-not (Test-Path $exportDir)) { New-Item -ItemType Directory -Path $exportDir | Out-Null }

$timestamp = (Get-Date -Format 'yyyyMMdd_HHmmss')

$mysqlDb   = $env:MYSQL_DATABASE; if (-not $mysqlDb)   { $mysqlDb = 'limesurvey' }
$mysqlUser = $env:MYSQL_USER;     if (-not $mysqlUser) { $mysqlUser = 'limesurvey' }
$mysqlPass = $env:MYSQL_PASSWORD; if (-not $mysqlPass) { $mysqlPass = 'limepass' }

Write-Info '[ETAPE] Export CSV des reponses...'

# Presence conteneur
$inspect = & docker inspect limesurvey-db 2>$null
if ($LASTEXITCODE -ne 0) { Write-Err '[ERREUR] Conteneur limesurvey-db introuvable. Demarrer via scripts\start-limesurvey.bat' }

# Etat conteneur
$state = (& docker inspect --format='{{.State.Running}}' limesurvey-db 2>$null).Trim()
if ($state -ne 'true') { Write-Err "[ERREUR] LimeSurvey non demarre (limesurvey-db) - etat=`"$state`"" }
Write-Info '[OK] Conteneur MySQL actif'

# Liste des tables de reponses
Write-Info '[INFO] Recuperation des tables de reponses...'
$tableList = & docker exec limesurvey-db mysql -u "$mysqlUser" -p"$mysqlPass" "$mysqlDb" -N -e "SHOW TABLES LIKE 'lime_survey_%';" 2>$null
if ($LASTEXITCODE -ne 0) { Write-Err '[ERREUR] Impossible de lister les tables' }

$tables = $tableList -split "`n" | Where-Object { $_ -match '^lime_survey_[0-9]+$' }
if (-not $tables -or $tables.Count -eq 0) {
    Write-Info '[INFO] Aucune table de reponses (lime_survey_*) trouvee.'
    Write-Info "OK: Export termine dans $exportDir\"
    exit 0
}

$converter = Join-Path $PSScriptRoot 'convert-mysql-tsv-to-csv.py'
$tempTsv = [System.IO.Path]::GetTempFileName()

foreach ($table in $tables) {
    $surveyId = $table -replace '^lime_survey_', ''
    $outCsv = Join-Path $exportDir ("reponses_{0}_{1}.csv" -f $surveyId, $timestamp)

    $rowcount = (& docker exec limesurvey-db mysql -u "$mysqlUser" -p"$mysqlPass" "$mysqlDb" -N -B -e "SELECT COUNT(*) FROM $table;" 2>$null).Trim()
    if (-not $rowcount) { $rowcount = '0' }

    & docker exec limesurvey-db mysql -u "$mysqlUser" -p"$mysqlPass" "$mysqlDb" -B -e "SELECT * FROM $table;" 2>$null | Out-File -FilePath $tempTsv -Encoding utf8
    if ($LASTEXITCODE -ne 0) { Write-Err "[ERREUR] Echec SELECT sur $table" }

    & python "$converter" "$tempTsv" "$outCsv"
    if ($LASTEXITCODE -ne 0) { Write-Err "[ERREUR] Conversion CSV echouee pour $table" }

    $size = (Get-Item $outCsv).Length
    if ($size -gt 0) {
        Write-Info "  -> $outCsv ($rowcount reponses)"
    } else {
        Remove-Item $outCsv -ErrorAction SilentlyContinue
    }
}

Remove-Item $tempTsv -ErrorAction SilentlyContinue
Write-Info "OK: Export termine dans $exportDir\"
exit 0
