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
    timeout /t 5 >nul
)

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
    echo Suppression complete (mode --fresh^)...
    docker rm -f limesurvey limesurvey-db 2>nul
    docker network rm limesurvey-net 2>nul
    docker volume rm %MYSQL_VOLUME% %LIMESURVEY_VOLUME% 2>nul
    echo OK: Nettoyage complet effectue
    echo.
)

REM Verifier si les conteneurs existent deja et sont arretes
docker ps -a --format "{{.Names}}" | findstr /x "limesurvey" >nul 2>&1
if %ERRORLEVEL% equ 0 (
    docker ps --format "{{.Names}}" | findstr /x "limesurvey" >nul 2>&1
    if !ERRORLEVEL! equ 0 (
        echo OK: LimeSurvey est deja en cours d'execution
        echo DONNEES: Preservees dans les volumes Docker
        echo.
    ) else (
        echo Redemarrage des conteneurs existants...
        echo DONNEES: Preservees dans les volumes Docker
        docker start limesurvey-db 2>nul
        timeout /t 5 >nul
        docker start limesurvey 2>nul
        echo OK: Conteneurs redemarres
        echo.
    )
) else (
    REM Premiere installation ou apres --fresh
    echo Nouvelle installation avec persistance des donnees...
    echo.
    
    REM Creer les volumes si necessaires
    docker volume ls --format "{{.Name}}" | findstr /x "%MYSQL_VOLUME%" >nul 2>&1
    if !ERRORLEVEL! neq 0 (
        echo Creation volume MySQL (donnees persistantes^)...
        docker volume create %MYSQL_VOLUME%
    ) else (
        echo Volume MySQL existant detecte (donnees preservees^)
    )
    
    docker volume ls --format "{{.Name}}" | findstr /x "%LIMESURVEY_VOLUME%" >nul 2>&1
    if !ERRORLEVEL! neq 0 (
        echo Creation volume LimeSurvey (fichiers uploades^)...
        docker volume create %LIMESURVEY_VOLUME%
    ) else (
        echo Volume LimeSurvey existant detecte (donnees preservees^)
    )
    
    REM Creer le reseau
    docker network ls --format "{{.Name}}" | findstr /x "limesurvey-net" >nul 2>&1
    if !ERRORLEVEL! neq 0 (
        echo Creation du reseau Docker...
        docker network create limesurvey-net
    )
    
    REM Lancer MySQL
    echo Demarrage de MySQL...
    docker run -d ^
        --name limesurvey-db ^
        --network limesurvey-net ^
        -v %MYSQL_VOLUME%:/var/lib/mysql ^
        -e MYSQL_ROOT_PASSWORD=rootpass ^
        -e MYSQL_DATABASE=limesurvey ^
        -e MYSQL_USER=limesurvey ^
        -e MYSQL_PASSWORD=limepass ^
        mysql:8.0
    
    echo Attente initialisation MySQL (30 secondes^)...
    timeout /t 30 >nul
    
    REM Lancer LimeSurvey
    echo Demarrage de LimeSurvey...
    docker run -d ^
        --name limesurvey ^
        --network limesurvey-net ^
        -p 8081:80 ^
        -v %LIMESURVEY_VOLUME%:/var/www/html/upload ^
        -e DB_TYPE=mysql ^
        -e DB_HOST=limesurvey-db ^
        -e DB_PORT=3306 ^
        -e DB_NAME=limesurvey ^
        -e DB_USERNAME=limesurvey ^
        -e DB_PASSWORD=limepass ^
        -e ADMIN_USER=admin ^
        -e ADMIN_PASSWORD=admin123 ^
        -e ADMIN_NAME=Administrator ^
        -e ADMIN_EMAIL=admin@example.com ^
        martialblog/limesurvey:6-apache
    
    echo OK: Installation terminee
    echo.
)

REM Attendre que LimeSurvey soit pret
echo Attente demarrage LimeSurvey...
set /a count=0
:waitloop
timeout /t 2 >nul
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
echo   - PC (local):     http://localhost:8081
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4"') do (
    set IP=%%a
    set IP=!IP: =!
    echo   - Tablettes:      http://!IP!:8081
)
echo.
echo Login admin: admin / admin123
echo.

exit /b 0
