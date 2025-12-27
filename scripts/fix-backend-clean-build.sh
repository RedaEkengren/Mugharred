#!/bin/bash

# Fix Backend Clean Build - Följer goldenrules.md strikt
# Problemet: Backend import errors, inconsistent state

set -e

echo "🚀 Fixing backend clean build..."

# STEG 1: Stop all processes
echo "📝 STEG 1: Stopping all backend processes..."
pm2 stop mugharred-backend || echo "Process already stopped"
pm2 delete mugharred-backend || echo "Process not found"

# STEG 2: Clean all compiled files
echo "📝 STEG 2: Cleaning compiled files..."
cd /home/reda/development/mugharred/backend
rm -rf dist/
rm -rf node_modules/.cache/ || true

# STEG 3: Verify source files
echo "📝 STEG 3: Verifying source files..."
echo "Source files:"
ls -la src/

echo "Checking for room-service imports in source:"
if grep -r "room-service" src/ 2>/dev/null; then
  echo "❌ Found room-service imports in source!"
  echo "Details:"
  grep -rn "room-service" src/ 2>/dev/null || true
  exit 1
else
  echo "✅ No room-service imports found"
fi

# STEG 4: Clean build
echo "📝 STEG 4: Clean TypeScript build..."
npm run build

echo "📝 STEG 5: Verify dist files..."
echo "Built files:"
ls -la dist/

echo "Checking for room-service imports in server.js:"
if grep "room-service" dist/server.js 2>/dev/null; then
  echo "❌ Found room-service imports in server.js!"
  exit 1
else
  echo "✅ No room-service imports in server.js"
fi

# STEG 6: Test server start
echo "📝 STEG 6: Testing server start..."
timeout 5s node dist/server.js &
SERVER_PID=$!
sleep 2

if kill -0 $SERVER_PID 2>/dev/null; then
  echo "✅ Server starts successfully"
  kill $SERVER_PID
else
  echo "❌ Server failed to start"
  exit 1
fi

# STEG 7: Start with PM2
echo "📝 STEG 7: Starting with PM2..."
pm2 start dist/server.js --name mugharred-backend

# STEG 8: Verify PM2 status
echo "📝 STEG 8: Verifying PM2 status..."
sleep 3
pm2 list

# STEG 9: Test API endpoint
echo "📝 STEG 9: Testing API endpoint..."
sleep 2

if curl -s -o /dev/null -w "%{http_code}" localhost:3001/api/csrf-token | grep -q "200"; then
  echo "✅ API endpoint responding"
else
  echo "❌ API endpoint not responding"
  pm2 logs mugharred-backend --lines 10
  exit 1
fi

echo "✅ Backend clean build completed successfully!"

echo ""
echo "🎯 RESULTS:"
echo "   - Backend process clean and running"
echo "   - No room-service imports"
echo "   - API endpoints responding"
echo "   - Ready for login testing"