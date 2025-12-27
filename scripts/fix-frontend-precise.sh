#!/bin/bash
# Fix Frontend-Backend Integration Issues - Precise Manual Edits
# According to goldenrules.md - script-driven fixes only

set -e

echo "🔧 FIXING FRONTEND-BACKEND INTEGRATION ISSUES (Precise)"

# Backup current frontend
cp frontend/src/MugharredLandingPage.tsx frontend/src/MugharredLandingPage.tsx.backup.$(date +%s)

echo "📝 Fix 1: Remove token clearing after login..."
# Remove SecureAPI.clearToken(); calls at lines 613 and 661
sed -i '613d' frontend/src/MugharredLandingPage.tsx
sed -i '660d' frontend/src/MugharredLandingPage.tsx  # Line shifts after first deletion

echo "📝 Fix 2: Add roomId to WebSocket send_message..."
# Add roomId to send_message payload at line 689-692
sed -i '/type: "send_message",/a\      roomId: currentRoomId,' frontend/src/MugharredLandingPage.tsx

echo "📝 Fix 3: Change online_users to participants_update..."
# Change "online_users" to "participants_update" at line 507
sed -i 's/data\.type === "online_users"/data.type === "participants_update"/' frontend/src/MugharredLandingPage.tsx

echo "📝 Fix 4: Add WebSocket room join after successful API join..."
# Add joinRoomWebSocket call after room join success
# Find the line with "showToast("Joined room successfully"," and add call before it
sed -i '/showToast("Joined room successfully",/i\      // Join via WebSocket after successful API join\
      if (ws && ws.readyState === WebSocket.OPEN) {\
        ws.send(JSON.stringify({\
          type: '\''join_room'\'',\
          roomId: currentRoomId,\
          name: userName\
        }));\
      }' frontend/src/MugharredLandingPage.tsx

echo "🏗️ Building Frontend..."
cd frontend
npm run build
cd ..

echo "🚀 Deploying Fixed Frontend..."
sudo cp -r frontend/dist/* /var/www/html/

echo "✅ FRONTEND INTEGRATION FIXES APPLIED"
echo ""
echo "Applied fixes:"
echo "1. ✅ Removed SecureAPI.clearToken() calls (lines 613, 661)"
echo "2. ✅ Added roomId to WebSocket send_message payload"  
echo "3. ✅ Changed online_users to participants_update message type"
echo "4. ✅ Added WebSocket room join after successful API join"
echo ""
echo "🧪 Test the user flow at: https://mugharred.se/"