@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

REM Restauration LimeSurvey - Windows
REM Usage: scripts\restore-data.bat chemin\vers\backup_database.sql

if "%1"=="" (
    echo Usage: scripts\restore-data.bat chemin\vers\backup_database.sql
    echo.
    echo Backups disponibles:
    dir /b ".\backups\*.sql" 2>nul
    exit /b 1
)

set BACKUP_FILE=%1

if not exist "%BACKUP_FILE%" (
    echo ERREUR: Fichier non trouve: %BACKUP_FILE%
    exit /b 1
)

echo ==========================================
echo Restauration LimeSurvey Lab
echo ==========================================
echo.
echo Fichier: %BACKUP_FILE%
echo.
echo ATTENTION: Cette operation va remplacer toutes les donnees actuelles!
echo Appuyez sur Ctrl+C pour annuler, ou...
pause

REM Verifier que les conteneurs sont en cours d'execution
docker ps --format "{{.Names}}" | findstr /x "limesurvey-db" >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ERREUR: Le conteneur limesurvey-db n'est pas en cours d'execution
    echo    Lancer d'abord: scripts\start-limesurvey.bat
    exit /b 1
)

echo.
echo Restauration de la base de donnees...
type "%BACKUP_FILE%" | docker exec -i limesurvey-db mysql -u limesurvey -plimepass limesurvey

if %ERRORLEVEL% equ 0 (
    echo.
    echo ==========================================
    echo OK: Restauration terminee avec succes!
    echo ==========================================
    echo.
    echo Redemarrez LimeSurvey pour appliquer les changements:
    echo    scripts\stop-limesurvey.bat
    echo    scripts\start-limesurvey.bat
) else (
    echo.
    echo ERREUR: Echec de la restauration
    exit /b 1
)

exit /b 0
