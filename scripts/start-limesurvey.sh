#!/bin/bash

# Demarrage LimeSurvey Lab
# Usage: ./scripts/start-limesurvey.sh [--fresh]

set -e

FRESH_INSTALL=false
if [ "$1" = "--fresh" ]; then
    FRESH_INSTALL=true
    echo "WARNING: MODE FRESH - Toutes les donnees seront supprimees!"
    echo "   Appuyez sur Ctrl+C dans 5 secondes pour annuler..."
    sleep 5
fi

LISTEN_PORT="${LISTEN_PORT:-8080}"
MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:-rootpass}"
MYSQL_DATABASE="${MYSQL_DATABASE:-limesurvey}"
MYSQL_USER="${MYSQL_USER:-limesurvey}"
MYSQL_PASSWORD="${MYSQL_PASSWORD:-limepass}"
ADMIN_USER="${ADMIN_USER:-admin}"
ADMIN_NAME="${ADMIN_NAME:-Admin}"
ADMIN_EMAIL="${ADMIN_EMAIL:-admin@lab.local}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-admin123}"

echo "Demarrage LimeSurvey Lab..."
echo ""

# Verifier si Docker est installe
if ! command -v docker &> /dev/null; then
    echo "ERREUR: Docker n'est pas installe."
    echo "   Installer Docker Desktop: https://www.docker.com/products/docker-desktop"
    exit 1
fi

# Verifier si Docker est en cours d'execution
if ! docker info &> /dev/null; then
    echo "ERREUR: Docker n'est pas demarre."
    echo "   Lancer Docker Desktop et reessayer."
    exit 1
fi

echo "OK: Docker est pret"
echo ""

# Verifier le pare-feu macOS
FIREWALL_STATE=$(/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null | grep -o "enabled\|disabled" || echo "unknown")
if [ "$FIREWALL_STATE" = "enabled" ]; then
    echo "ATTENTION: Pare-feu macOS actif!"
    echo "   Les tablettes/mobiles ne pourront pas acceder a LimeSurvey."
    echo "   Pour desactiver: sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate off"
    echo "   Ou: Preferences Systeme -> Securite -> Pare-feu -> Desactiver"
    echo ""
fi

# Nom des volumes pour persistance
MYSQL_VOLUME="limesurvey-mysql-data"
LIMESURVEY_VOLUME="limesurvey-upload-data"

# Mode FRESH : supprimer tout
if [ "$FRESH_INSTALL" = true ]; then
    echo "Suppression complete (mode --fresh)..."
    docker rm -f limesurvey limesurvey-db 2>/dev/null || true
    docker network rm limesurvey-net 2>/dev/null || true
    docker volume rm $MYSQL_VOLUME $LIMESURVEY_VOLUME 2>/dev/null || true
    echo "OK: Nettoyage complet effectue"
    echo ""
fi

# Verifier si les conteneurs existent deja et sont arretes
if docker ps -a --format '{{.Names}}' | grep -q "^limesurvey$"; then
    if docker ps --format '{{.Names}}' | grep -q "^limesurvey$"; then
        echo "OK: LimeSurvey est deja en cours d'execution"
        echo "DONNEES: Preservees dans les volumes Docker"
        echo ""
    else
        echo "Redemarrage des conteneurs existants..."
        echo "DONNEES: Preservees dans les volumes Docker"
        docker start limesurvey-db 2>/dev/null || true
        sleep 5
        docker start limesurvey 2>/dev/null || true
        echo "OK: Conteneurs redemarres"
        echo ""
    fi
