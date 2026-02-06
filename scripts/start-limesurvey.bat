@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

REM Demarrage LimeSurvey Lab - Windows
REM Usage: scripts\start-limesurvey.bat [--fresh]

set FRESH_INSTALL=false
if "%1"=="--fresh" (
    set FRESH_INSTALL=true
    echo WARNING: MODE FRESH - Toutes les donnees seront supprimees!
    echo    Appuyez sur Ctrl+C dans 5 secondes pour annuler...
    powershell -NoProfile -Command "Start-Sleep -Seconds 5" >nul 2>nul
)

if "%LISTEN_PORT%"=="" set LISTEN_PORT=8080
if "%MYSQL_ROOT_PASSWORD%"=="" set MYSQL_ROOT_PASSWORD=rootpass
if "%MYSQL_DATABASE%"=="" set MYSQL_DATABASE=limesurvey
if "%MYSQL_USER%"=="" set MYSQL_USER=limesurvey
if "%MYSQL_PASSWORD%"=="" set MYSQL_PASSWORD=limepass
if "%ADMIN_USER%"=="" set ADMIN_USER=admin
if "%ADMIN_PASSWORD%"=="" set ADMIN_PASSWORD=admin123
if "%ADMIN_NAME%"=="" set ADMIN_NAME=Administrator
if "%ADMIN_EMAIL%"=="" set ADMIN_EMAIL=admin@example.com

echo Demarrage LimeSurvey Lab...
echo.

REM Verifier si Docker est installe
where docker >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ERREUR: Docker n'est pas installe.
    echo    Installer Docker Desktop: https://www.docker.com/products/docker-desktop
    exit /b 1
)

REM Verifier si Docker est en cours d'execution
docker info >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ERREUR: Docker n'est pas demarre.
    echo    Lancer Docker Desktop et reessayer.
    exit /b 1
)

echo OK: Docker est pret
echo.

REM Nom des volumes pour persistance
set MYSQL_VOLUME=limesurvey-mysql-data
set LIMESURVEY_VOLUME=limesurvey-upload-data

REM Mode FRESH : supprimer tout
if "%FRESH_INSTALL%"=="true" (
    echo Suppression complete ^(mode --fresh^)...
    docker rm -f limesurvey limesurvey-db 2>nul
    docker network rm limesurvey-net 2>nul
    docker volume rm %MYSQL_VOLUME% %LIMESURVEY_VOLUME% 2>nul
    echo OK: Nettoyage complet effectue
    echo.
)

REM Detecter l'existence et l'etat des conteneurs
REM Note: Docker renvoie souvent des fins de ligne LF sur Windows, donc eviter findstr /x.
set "DB_EXISTS=false"
docker inspect limesurvey-db >nul 2>&1 && set "DB_EXISTS=true"
set "APP_EXISTS=false"
docker inspect limesurvey >nul 2>&1 && set "APP_EXISTS=true"

set "DB_RUNNING=false"
if /i "%DB_EXISTS%"=="true" (
    docker inspect -f "{{.State.Running}}" limesurvey-db > "%TEMP%\ls_db_state.txt" 2>nul
    if exist "%TEMP%\ls_db_state.txt" (
        set /p DB_RUNNING=<"%TEMP%\ls_db_state.txt"
        del "%TEMP%\ls_db_state.txt" >nul 2>nul
    )
)

set "APP_RUNNING=false"
if /i "%APP_EXISTS%"=="true" (
    docker inspect -f "{{.State.Running}}" limesurvey > "%TEMP%\ls_app_state.txt" 2>nul
    if exist "%TEMP%\ls_app_state.txt" (
        set /p APP_RUNNING=<"%TEMP%\ls_app_state.txt"
        del "%TEMP%\ls_app_state.txt" >nul 2>nul
    )
)

set "ALL_RUNNING=false"
if /i "%DB_EXISTS%"=="true" if /i "%APP_EXISTS%"=="true" if /i "%DB_RUNNING%"=="true" if /i "%APP_RUNNING%"=="true" set "ALL_RUNNING=true"

