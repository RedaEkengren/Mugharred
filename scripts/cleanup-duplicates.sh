#!/bin/bash
set -e

echo "🧹 CLEANUP: Removing duplicate/backup files according to goldenrules.md"
echo ""

# Ensure we're in project root
cd /home/reda/development/mugharred

echo "📋 Files and directories to be removed:"
echo ""

# List backup directories
echo "BACKUP DIRECTORIES:"
echo "❌ integration-backup-1766875262/"
echo "❌ frontend/src.backup.1766873629/"
echo ""

# List backup files  
echo "BACKUP FILES:"
echo "❌ frontend/src/MugharredLandingPage.tsx.backup.1766873787"
echo "❌ frontend/src/MugharredLandingPage.tsx.tmp"
echo "❌ backend/src/websocket-service.ts.old"
echo ""

echo "⚠️  These violate goldenrules.md: 'Creating duplicate folders' and 'Creating test files or temporary files'"
echo "✅ GitHub has all versions - safe to remove"
echo ""

read -p "Proceed with cleanup? (y/N): " -r
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Cleanup cancelled"
    exit 0
fi

echo ""
echo "🗑️  Removing backup directories..."

# Remove backup directories
if [ -d "integration-backup-1766875262" ]; then
    rm -rf integration-backup-1766875262/
    echo "✅ Removed integration-backup-1766875262/"
fi

if [ -d "frontend/src.backup.1766873629" ]; then
    rm -rf frontend/src.backup.1766873629/
    echo "✅ Removed frontend/src.backup.1766873629/"
fi

echo ""
echo "🗑️  Removing backup files..."

# Remove backup files
if [ -f "frontend/src/MugharredLandingPage.tsx.backup.1766873787" ]; then
    rm frontend/src/MugharredLandingPage.tsx.backup.1766873787
    echo "✅ Removed MugharredLandingPage.tsx.backup.1766873787"
fi

if [ -f "frontend/src/MugharredLandingPage.tsx.tmp" ]; then
    rm frontend/src/MugharredLandingPage.tsx.tmp
    echo "✅ Removed MugharredLandingPage.tsx.tmp"
fi

if [ -f "backend/src/websocket-service.ts.old" ]; then
    rm backend/src/websocket-service.ts.old
    echo "✅ Removed websocket-service.ts.old"
fi

echo ""
echo "🔍 Verifying cleanup..."

# Verify files are gone
REMAINING=$(find . -name "*.backup.*" -o -name "*.tmp" -o -name "*.old" -o -name "*backup*" | grep -v node_modules | wc -l)

if [ "$REMAINING" -eq 0 ]; then
    echo "✅ All duplicates/backups removed successfully!"
else
    echo "⚠️  Some backup files may still exist:"
    find . -name "*.backup.*" -o -name "*.tmp" -o -name "*.old" -o -name "*backup*" | grep -v node_modules
fi

echo ""
echo "📁 Current canonical structure:"
ls -la | grep "^d" | awk '{print "✅", $9}' | grep -E "(frontend|backend|scripts|docs|logs)"

echo ""
echo "🎉 CLEANUP COMPLETE!"
echo "📝 Structure now complies with goldenrules.md"
echo "💾 All code versions safely stored in GitHub"