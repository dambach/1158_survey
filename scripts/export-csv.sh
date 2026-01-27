#!/bin/bash

# Export CSV des reponses
# Usage: ./scripts/export-csv.sh

set -e

EXPORT_DIR="./exports"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

mkdir -p "$EXPORT_DIR"

if ! docker ps --format '{{.Names}}' | grep -q "^limesurvey-db$"; then
    echo "ERREUR: LimeSurvey non demarre"
    exit 1
fi

echo "Export CSV des reponses..."

# Export uniquement des tables de reponses (lime_survey_XXXXX - ID numerique seulement)
docker exec limesurvey-db mysql -u limesurvey -plimepass limesurvey -N -e "SHOW TABLES LIKE 'lime_survey_%';" 2>/dev/null | while read table; do
    # Extraire l'ID et verifier que c'est numerique (pas lime_surveys, lime_surveymenu, etc.)
    survey_id=$(echo "$table" | sed 's/lime_survey_//')
    if [[ "$survey_id" =~ ^[0-9]+$ ]]; then
        output_file="$EXPORT_DIR/reponses_${survey_id}_${TIMESTAMP}.csv"
        
        docker exec limesurvey-db mysql -u limesurvey -plimepass limesurvey -e "SELECT * FROM $table;" 2>/dev/null | tr '\t' ',' > "$output_file"
        
        if [ -s "$output_file" ]; then
            lines=$(wc -l < "$output_file" | tr -d ' ')
            echo "  -> $output_file ($((lines-1)) reponses)"
        else
            rm -f "$output_file"
        fi
    fi
done

echo ""
echo "OK: Export termine dans $EXPORT_DIR/"
