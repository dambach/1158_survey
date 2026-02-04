#!/bin/bash

# Diagnostic LimeSurvey
# Usage: ./scripts/test-system.sh

set -e

LIMESURVEY_URL="http://localhost:8081"

echo "Test LimeSurvey - $(date)"
echo "=========================================="

# Test 1: Connectivité de base
echo "📡 Test connectivité serveur..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 --max-time 10 $LIMESURVEY_URL 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ LimeSurvey accessible sur $LIMESURVEY_URL"
elif [ "$HTTP_CODE" = "000" ]; then
    echo "❌ Impossible de se connecter (timeout ou service non demarre)"
    echo "💡 Solution: Lancer ./scripts/start-limesurvey.sh"
    exit 1
else
    echo "❌ Problème de connectivité (Code HTTP: $HTTP_CODE)"
    echo "💡 Solution: Lancer ./scripts/start-limesurvey.sh"
    exit 1
fi

# Test 2: Administration
echo ""
echo "🔐 Test interface administration..."
HTTP_CODE_ADMIN=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 --max-time 10 $LIMESURVEY_URL/index.php/admin 2>/dev/null || echo "000")
if [ "$HTTP_CODE_ADMIN" = "302" ] || [ "$HTTP_CODE_ADMIN" = "200" ]; then
    echo "✅ Interface admin accessible"
else
    echo "❌ Interface admin inaccessible (Code: $HTTP_CODE_ADMIN)"
fi

# Test 3: Conteneurs Docker
echo ""
echo "🐳 État des conteneurs Docker..."
if docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "limesurvey|limesurvey-db"; then
    echo "✅ Conteneurs Docker actifs"
else
    echo "❌ Problème avec les conteneurs Docker"
    echo "💡 Solution: ./scripts/start-limesurvey.sh"
fi

# Test 4: Diagnostic réseau pour tablettes/téléphones
echo ""
echo "📱 Diagnostic réseau pour appareils mobiles..."

# Vérifier mode hotspot (bridge0) si une IP est réellement assignée
IP_HOTSPOT=$(ifconfig bridge0 2>/dev/null | awk '/inet /{print $2; exit}')
if [ -n "$IP_HOTSPOT" ]; then
    echo "✅ Mode HOTSPOT actif : $IP_HOTSPOT"
    echo "   URL tablettes hotspot : http://$IP_HOTSPOT:8081"
    echo "   SSID hotspot : LimeSurvey-Lab"
    IP_WIFI="$IP_HOTSPOT"
else
    # Sinon, trouver IP WiFi normale du Mac
    IP_WIFI=$(ipconfig getifaddr en0 2>/dev/null || true)
    if [ -n "$IP_WIFI" ]; then
        echo "✅ Mode WiFi normal : $IP_WIFI"
        echo "   URL tablettes WiFi : http://$IP_WIFI:8081"
    else
        echo "❌ Aucune IP réseau trouvée"
        echo "💡 Activez hotspot ou connectez-vous au WiFi"
    fi
fi

# Test pare-feu
echo ""
echo "Test pare-feu macOS..."
FIREWALL_STATUS=$(defaults read /Library/Preferences/com.apple.alf globalstate 2>/dev/null || echo "inconnu")
case $FIREWALL_STATUS in
    0) echo "OK: Pare-feu desactive (connexions autorisees)" ;;
    1|2) 
        echo ""
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        echo "!! ERREUR: PARE-FEU ACTIF - TABLETTES BLOQUEES !!"
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        echo ""
        echo "Les tablettes/telephones NE PEUVENT PAS acceder a LimeSurvey."
        echo ""
        echo "Solution immediate:"
        echo "   sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate off"
        echo ""
        echo "Ou via interface graphique:"
        echo "   Preferences Systeme -> Securite -> Pare-feu -> Desactiver"
        echo ""
        ;;
    *) echo "Etat du pare-feu inconnu" ;;
esac

# Test connectivité réseau local
echo ""
echo "🌐 Test accessibilité depuis tablettes..."
if [ -n "$IP_WIFI" ]; then
    if command -v nc >/dev/null 2>&1; then
        if echo "" | nc -w 1 $IP_WIFI 8081 2>/dev/null; then
            echo "✅ Port 8081 accessible depuis tablettes"
        else
            echo "❌ Port 8081 bloqué depuis l'extérieur"
            echo "💡 Solution : Désactiver pare-feu ou autoriser port 8081"
        fi
    fi
fi

echo ""
echo "🔧 Solutions si tablettes ne peuvent pas accéder :"
echo "   1. MODE HOTSPOT: Activer via Préférences → Partage → Partage Internet"
echo "      - SSID: LimeSurvey-Lab | Mot de passe: Lab2026!"
echo "      - IP attendue: 192.168.2.1"
echo "   2. MODE WIFI NORMAL: Connecter tablettes au même WiFi que le Mac"
echo "   3. PARE-FEU: Désactiver via Préférences → Sécurité → Pare-feu"
echo "   4. Ou commande: sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate off"

echo ""
echo "🎯 URLs de test :"
echo "   📱 Mac local    : $LIMESURVEY_URL"
echo "   🔐 Admin        : $LIMESURVEY_URL/index.php/admin"
if [ -n "$IP_WIFI" ]; then
    echo "   📲 Tablettes   : http://$IP_WIFI:8081"
fi

echo ""
echo "✅ Test système terminé!"
