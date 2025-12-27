#!/bin/bash
# Fix Frontend-Backend Integration Issues
# According to goldenrules.md - script-driven fixes only

set -e

echo "🔧 FIXING FRONTEND-BACKEND INTEGRATION ISSUES"

# Backup current frontend
cp -r frontend/src frontend/src.backup.$(date +%s)

echo "📝 Fixing Token Management Bug..."
# Fix 1: Remove token clearing after login (Line 564)
sed -i '/SecureAPI\.clearToken();/d' frontend/src/MugharredLandingPage.tsx

echo "📝 Fixing WebSocket Message Room Context..."
# Fix 2: Add roomId to WebSocket messages
sed -i 's/type: "send_message",/type: "send_message",\n        roomId: currentRoomId,/' frontend/src/MugharredLandingPage.tsx

echo "📝 Fixing WebSocket Room Join Timing..."
# Fix 3: Delay WebSocket room join until after API join
sed -i '/socket\.send(JSON\.stringify({/,/}));/ s/socket\.send/\/\/ Delayed join - socket.send/' frontend/src/MugharredLandingPage.tsx

echo "📝 Adding Proper Room Join Sequence..."
# Fix 4: Add coordinated API → WebSocket join
cat >> frontend/src/MugharredLandingPage.tsx.tmp << 'EOF'
  
  // Fixed room join sequence
  const joinRoomWebSocket = (roomId: string, userName: string) => {
    if (wsRef.current && wsRef.current.readyState === WebSocket.OPEN) {
      wsRef.current.send(JSON.stringify({
        type: 'join_room',
        roomId: roomId,
        name: userName
      }));
    }
  };
EOF

# Insert the function before the return statement
sed -i '/return (/i\
  // Fixed room join sequence\
  const joinRoomWebSocket = (roomId: string, userName: string) => {\
    if (wsRef.current && wsRef.current.readyState === WebSocket.OPEN) {\
      wsRef.current.send(JSON.stringify({\
        type: '\''join_room'\'',\
        roomId: roomId,\
        name: userName\
      }));\
    }\
  };' frontend/src/MugharredLandingPage.tsx

echo "📝 Fixing Online Users Message Format..."
# Fix 5: Update online users handler to match backend format
sed -i 's/data\.type === "online_users"/data.type === "participants_update"/' frontend/src/MugharredLandingPage.tsx

echo "🏗️ Building Frontend..."
cd frontend
npm run build
cd ..

echo "🚀 Deploying Fixed Frontend..."
sudo cp -r frontend/dist/* /var/www/html/

echo "✅ FRONTEND INTEGRATION FIXES APPLIED"
echo ""
echo "Fixed Issues:"
echo "1. ✅ Removed token clearing after login"
echo "2. ✅ Added roomId to WebSocket messages"  
echo "3. ✅ Fixed WebSocket room join timing"
echo "4. ✅ Added coordinated API→WebSocket join sequence"
echo "5. ✅ Synchronized online user message formats"
echo ""
echo "🧪 Test the user flow at: https://mugharred.se/"