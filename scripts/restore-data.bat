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

if "%MYSQL_DATABASE%"=="" set MYSQL_DATABASE=limesurvey
if "%MYSQL_USER%"=="" set MYSQL_USER=limesurvey
if "%MYSQL_PASSWORD%"=="" set MYSQL_PASSWORD=limepass

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

echo.
echo Restauration de la base de donnees...
type "%BACKUP_FILE%" | docker exec -i limesurvey-db mysql -u "%MYSQL_USER%" -p"%MYSQL_PASSWORD%" "%MYSQL_DATABASE%"

if %ERRORLEVEL% equ 0 (
    echo.
    echo Restauration des fichiers uploades...
    set BASE_NAME=%BACKUP_FILE%
    if /i "!BASE_NAME:~-13!"=="_database.sql" set BASE_NAME=!BASE_NAME:~0,-13!
    set UPLOAD_DIR=!BASE_NAME!_uploads
    set UPLOAD_SRC=
    if exist "!UPLOAD_DIR!\upload" (
        set UPLOAD_SRC=!UPLOAD_DIR!\upload
    ) else if exist "!UPLOAD_DIR!" (
        set UPLOAD_SRC=!UPLOAD_DIR!
    )
    if defined UPLOAD_SRC (
        set APP_RUNNING=false
        docker inspect -f "{{.State.Running}}" limesurvey > "%TEMP%\ls_app_state.txt" 2>nul
        if exist "%TEMP%\ls_app_state.txt" (
            set /p APP_RUNNING=<"%TEMP%\ls_app_state.txt"
            del "%TEMP%\ls_app_state.txt" >nul 2>nul
        )
        if /i "!APP_RUNNING!"=="true" (
            docker cp "!UPLOAD_SRC!\." limesurvey:/var/www/html/upload/ 2>nul
            if !ERRORLEVEL! equ 0 (
                echo    -^> Fichiers uploades restaures
            ) else (
                echo    -^> ERREUR: Echec restauration fichiers uploades
            )
        ) else (
            echo    -^> ^(conteneur limesurvey non actif, fichiers non restaures^)
        )
    ) else (
        echo    -^> ^(pas de fichiers uploades dans ce backup^)
    )
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
