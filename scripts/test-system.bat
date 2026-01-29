@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

REM Diagnostic LimeSurvey - Windows
REM Usage: scripts\test-system.bat

set LIMESURVEY_URL=http://localhost:8081

echo Test LimeSurvey - %date% %time%
echo ==========================================

REM Test 1: Docker installe
echo.
echo [TEST] Docker installe...
where docker >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo [OK] Docker est installe
) else (
    echo [ERREUR] Docker n'est pas installe
    echo    Solution: Installer Docker Desktop depuis https://www.docker.com/products/docker-desktop
    exit /b 1
)

REM Test 2: Docker en cours d'execution
echo.
echo [TEST] Docker en cours d'execution...
docker info >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo [OK] Docker est en cours d'execution
) else (
    echo [ERREUR] Docker n'est pas demarre
    echo    Solution: Lancer Docker Desktop
    exit /b 1
)

REM Test 3: Conteneurs Docker
echo.
echo [TEST] Etat des conteneurs Docker...
docker ps --format "table {{.Names}}\t{{.Status}}" | findstr /i "limesurvey"
if %ERRORLEVEL% equ 0 (
    echo [OK] Conteneurs Docker actifs
) else (
    echo [ERREUR] Probleme avec les conteneurs Docker
    echo    Solution: scripts\start-limesurvey.bat
)

REM Test 4: Connectivite de base
echo.
echo [TEST] Connectivite serveur...
curl -s -o nul -w "%%{http_code}" --connect-timeout 5 --max-time 10 %LIMESURVEY_URL% 2>nul | findstr "200" >nul
if %ERRORLEVEL% equ 0 (
    echo [OK] LimeSurvey accessible sur %LIMESURVEY_URL%
) else (
    echo [ERREUR] Impossible de se connecter
    echo    Solution: Lancer scripts\start-limesurvey.bat
)

REM Test 5: Interface administration
echo.
echo [TEST] Interface administration...
curl -s -o nul -w "%%{http_code}" --connect-timeout 5 --max-time 10 %LIMESURVEY_URL%/index.php/admin 2>nul | findstr "200 302" >nul
if %ERRORLEVEL% equ 0 (
    echo [OK] Interface admin accessible
) else (
    echo [ATTENTION] Interface admin peut-etre inaccessible
)

REM Test 6: Diagnostic reseau pour tablettes/telephones
echo.
echo [TEST] Diagnostic reseau pour appareils mobiles...
echo.
echo Adresses IP de ce PC:
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4"') do (
    set IP=%%a
    set IP=!IP: =!
    echo   URL tablettes: http://!IP!:8081
)

REM Test 7: Pare-feu Windows
echo.
echo [TEST] Pare-feu Windows...
netsh advfirewall show currentprofile state | findstr /i "ON" >nul
if %ERRORLEVEL% equ 0 (
    echo [ATTENTION] Pare-feu Windows actif
    echo    Les tablettes peuvent etre bloquees.
    echo    Solution: Autoriser Docker Desktop dans le pare-feu Windows
    echo    Ou: Desactiver temporairement le pare-feu
) else (
    echo [OK] Pare-feu desactive ou regle correctement
)

echo.
echo ==========================================
echo Diagnostic termine.
echo ==========================================

exit /b 0