else
    # Premiere installation ou apres --fresh
    echo "Nouvelle installation avec persistance des donnees..."
    echo ""
    
    # Creer les volumes si necessaires
    if ! docker volume ls --format '{{.Name}}' | grep -q "^${MYSQL_VOLUME}$"; then
        echo "Creation volume MySQL (donnees persistantes)..."
        docker volume create $MYSQL_VOLUME
    else
        echo "Volume MySQL existant detecte (donnees preservees)"
    fi
    
    if ! docker volume ls --format '{{.Name}}' | grep -q "^${LIMESURVEY_VOLUME}$"; then
        echo "Creation volume LimeSurvey (fichiers uploades)..."
        docker volume create $LIMESURVEY_VOLUME
    else
        echo "Volume LimeSurvey existant detecte (donnees preservees)"
    fi
    
    # Creer le reseau
    if ! docker network ls --format '{{.Name}}' | grep -q "^limesurvey-net$"; then
        echo "Creation du reseau Docker..."
        docker network create limesurvey-net
    fi
    
    # Nettoyer conteneurs orphelins
    docker rm -f limesurvey limesurvey-db 2>/dev/null || true
    
    echo "Lancement de la base de donnees MySQL..."
    docker run -d \
      --name limesurvey-db \
      --network limesurvey-net \
      --restart unless-stopped \
      -v $MYSQL_VOLUME:/var/lib/mysql \
      -e MYSQL_ROOT_PASSWORD="$MYSQL_ROOT_PASSWORD" \
      -e MYSQL_DATABASE="$MYSQL_DATABASE" \
      -e MYSQL_USER="$MYSQL_USER" \
      -e MYSQL_PASSWORD="$MYSQL_PASSWORD" \
      mysql:8.0
    
    echo "Attente du demarrage de MySQL (30 secondes)..."
    sleep 30
    
    echo "Lancement de LimeSurvey..."
    docker run -d \
      --name limesurvey \
      --network limesurvey-net \
      --restart unless-stopped \
      -p 8081:$LISTEN_PORT \
      -v $LIMESURVEY_VOLUME:/var/www/html/upload \
      -e LISTEN_PORT="$LISTEN_PORT" \
      -e DB_TYPE=mysql \
      -e DB_HOST=limesurvey-db \
      -e DB_PORT=3306 \
      -e DB_NAME="$MYSQL_DATABASE" \
      -e DB_USERNAME="$MYSQL_USER" \
      -e DB_PASSWORD="$MYSQL_PASSWORD" \
      -e ADMIN_USER="$ADMIN_USER" \
      -e ADMIN_NAME="$ADMIN_NAME" \
      -e ADMIN_EMAIL="$ADMIN_EMAIL" \
      -e ADMIN_PASSWORD="$ADMIN_PASSWORD" \
      martialblog/limesurvey:6-apache
    
    echo "Attente du demarrage de LimeSurvey (20 secondes)..."
    sleep 20
fi

echo ""
echo "=========================================="
echo "OK: LimeSurvey est operationnel!"
echo "=========================================="
echo ""
echo "Acces LimeSurvey:"
echo ""
echo "   Sur ce Mac:"
echo "   -> http://localhost:8081"
echo ""
echo "   Sur tablette (meme reseau WiFi):"

# Trouver l'IP du Mac
IP_WIFI=$(ipconfig getifaddr en0 2>/dev/null || echo "")
IP_ETH=$(ipconfig getifaddr en1 2>/dev/null || echo "")

if [ ! -z "$IP_WIFI" ]; then
    echo "   -> http://$IP_WIFI:8081"
fi

if [ ! -z "$IP_ETH" ]; then
    echo "   -> http://$IP_ETH:8081"
fi

if [ -z "$IP_WIFI" ] && [ -z "$IP_ETH" ]; then
    echo "   -> http://[TROUVER-IP-MAC]:8081"
    echo "     (Executer: ipconfig getifaddr en0)"
fi

echo ""
echo "=========================================="
echo ""
echo "Identifiants de connexion:"
echo "   Utilisateur: admin"
echo "   Mot de passe: admin123"
echo ""
echo "=========================================="
echo ""
echo "PERSISTANCE DES DONNEES:"
echo "   Les donnees sont stockees dans des volumes Docker."
echo "   Elles survivent aux redemarrages du Mac et des conteneurs."
echo ""
echo "   Volumes utilises:"
echo "   - $MYSQL_VOLUME (base de donnees)"
echo "   - $LIMESURVEY_VOLUME (fichiers uploades)"
echo ""
echo "=========================================="
echo ""
echo "Commandes utiles:"
echo "   Arreter:       ./scripts/stop-limesurvey.sh"
echo "   Redemarrer:    ./scripts/start-limesurvey.sh"
echo "   Backup:        ./scripts/backup-data.sh"
echo "   Reinitialiser: ./scripts/start-limesurvey.sh --fresh"
echo "   Logs:          docker logs limesurvey"
echo ""
echo "Bon test!"
