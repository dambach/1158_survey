#!/bin/bash

# Compilation de l'application LimeSurvey.app
# Usage: ./app/build-app.sh

set -e

cd "$(dirname "$0")"

echo "Installation des dependances..."
pip install -r requirements.txt

# Generer l'icone si elle n'existe pas
if [ ! -f "icon.icns" ]; then
    echo ""
    echo "Generation de l'icone..."
    qlmanage -t -s 512 -o . ../Limesurvey_logo.svg 2>/dev/null
    mv Limesurvey_logo.svg.png icon.png 2>/dev/null || true
    # Creer iconset avec Python/Pillow
    python3 -c "
from PIL import Image
import os
img = Image.open('icon.png')
os.makedirs('icon.iconset', exist_ok=True)
for size in [16, 32, 64, 128, 256, 512]:
    resized = img.resize((size, size), Image.Resampling.LANCZOS)
    resized.save(f'icon.iconset/icon_{size}x{size}.png')
    if size <= 256:
        resized.resize((size*2, size*2), Image.Resampling.LANCZOS).save(f'icon.iconset/icon_{size}x{size}@2x.png')
"
    iconutil -c icns icon.iconset -o icon.icns
    rm -rf icon.iconset icon.png
fi

echo ""
echo "Compilation de l'application..."

# Supprimer ancienne app si existe
rm -rf ../LimeSurvey.app

pyinstaller \
    --name="LimeSurvey" \
    --windowed \
    --onedir \
    --icon="icon.icns" \
    --osx-bundle-identifier="com.limesurvey.lab" \
    limesurvey_app.py

echo ""
echo "Deplacement de l'application..."
mv dist/LimeSurvey.app ../LimeSurvey.app

echo ""
echo "Nettoyage..."
rm -rf build dist *.spec

echo ""
echo "OK: Application creee -> LimeSurvey.app"
echo ""
echo "Pour lancer: open ../LimeSurvey.app"
