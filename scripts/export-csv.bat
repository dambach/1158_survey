@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

REM Export CSV des reponses - Windows
REM Usage: scripts\export-csv.bat

set "EXPORT_DIR=.\exports"

REM Horodatage (PowerShell, fallback WMIC)
set "TIMESTAMP="
for /f %%I in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss" 2^>nul') do set "TIMESTAMP=%%I"
if "%TIMESTAMP%"=="" (
    for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value 2^>nul') do set "datetime=%%I"
    if defined datetime set "TIMESTAMP=%datetime:~0,8%_%datetime:~8,6%"
)
if "%TIMESTAMP%"=="" set "TIMESTAMP=unknown_%RANDOM%"

if "%MYSQL_DATABASE%"=="" set "MYSQL_DATABASE=limesurvey"
if "%MYSQL_USER%"=="" set "MYSQL_USER=limesurvey"
if "%MYSQL_PASSWORD%"=="" set "MYSQL_PASSWORD=limepass"

if not exist "%EXPORT_DIR%" mkdir "%EXPORT_DIR%"

echo [ETAPE] Export CSV des reponses...

echo [TEST] Presence du conteneur MySQL...
docker inspect limesurvey-db >nul 2>&1 || (echo [ERREUR] Conteneur limesurvey-db introuvable. Demarrer via scripts\start-limesurvey.bat & exit /b 1)

echo [TEST] Etat du conteneur MySQL...
echo [DEBUG] step-state-start
set "RUNNING_STATE=unknown"
set "STATE_FILE=%TEMP%\ls_state.txt"
del "%STATE_FILE%" 2>nul
docker inspect --format={{.State.Running}} limesurvey-db > "%STATE_FILE%" 2>nul
if exist "%STATE_FILE%" set /p RUNNING_STATE=<"%STATE_FILE%"
del "%STATE_FILE%" 2>nul
echo [DEBUG] state-read="%RUNNING_STATE%"
if /i "%RUNNING_STATE%" NEQ "true" (
    echo [ERREUR] LimeSurvey non demarre ^(limesurvey-db^) - etat="%RUNNING_STATE%"
    exit /b 1
)
echo [OK] Conteneur MySQL actif
echo [DEBUG] step-state-end

set "TABLE_LIST=%TEMP%\ls_tables.txt"
set "TABLE_ERR=%TEMP%\ls_tables.err"
del "%TABLE_LIST%" "%TABLE_ERR%" 2>nul

echo [INFO] Recuperation des tables de reponses...
docker exec limesurvey-db mysql -u "%MYSQL_USER%" -p"%MYSQL_PASSWORD%" "%MYSQL_DATABASE%" -N -e "SHOW TABLES LIKE 'lime_survey_%%';" > "%TABLE_LIST%" 2> "%TABLE_ERR%"
if errorlevel 1 (
    echo [ERREUR] Impossible de lister les tables:
    type "%TABLE_ERR%" 2>nul
    del "%TABLE_LIST%" "%TABLE_ERR%" 2>nul
    exit /b 1
)

set "FOUND_TABLE=false"
for /f "usebackq delims=" %%t in ("%TABLE_LIST%") do call :EXPORT_TABLE "%%t" || exit /b 1

if /i "%FOUND_TABLE%"=="false" (
    echo [INFO] Aucune table de reponses ^(lime_survey_*^) trouvee.
    del "%TABLE_LIST%" "%TABLE_ERR%" 2>nul
    echo.
    echo OK: Export termine dans %EXPORT_DIR%\
    exit /b 0
)

del "%TABLE_LIST%" "%TABLE_ERR%" 2>nul
echo.
echo OK: Export termine dans %EXPORT_DIR%\
exit /b 0

:EXPORT_TABLE
set "TABLE=%~1"
set "SURVEY_ID=%TABLE:lime_survey_=%"
echo %SURVEY_ID%| findstr /r "^[0-9][0-9]*$" >nul
if errorlevel 1 exit /b 0

set "FOUND_TABLE=true"
set "OUTPUT_FILE=%EXPORT_DIR%\reponses_%SURVEY_ID%_%TIMESTAMP%.csv"
set "ROWCOUNT=0"
set "COUNT_FILE=%TEMP%\\ls_rowcount.txt"
del "%COUNT_FILE%" 2>nul
docker exec limesurvey-db mysql -u "%MYSQL_USER%" -p"%MYSQL_PASSWORD%" "%MYSQL_DATABASE%" -N -B -e "SELECT COUNT(*) FROM %TABLE%;" > "%COUNT_FILE%" 2> "%TABLE_ERR%"
if errorlevel 1 (
    echo [ERREUR] Echec COUNT sur %TABLE% ; details :
    type "%TABLE_ERR%" 2>nul
    del "%COUNT_FILE%" "%TABLE_ERR%" 2>nul
    exit /b 1
)
for /f "usebackq delims=" %%R in ("%COUNT_FILE%") do set "ROWCOUNT=%%R"
del "%COUNT_FILE%" 2>nul

docker exec limesurvey-db mysql -u "%MYSQL_USER%" -p"%MYSQL_PASSWORD%" "%MYSQL_DATABASE%" -B -e "SELECT * FROM %TABLE%;" > "%OUTPUT_FILE%.tmp" 2> "%TABLE_ERR%"
if errorlevel 1 (
    echo [ERREUR] Echec SELECT sur %TABLE% ; details :
    type "%TABLE_ERR%" 2>nul
    del "%OUTPUT_FILE%.tmp" "%TABLE_ERR%" 2>nul
    exit /b 1
)

python "%~dp0convert-mysql-tsv-to-csv.py" "%OUTPUT_FILE%.tmp" "%OUTPUT_FILE%"
if errorlevel 1 (
    echo [ERREUR] Conversion TSV->CSV echouee pour %TABLE%
    del "%OUTPUT_FILE%.tmp" "%OUTPUT_FILE%" "%TABLE_ERR%" 2>nul
    exit /b 1
)
del "%OUTPUT_FILE%.tmp" 2>nul

set "SIZE=0"
for %%F in ("%OUTPUT_FILE%") do set "SIZE=%%~zF"
if %SIZE% gtr 0 (
    echo   -^> %OUTPUT_FILE% ^(%ROWCOUNT% reponses^)
) else (
    del "%OUTPUT_FILE%" 2>nul
)

goto :eof
