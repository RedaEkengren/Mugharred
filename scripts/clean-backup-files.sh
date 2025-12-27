#!/bin/bash

# Clean Backup Files - Följer goldenrules.md strikt
# Problemet: Backup files i src/ directory förorenar systemet

set -e

echo "🚀 Cleaning backup files according to goldenrules.md..."

# STEG 1: List all backup files
echo "📝 STEG 1: Listing backup files in src/..."
find /home/reda/development/mugharred/backend/src/ -name "*.backup*" -type f

echo ""
echo "📝 STEG 2: Moving backup files to safe location..."

# Create backup storage outside src
mkdir -p /home/reda/development/mugharred/backend/backups/

# Move all backup files
mv /home/reda/development/mugharred/backend/src/*.backup* /home/reda/development/mugharred/backend/backups/ || echo "No backup files found"

echo "📝 STEG 3: Verifying src/ directory is clean..."
echo "Files in src/:"
ls -la /home/reda/development/mugharred/backend/src/

echo "📝 STEG 4: Testing for room-service imports..."
if grep -r "room-service" /home/reda/development/mugharred/backend/src/ 2>/dev/null || true; then
  echo "❌ Still found room-service imports!"
  exit 1
else
  echo "✅ No room-service imports found in src/"
fi

echo ""
echo "✅ Backup files cleaned successfully!"
echo "   - All backup files moved to backend/backups/"
echo "   - src/ directory is now clean"
echo "   - Ready for clean build"