@echo off
chcp 65001 >nul
setlocal

REM Build LimeSurvey.exe pour Windows
REM Usage: app\build-app.bat

echo ==========================================
echo Build LimeSurvey Lab - Windows
echo ==========================================
echo.

cd /d "%~dp0"

REM Verifier Python
where python >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ERREUR: Python n'est pas installe.
    echo    Installer Python depuis: https://www.python.org/downloads/
    echo    IMPORTANT: Cocher "Add Python to PATH" lors de l'installation
    exit /b 1
)

echo [1/4] Verification de Python...
python --version

echo.
echo [2/4] Installation des dependances...
pip install -r requirements.txt
if %ERRORLEVEL% neq 0 (
    echo ERREUR: Echec de l'installation des dependances
    exit /b 1
)

echo.
echo [3/4] Compilation de l'application...

REM Verifier si icon.ico existe, sinon utiliser une icone par defaut
if exist "icon.ico" (
    set ICON_OPTION=--icon=icon.ico
    set DATA_OPTION=--add-data=icon.ico;.
) else (
    echo    Note: icon.ico non trouve, icone par defaut utilisee
    set ICON_OPTION=
    set DATA_OPTION=
)

pyinstaller --onefile --noconsole --name=LimeSurvey %ICON_OPTION% %DATA_OPTION% limesurvey_app.py
if %ERRORLEVEL% neq 0 (
    echo ERREUR: Echec de la compilation
    exit /b 1
)

echo.
echo [4/4] Deplacement de l'executable...

REM Creer le dossier dist a la racine si necessaire
if not exist "..\dist" mkdir "..\dist"

REM Deplacer l'exe vers dist/
move /y "dist\LimeSurvey.exe" "..\dist\LimeSurvey.exe" >nul

REM Nettoyage
rmdir /s /q build 2>nul
rmdir /s /q dist 2>nul
del /q LimeSurvey.spec 2>nul

echo.
echo ==========================================
echo OK: Build termine avec succes!
echo ==========================================
echo.
echo L'application a ete creee: dist\LimeSurvey.exe
echo.
echo Pour lancer l'application:
echo    1. Ouvrir Docker Desktop
echo    2. Double-cliquer sur dist\LimeSurvey.exe
echo.

exit /b 0
