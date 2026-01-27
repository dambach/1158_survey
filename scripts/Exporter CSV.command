#!/bin/bash
cd "$(dirname "$0")"
./export-csv.sh

osascript -e 'display notification "Export CSV termine dans ./exports/" with title "Export" sound name "Glass"' 2>/dev/null

# Ouvrir le dossier exports
open ../exports/

echo ""
read -p "Appuyez sur Entree pour fermer..."
