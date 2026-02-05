@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

REM Sauvegarde LimeSurvey - Windows
REM Usage: scripts\backup-data.bat

set BACKUP_DIR=.\backups

REM Horodatage compatible Windows 10/11 (fallback WMIC)
set TIMESTAMP=
for /f %%I in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss" 2^>nul') do set TIMESTAMP=%%I
if "%TIMESTAMP%"=="" (
    for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value 2^>nul') do set datetime=%%I
    if defined datetime set TIMESTAMP=%datetime:~0,8%_%datetime:~8,6%
)
if "%TIMESTAMP%"=="" set TIMESTAMP=unknown_%RANDOM%

set BACKUP_NAME=limesurvey_backup_%TIMESTAMP%

if "%MYSQL_DATABASE%"=="" set MYSQL_DATABASE=limesurvey
if "%MYSQL_USER%"=="" set MYSQL_USER=limesurvey
if "%MYSQL_PASSWORD%"=="" set MYSQL_PASSWORD=limepass

echo ==========================================
echo Backup LimeSurvey Lab - %TIMESTAMP%
echo ==========================================
echo.

REM Verifier que les conteneurs sont en cours d'execution
set DB_RUNNING=false
docker inspect -f "{{.State.Running}}" limesurvey-db > "%TEMP%\ls_db_state.txt" 2>nul
if exist "%TEMP%\ls_db_state.txt" (
    set /p DB_RUNNING=<"%TEMP%\ls_db_state.txt"
    del "%TEMP%\ls_db_state.txt" >nul 2>nul
)
if /i not "%DB_RUNNING%"=="true" (
    echo ERREUR: Le conteneur limesurvey-db n'est pas en cours d'execution
    echo    Lancer d'abord: scripts\start-limesurvey.bat
    exit /b 1
)

REM Creer le dossier de backup
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

echo 1/2 - Export de la base de donnees MySQL...
docker exec limesurvey-db mysqldump --no-tablespaces -u "%MYSQL_USER%" -p"%MYSQL_PASSWORD%" "%MYSQL_DATABASE%" > "%BACKUP_DIR%\%BACKUP_NAME%_database.sql"
if errorlevel 1 (
    echo ERREUR: Echec export de la base de donnees
    exit /b 1
)
echo     -^> %BACKUP_DIR%\%BACKUP_NAME%_database.sql

echo.
echo 2/2 - Export des fichiers uploades...
set APP_RUNNING=false
docker inspect -f "{{.State.Running}}" limesurvey > "%TEMP%\ls_app_state.txt" 2>nul
if exist "%TEMP%\ls_app_state.txt" (
    set /p APP_RUNNING=<"%TEMP%\ls_app_state.txt"
    del "%TEMP%\ls_app_state.txt" >nul 2>nul
)
if /i "%APP_RUNNING%"=="true" (
    if not exist "%BACKUP_DIR%\%BACKUP_NAME%_uploads" mkdir "%BACKUP_DIR%\%BACKUP_NAME%_uploads"
    docker cp limesurvey:/var/www/html/upload "%BACKUP_DIR%\%BACKUP_NAME%_uploads" 2>nul
    if errorlevel 1 (
        echo     -^> ERREUR: Echec export fichiers uploades
    ) else (
        echo     -^> %BACKUP_DIR%\%BACKUP_NAME%_uploads\
    )
) else (
    echo     -^> ^(conteneur limesurvey non actif, fichiers non exportes^)
)

echo.
echo ==========================================
echo OK: Backup termine avec succes!
echo ==========================================
echo.
echo Fichiers: %BACKUP_DIR%\%BACKUP_NAME%_*
echo.
echo ==========================================
echo.
echo Pour restaurer ce backup:
echo    1. Arreter LimeSurvey: scripts\stop-limesurvey.bat
echo    2. Reinitialiser:      scripts\start-limesurvey.bat --fresh
echo    3. Restaurer:          scripts\restore-data.bat %BACKUP_DIR%\%BACKUP_NAME%_database.sql
echo.
echo Liste des backups disponibles:
dir /b "%BACKUP_DIR%\*.sql" 2>nul
echo.

exit /b 0
