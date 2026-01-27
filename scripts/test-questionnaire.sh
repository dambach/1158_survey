#!/bin/bash

# Test questionnaire LimeSurvey
# Usage: ./scripts/test-questionnaire.sh <ID>

set -e

LIMESURVEY_URL="http://localhost:8081"

if [ -z "$1" ]; then
    echo "Usage: ./scripts/test-questionnaire.sh <ID>"
    echo "Exemple: ./scripts/test-questionnaire.sh 142375"
    exit 1
fi

QUESTIONNAIRE_ID="$1"

echo "Test Questionnaire LimeSurvey - $(date)"
echo "=========================================="
echo "ID questionnaire: $QUESTIONNAIRE_ID"
echo ""

# Test connectivite generale
echo "Test connectivite serveur..."
if curl -s --connect-timeout 5 "$LIMESURVEY_URL" | grep -q "LimeSurvey"; then
    echo "OK: LimeSurvey accessible sur $LIMESURVEY_URL"
else
    echo "ERREUR: LimeSurvey non accessible"
    exit 1
fi

# Test questionnaire specifique
echo ""
echo "Test questionnaire (ID: $QUESTIONNAIRE_ID)..."
SURVEY_URL="$LIMESURVEY_URL/index.php/$QUESTIONNAIRE_ID?lang=fr"

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "$SURVEY_URL" 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
    echo "OK: Questionnaire accessible"
    echo "   URL: $SURVEY_URL"
elif [ "$HTTP_CODE" = "302" ]; then
    echo "OK: Questionnaire accessible (redirection)"
    echo "   URL: $SURVEY_URL"
else
    echo "ATTENTION: Questionnaire peut-etre inactif (Code: $HTTP_CODE)"
    echo "   Verifiez que le questionnaire est active dans l'admin"
    echo "   URL: $SURVEY_URL"
fi

# Test sur reseau local pour tablettes
echo ""
echo "Test accessibilite tablettes..."
MAC_IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo "IP non trouvee")
if [ "$MAC_IP" != "IP non trouvee" ]; then
    echo "OK: IP WiFi du Mac: $MAC_IP"
    echo "   URL questionnaire tablettes: http://$MAC_IP:8081/index.php/$QUESTIONNAIRE_ID?lang=fr"
else
    echo "IP WiFi non detectee"
fi

# Verification conteneurs Docker
echo ""
echo "Etat des conteneurs..."
if docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "(limesurvey|limesurvey-db)"; then
    echo "OK: Conteneurs Docker actifs"
else
    echo "ERREUR: Probleme avec les conteneurs Docker"
    exit 1
fi

echo ""
echo "=========================================="
echo "URLs de test:"
echo "   Mac local:  $SURVEY_URL"
if [ "$MAC_IP" != "IP non trouvee" ]; then
echo "   Tablettes:  http://$MAC_IP:8081/index.php/$QUESTIONNAIRE_ID?lang=fr"
fi
echo "   Admin:      $LIMESURVEY_URL/index.php/admin"
echo "=========================================="
echo ""
echo "Test questionnaire termine!"