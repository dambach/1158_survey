#!/bin/bash

# Arret LimeSurvey
# Usage: ./scripts/stop-limesurvey.sh

echo "Arret..."

docker stop limesurvey limesurvey-db 2>/dev/null || true

echo "OK"
