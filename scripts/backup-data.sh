#!/bin/bash

# Sauvegarde LimeSurvey
# Usage: ./scripts/backup-data.sh

set -e

BACKUP_DIR="./backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="limesurvey_backup_$TIMESTAMP"

echo "=========================================="
echo "Backup LimeSurvey Lab - $TIMESTAMP"
echo "=========================================="
echo ""

# Verifier que les conteneurs sont en cours d'execution
if ! docker ps --format '{{.Names}}' | grep -q "^limesurvey-db$"; then
    echo "ERREUR: Le conteneur limesurvey-db n'est pas en cours d'execution"
    echo "   Lancer d'abord: ./scripts/start-limesurvey.sh"
    exit 1
fi

# Creer le dossier de backup
mkdir -p "$BACKUP_DIR"

echo "1/3 - Export de la base de donnees MySQL..."
docker exec limesurvey-db mysqldump -u limesurvey -plimepass limesurvey > "$BACKUP_DIR/${BACKUP_NAME}_database.sql"
echo "    -> $BACKUP_DIR/${BACKUP_NAME}_database.sql"

echo ""
echo "2/3 - Export des fichiers uploades..."
if docker ps --format '{{.Names}}' | grep -q "^limesurvey$"; then
    docker cp limesurvey:/var/www/html/upload "$BACKUP_DIR/${BACKUP_NAME}_uploads" 2>/dev/null || mkdir -p "$BACKUP_DIR/${BACKUP_NAME}_uploads"
    echo "    -> $BACKUP_DIR/${BACKUP_NAME}_uploads/"
else
    echo "    -> (conteneur limesurvey non actif, fichiers non exportes)"
fi

echo ""
echo "3/3 - Creation de l'archive compressee..."
cd "$BACKUP_DIR"
tar -czf "${BACKUP_NAME}.tar.gz" "${BACKUP_NAME}_database.sql" "${BACKUP_NAME}_uploads" 2>/dev/null || tar -czf "${BACKUP_NAME}.tar.gz" "${BACKUP_NAME}_database.sql"
rm -rf "${BACKUP_NAME}_database.sql" "${BACKUP_NAME}_uploads"
cd ..

BACKUP_SIZE=$(du -h "$BACKUP_DIR/${BACKUP_NAME}.tar.gz" | cut -f1)

echo ""
echo "=========================================="
echo "OK: Backup termine avec succes!"
echo "=========================================="
echo ""
echo "Fichier: $BACKUP_DIR/${BACKUP_NAME}.tar.gz"
echo "Taille:  $BACKUP_SIZE"
echo ""
echo "=========================================="
echo ""
echo "Pour restaurer ce backup:"
echo "   1. Arreter LimeSurvey: ./scripts/stop-limesurvey.sh"
echo "   2. Reinitialiser:      ./scripts/start-limesurvey.sh --fresh"
echo "   3. Restaurer:          ./scripts/restore-data.sh $BACKUP_DIR/${BACKUP_NAME}.tar.gz"
echo ""
echo "Liste des backups disponibles:"
ls -lh "$BACKUP_DIR"/*.tar.gz 2>/dev/null || echo "   (aucun backup)"
echo ""
