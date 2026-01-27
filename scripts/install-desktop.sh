#!/bin/bash

# Installation des raccourcis Bureau
# Usage: ./scripts/install-desktop.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DESKTOP="$HOME/Desktop"

echo "Installation des raccourcis Bureau..."

# Creer les alias sur le Bureau
ln -sf "$SCRIPT_DIR/Demarrer.command" "$DESKTOP/Demarrer LimeSurvey.command"
ln -sf "$SCRIPT_DIR/Arreter.command" "$DESKTOP/Arreter LimeSurvey.command"
ln -sf "$SCRIPT_DIR/Sauvegarder.command" "$DESKTOP/Sauvegarder LimeSurvey.command"
ln -sf "$SCRIPT_DIR/Exporter CSV.command" "$DESKTOP/Exporter CSV LimeSurvey.command"
ln -sf "$SCRIPT_DIR/Diagnostics.command" "$DESKTOP/Diagnostics LimeSurvey.command"

echo ""
echo "OK: Raccourcis crees sur le Bureau"
echo ""
echo "Vous pouvez maintenant double-cliquer sur:"
echo "  - Demarrer LimeSurvey.command"
echo "  - Arreter LimeSurvey.command"
echo "  - Sauvegarder LimeSurvey.command"
echo "  - Exporter CSV LimeSurvey.command"
echo "  - Diagnostics LimeSurvey.command"
