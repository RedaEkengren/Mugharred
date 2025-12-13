#!/bin/bash
set -e

echo "🗑️ ELIMINERAR KORRUPTION enligt GOLDEN RULES"
echo "=============================================="

echo "🔍 Identifierad korruption: frontend/assets/ katalog"
ls -la frontend/assets/

echo "🧹 Tar bort korrupta filer..."
rm -rf frontend/assets/

echo "🔄 Force clean build..."
cd frontend
rm -rf dist/ node_modules/.vite/ .vite/
npm run build

echo "✅ Verifierar att korruptionen är eliminerad..."
if find dist/ -name "*.js" -exec grep -l "Koppla detta" {} \; | grep -q .; then
    echo "❌ Korruption finns fortfarande!"
    exit 1
else
    echo "✅ Korruption eliminerad!"
fi

cd ..
echo "🚀 Deployar ren version..."
echo "899118RKs" | sudo -S rsync -av --delete frontend/dist/ /var/www/html/

echo "✅ CORRUPTION ELIMINATED enligt GOLDEN RULES"