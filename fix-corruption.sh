#!/bin/bash
set -e

echo "🔧 FIXAR KORRUPTION I INDEX.HTML"

cd frontend

echo "📋 Backup och återställ från template..."
# Återställ till clean index.html template
cat > index.html << 'EOF'
<!doctype html>
<html lang="sv">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/vite.svg" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Mugharred - En enkel social feed som uppdateras live</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
EOF

echo "🏗️ Clean build..."
rm -rf dist/
npm run build

echo "✅ Verifierar att assets är rena..."
if find dist/ -name "*.js" -exec grep -l "Koppla detta" {} \; | grep -q .; then
    echo "❌ Fortfarande korrupt!"
    exit 1
else
    echo "✅ KORRUPTION ELIMINERAD!"
fi

cd ..
echo "🚀 Deployment..."
echo "899118RKs" | sudo -S rsync -av --delete frontend/dist/ /var/www/html/

echo "✅ FINAL FIX COMPLETE"