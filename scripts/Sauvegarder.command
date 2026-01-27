#!/bin/bash
cd "$(dirname "$0")"
./backup-data.sh

osascript -e 'display notification "Sauvegarde terminee dans ./backups/" with title "Sauvegarde" sound name "Glass"' 2>/dev/null

echo ""
read -p "Appuyez sur Entree pour fermer..."
