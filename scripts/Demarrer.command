#!/bin/bash
cd "$(dirname "$0")"
./start-limesurvey.sh

# Notification macOS
osascript -e 'display notification "Ouvrir http://localhost:8081" with title "LimeSurvey pret" sound name "Glass"' 2>/dev/null

# Ouvrir navigateur
open "http://localhost:8081"

echo ""
read -p "Appuyez sur Entree pour fermer..."
