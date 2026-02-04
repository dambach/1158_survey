@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

REM Export CSV des reponses - Windows
REM Usage: scripts\export-csv.bat

set EXPORT_DIR=.\exports
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set datetime=%%I
set TIMESTAMP=%datetime:~0,8%_%datetime:~8,6%

if "%MYSQL_DATABASE%"=="" set MYSQL_DATABASE=limesurvey
if "%MYSQL_USER%"=="" set MYSQL_USER=limesurvey
if "%MYSQL_PASSWORD%"=="" set MYSQL_PASSWORD=limepass

if not exist "%EXPORT_DIR%" mkdir "%EXPORT_DIR%"

docker ps --format "{{.Names}}" | findstr /x "limesurvey-db" >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ERREUR: LimeSurvey non demarre
    exit /b 1
)

echo Export CSV des reponses...

REM Recuperer la liste des tables de reponses
for /f "tokens=*" %%t in ('docker exec limesurvey-db mysql -u "%MYSQL_USER%" -p"%MYSQL_PASSWORD%" "%MYSQL_DATABASE%" -N -e "SHOW TABLES LIKE 'lime_survey_%%';" 2^>nul') do (
    set TABLE=%%t
    REM Extraire l'ID du survey (partie apres lime_survey_)
    set SURVEY_ID=!TABLE:lime_survey_=!
    
    REM Verifier que c'est un ID numerique (pas lime_surveys, lime_surveymenu, etc.)
    echo !SURVEY_ID!| findstr /r "^[0-9]*$" >nul
    if !ERRORLEVEL! equ 0 (
        set OUTPUT_FILE=%EXPORT_DIR%\reponses_!SURVEY_ID!_%TIMESTAMP%.csv
        
        docker exec limesurvey-db mysql -u "%MYSQL_USER%" -p"%MYSQL_PASSWORD%" "%MYSQL_DATABASE%" -B -e "SELECT * FROM !TABLE!;" 2>nul > "!OUTPUT_FILE!.tmp"
        
        REM Convertir TSV MySQL -> CSV avec echappement correct
        python "%~dp0convert-mysql-tsv-to-csv.py" "!OUTPUT_FILE!.tmp" "!OUTPUT_FILE!"
        del "!OUTPUT_FILE!.tmp" 2>nul
        
        REM Verifier si le fichier contient des donnees
        for %%F in ("!OUTPUT_FILE!") do set SIZE=%%~zF
        if !SIZE! gtr 0 (
            for /f %%L in ('type "!OUTPUT_FILE!" ^| find /c /v ""') do set LINES=%%L
            set /a RESPONSES=!LINES!-1
            echo   -^> !OUTPUT_FILE! ^(!RESPONSES! reponses^)
        ) else (
            del "!OUTPUT_FILE!" 2>nul
        )
    )
)

echo.
echo OK: Export termine dans %EXPORT_DIR%\

exit /b 0
