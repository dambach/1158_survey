#!/bin/bash

# Restauration LimeSurvey
# Usage: ./scripts/restore-data.sh <fichier.tar.gz>

set -e

if [ -z "$1" ]; then
    echo "Usage: ./scripts/restore-data.sh <fichier_backup.tar.gz>"
    echo ""
    echo "Backups disponibles:"
    ls -lh ./backups/*.tar.gz 2>/dev/null || echo "   (aucun backup trouve)"
    exit 1
fi

BACKUP_FILE="$1"

if [ ! -f "$BACKUP_FILE" ]; then
    echo "ERREUR: Fichier backup non trouve: $BACKUP_FILE"
    exit 1
fi

echo "=========================================="
echo "Restauration LimeSurvey Lab"
echo "=========================================="
echo ""
echo "Fichier: $BACKUP_FILE"
echo ""
echo "ATTENTION: Cette operation va remplacer toutes les donnees actuelles!"
echo "   Appuyez sur Ctrl+C dans 5 secondes pour annuler..."
sleep 5

# Verifier que les conteneurs sont en cours d'execution
if ! docker ps --format '{{.Names}}' | grep -q "^limesurvey-db$"; then
    echo "ERREUR: Le conteneur limesurvey-db n'est pas en cours d'execution"
    echo "   Lancer d'abord: ./scripts/start-limesurvey.sh"
    exit 1
fi

# Creer un dossier temporaire pour l'extraction
TEMP_DIR=$(mktemp -d)
echo ""
echo "1/3 - Extraction de l'archive..."
tar -xzf "$BACKUP_FILE" -C "$TEMP_DIR"

# Trouver le fichier SQL
SQL_FILE=$(find "$TEMP_DIR" -name "*.sql" -type f | head -1)

if [ -z "$SQL_FILE" ]; then
    echo "ERREUR: Fichier SQL non trouve dans l'archive"
    rm -rf "$TEMP_DIR"
    exit 1
fi

echo "    -> Fichier SQL trouve: $(basename $SQL_FILE)"

echo ""
echo "2/3 - Restauration de la base de donnees..."
docker exec -i limesurvey-db mysql -u limesurvey -plimepass limesurvey < "$SQL_FILE"
echo "    -> Base de donnees restauree"

echo ""
echo "3/3 - Restauration des fichiers uploades..."
UPLOAD_DIR=$(find "$TEMP_DIR" -type d -name "*_uploads" | head -1)
if [ ! -z "$UPLOAD_DIR" ] && [ -d "$UPLOAD_DIR" ]; then
    if docker ps --format '{{.Names}}' | grep -q "^limesurvey$"; then
        docker cp "$UPLOAD_DIR/." limesurvey:/var/www/html/upload/
        echo "    -> Fichiers uploades restaures"
    else
        echo "    -> (conteneur limesurvey non actif, fichiers non restaures)"
    fi
else
    echo "    -> (pas de fichiers uploades dans ce backup)"
fi

# Nettoyage
rm -rf "$TEMP_DIR"

echo ""
echo "=========================================="
echo "OK: Restauration terminee avec succes!"
echo "=========================================="
echo ""
echo "Redemarrez LimeSurvey pour appliquer les changements:"
echo "   docker restart limesurvey"
echo ""
