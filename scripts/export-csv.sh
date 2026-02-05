#!/bin/bash

# Export CSV des reponses
# Usage: ./scripts/export-csv.sh

set -e

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
PYTHON_BIN="${PYTHON_BIN:-python3}"
if ! command -v "$PYTHON_BIN" >/dev/null 2>&1; then
    PYTHON_BIN="python"
fi

EXPORT_DIR="./exports"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

MYSQL_DATABASE="${MYSQL_DATABASE:-limesurvey}"
MYSQL_USER="${MYSQL_USER:-limesurvey}"
MYSQL_PASSWORD="${MYSQL_PASSWORD:-limepass}"

mkdir -p "$EXPORT_DIR"

if ! docker ps --format '{{.Names}}' | grep -q "^limesurvey-db$"; then
    echo "ERREUR: LimeSurvey non demarre"
    exit 1
fi

echo "Export CSV des reponses..."

# Export uniquement des tables de reponses (lime_survey_XXXXX - ID numerique seulement)
docker exec limesurvey-db mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" -N -e "SHOW TABLES LIKE 'lime_survey_%';" 2>/dev/null | while read table; do
    # Extraire l'ID et verifier que c'est numerique (pas lime_surveys, lime_surveymenu, etc.)
    survey_id=$(echo "$table" | sed 's/lime_survey_//')
    if [[ "$survey_id" =~ ^[0-9]+$ ]]; then
        output_file="$EXPORT_DIR/reponses_${survey_id}_${TIMESTAMP}.csv"
        tmp_file="$EXPORT_DIR/.tmp_${survey_id}_${TIMESTAMP}.tsv"

        docker exec limesurvey-db mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" -B -e "SELECT * FROM $table;" 2>/dev/null > "$tmp_file"
        "$PYTHON_BIN" "$SCRIPT_DIR/convert-mysql-tsv-to-csv.py" "$tmp_file" "$output_file"
        rm -f "$tmp_file"
        
        if [ -s "$output_file" ]; then
            responses=$(docker exec limesurvey-db mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" -N -B -e "SELECT COUNT(*) FROM $table;" 2>/dev/null | tr -d '\r' | head -n 1)
            if [[ -z "$responses" ]]; then
                responses=0
            fi
            echo "  -> $output_file (${responses} reponses)"
        else
            rm -f "$output_file"
        fi
    fi
done

echo ""
echo "OK: Export termine dans $EXPORT_DIR/"
