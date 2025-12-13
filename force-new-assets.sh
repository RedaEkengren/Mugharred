#!/bin/bash
set -e

echo "🔄 Tvingar nya asset-namn genom att ändra källkod"

cd frontend/src

# Lägg till tidsstämpel som kommentar för att ändra hash
echo "// Build timestamp: $(date)" >> MugharredLandingPage.tsx

cd ..
npm run build

echo "📋 Nya assets:"
ls -la dist/assets/

echo "🚀 Deployar..."
echo "899118RKs" | sudo -S rsync -av --delete dist/ /var/www/html/

echo "✅ Deployment klar med nya asset-hash"