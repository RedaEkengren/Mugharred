#!/bin/bash
# Clean up chaos and establish canonical structure
# Compliance: goldenrules.md - single source of truth

set -e

echo "🧹 CLEANUP CANONICAL STRUCTURE"
echo "=============================="

cd /home/reda/development/mugharred

echo "1. STOP all running servers..."
pkill -f "tsx.*server" || true
pkill -f "node.*server" || true

echo "2. CLEAN backend - establish canonical structure..."
cd backend

# Remove all invalid server files (keep only server-stateless.ts)
rm -f src/server.ts
rm -f src/server-jwt.ts  
rm -f src/server-sessions-backup.ts

# Remove backup folders
rm -rf backups/
rm -rf src.backup.*/

# Make server-stateless.ts the canonical server.ts
cp src/server-stateless.ts src/server.ts

echo "3. CLEAN frontend - remove JS chaos..."
cd ../frontend

# Remove all old JS files from production
echo "899118RKs" | sudo -S rm -f /var/www/html/assets/index-*.js
echo "899118RKs" | sudo -S rm -f /var/www/html/assets/index-*.css

echo "4. BUILD canonical frontend..."
npm run build

echo "5. DEPLOY canonical build..."
echo "899118RKs" | sudo -S cp -r dist/* /var/www/html/

echo "6. START canonical backend..."
cd ../backend
npm run build
node dist/server.js &
SERVER_PID=$!

echo "✅ CANONICAL STRUCTURE ESTABLISHED"
echo ""
echo "Backend: server-stateless.ts (now server.ts)"
echo "Frontend: Clean build deployed"
echo "Server PID: $SERVER_PID"
echo ""
echo "Test at: https://mugharred.se/r/smooth-tree-7321"