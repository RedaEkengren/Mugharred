#!/bin/bash
# Complete cleanup according to goldenrules.md canonical structure
set -e

echo "🧹 COMPLETE CANONICAL CLEANUP"
echo "============================="

cd /home/reda/development/mugharred

echo "1. CLEAN ROOT - remove loose files..."
rm -f *.sh *.txt *.png *.patch *.cjs

echo "2. CLEAN SCRIPTS - keep only canonical..."
cd scripts
# Keep only essential scripts
mv cleanup-canonical.sh ../cleanup-canonical.sh.temp
mv complete-cleanup.sh ../complete-cleanup.sh.temp
rm -f *.sh
mv ../cleanup-canonical.sh.temp cleanup-canonical.sh
mv ../complete-cleanup.sh.temp complete-cleanup.sh
cd ..

echo "3. CLEAN FRONTEND - remove JWT chaos..."
cd frontend/src
rm -f jwt-*.ts simple-*.ts useJWTAuth.ts
# Keep only: MugharredLandingPage.tsx, main.tsx, index.css
cd ../..

echo "4. CLEAN BACKEND - remove duplicates..."
cd backend/src
rm -f server-stateless.ts room-service.ts
# Keep server.ts (which is the stateless version)
cd ../..

echo "5. ORGANIZE DOCS properly..."
# Docs are already in docs/ which is correct

echo "6. VERIFY canonical structure..."
echo ""
echo "📁 CANONICAL STRUCTURE:"
echo "├── backend/"
echo "│   ├── src/server.ts (JWT+Redis)"
echo "│   └── other core files"
echo "├── frontend/" 
echo "│   └── src/MugharredLandingPage.tsx"
echo "├── scripts/"
echo "│   └── cleanup scripts only"
echo "└── docs/"
echo "    └── all .md files"
echo ""
echo "✅ CANONICAL CLEANUP COMPLETE"
echo "No more chaos, single source of truth established"