if /i "%ALL_RUNNING%"=="true" (
    echo OK: LimeSurvey est deja en cours d'execution
    echo DONNEES: Preservees dans les volumes Docker
    echo.
) else (
    if /i "%DB_EXISTS%"=="false" (
        echo Nouvelle installation avec persistance des donnees...
    ) else (
        echo Redemarrage / finalisation de l'installation...
        echo DONNEES: Preservees dans les volumes Docker
    )
    echo.

    REM Creer les volumes (idempotent)
    docker volume create %MYSQL_VOLUME% >nul 2>&1
    docker volume create %LIMESURVEY_VOLUME% >nul 2>&1

    REM Creer le reseau si necessaire
    docker network inspect limesurvey-net >nul 2>&1
    if errorlevel 1 (
        echo Creation du reseau Docker...
        docker network create limesurvey-net >nul
        if errorlevel 1 (
            echo ERREUR: Impossible de creer le reseau Docker ^(limesurvey-net^)
            exit /b 1
        )
    )

    REM Demarrer / creer MySQL
    if /i "%DB_EXISTS%"=="true" (
        if /i "%DB_RUNNING%" NEQ "true" (
            echo Redemarrage de MySQL...
            docker start limesurvey-db 2>nul
            if errorlevel 1 (
                echo ERREUR: Impossible de demarrer limesurvey-db
                exit /b 1
            )
        )
        echo Attente MySQL ^(5 secondes^)...
        powershell -NoProfile -Command "Start-Sleep -Seconds 5" >nul 2>nul
    ) else (
        echo Demarrage de MySQL...
        docker run -d ^
            --name limesurvey-db ^
            --network limesurvey-net ^
            --restart unless-stopped ^
            -v %MYSQL_VOLUME%:/var/lib/mysql ^
            -e "MYSQL_ROOT_PASSWORD=%MYSQL_ROOT_PASSWORD%" ^
            -e "MYSQL_DATABASE=%MYSQL_DATABASE%" ^
            -e "MYSQL_USER=%MYSQL_USER%" ^
            -e "MYSQL_PASSWORD=%MYSQL_PASSWORD%" ^
            mysql:8.0
        if errorlevel 1 (
            echo ERREUR: Echec demarrage MySQL
            exit /b 1 
        )

        echo Attente initialisation MySQL ^(30 secondes^)...
        powershell -NoProfile -Command "Start-Sleep -Seconds 30" >nul 2>nul
    )

    REM Demarrer / creer LimeSurvey
    if /i "%APP_EXISTS%"=="true" (
        if /i "%APP_RUNNING%" NEQ "true" (
            echo Redemarrage de LimeSurvey...
            docker start limesurvey 2>nul
            if errorlevel 1 (
                echo ERREUR: Impossible de demarrer limesurvey
                exit /b 1
            )
        )
    ) else (
        echo Demarrage de LimeSurvey...
        docker run -d ^
            --name limesurvey ^
            --network limesurvey-net ^
            --restart unless-stopped ^
            -p 8081:%LISTEN_PORT% ^
            -v %LIMESURVEY_VOLUME%:/var/www/html/upload ^
            -e "LISTEN_PORT=%LISTEN_PORT%" ^
            -e DB_TYPE=mysql ^
            -e DB_HOST=limesurvey-db ^
            -e DB_PORT=3306 ^
            -e "DB_NAME=%MYSQL_DATABASE%" ^
            -e "DB_USERNAME=%MYSQL_USER%" ^
            -e "DB_PASSWORD=%MYSQL_PASSWORD%" ^
            -e "ADMIN_USER=%ADMIN_USER%" ^
            -e "ADMIN_PASSWORD=%ADMIN_PASSWORD%" ^
            -e "ADMIN_NAME=%ADMIN_NAME%" ^
            -e "ADMIN_EMAIL=%ADMIN_EMAIL%" ^
            martialblog/limesurvey:6-apache
        if errorlevel 1 (
            echo ERREUR: Echec demarrage LimeSurvey
            exit /b 1
        )

        echo OK: Installation terminee
        echo.
    )
)

REM Attendre que LimeSurvey soit pret
echo Attente demarrage LimeSurvey...
set /a count=0
:waitloop
powershell -NoProfile -Command "Start-Sleep -Seconds 2" >nul 2>nul
curl -s -o nul -w "%%{http_code}" http://localhost:8081 2>nul | findstr "200 302" >nul
if %ERRORLEVEL% equ 0 goto :ready
set /a count+=1
if %count% lss 30 goto :waitloop
echo Timeout - verifiez les logs: docker logs limesurvey
exit /b 1

:ready
echo.
echo ==========================================
echo OK: LimeSurvey est pret!
echo ==========================================
echo.

REM Afficher l'IP locale pour les tablettes
echo Adresses reseau:
echo   - PC ^(local^):     http://localhost:8081
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4"') do (
    set IP=%%a
    set IP=!IP: =!
    echo   - Tablettes:      http://!IP!:8081
)
echo.
echo Login admin: admin / admin123
echo.

exit /b 0
