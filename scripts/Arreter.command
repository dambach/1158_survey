#!/bin/bash
cd "$(dirname "$0")"
./stop-limesurvey.sh

osascript -e 'display notification "LimeSurvey arrete" with title "Arret" sound name "Glass"' 2>/dev/null

echo ""
read -p "Appuyez sur Entree pour fermer..."
