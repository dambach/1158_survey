@echo off
chcp 65001 >nul

REM Arret LimeSurvey - Windows
REM Usage: scripts\stop-limesurvey.bat

echo Arret...

docker stop limesurvey limesurvey-db 2>nul

echo OK

exit /b 0
