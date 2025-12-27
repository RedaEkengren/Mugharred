#!/bin/bash

# Add Room Chat View - Reuse global chat for room-specific chat
# Per user request: use existing chat code for rooms

set -e

echo "🚀 Adding Room Chat View..."

FRONTEND_FILE="frontend/src/MugharredLandingPage.tsx"

# Backup current file
echo "📦 Creating backup..."
cp "$FRONTEND_FILE" "${FRONTEND_FILE}.backup.room-chat.$(date +%Y%m%d_%H%M%S)"

echo "📝 STEG 1: Add room state..."

# Add room state after sessionId state
sed -i '/const \[sessionId, setSessionId\] = useState<string | null>(null);/a\
  const [currentRoomId, setCurrentRoomId] = useState<string | null>(null);\
  const [isInRoom, setIsInRoom] = useState(false);' "$FRONTEND_FILE"

echo "📝 STEG 2: Add useEffect to detect room URL..."

# Add useEffect to check for room URL on mount
sed -i '/useEffect(() => {/i\
  // Check if we are on a room URL\
  useEffect(() => {\
    const path = window.location.pathname;\
    const roomMatch = path.match(/^\\/r\\/([a-z0-9-]+)$/);\
    \
    if (roomMatch) {\
      const roomId = roomMatch[1];\
      setCurrentRoomId(roomId);\
      \
      // If not logged in, show join modal\
      if (!sessionId) {\
        // TODO: Show join room modal\
        console.log("Need to join room:", roomId);\
      } else {\
        // Already logged in, join the room\
        setIsInRoom(true);\
      }\
    }\
  }, [sessionId]);\
' "$FRONTEND_FILE"

echo "📝 STEG 3: Update condition to show chat for rooms..."

# Change the condition to show chat interface
sed -i 's/if (!sessionId) {/if (!sessionId && !currentRoomId) {/' "$FRONTEND_FILE"

echo "📝 STEG 4: Add room info to chat header..."

# Update the header to show room name instead of "Mugharred"
sed -i '/<h1 className="text-xl font-bold text-gray-900">Mugharred<\/h1>/c\
                <h1 className="text-xl font-bold text-gray-900">{currentRoomId ? `Room: ${currentRoomId}` : "Mugharred"}</h1>' "$FRONTEND_FILE"

echo "📝 STEG 5: Add room-specific WebSocket handling..."

# Update WebSocket connection to include roomId
sed -i 's|const wsUrl = `${protocol}//${window.location.host}/ws?sessionId=${encodeURIComponent(sessionId || '\'''\'')}`;|const wsUrl = `${protocol}//${window.location.host}/ws?sessionId=${encodeURIComponent(sessionId || '\'''\'')}${currentRoomId ? `\&roomId=${currentRoomId}` : '\'''\''}\&timestamp=${Date.now()}`;|' "$FRONTEND_FILE"

echo "✅ Room Chat View Added!"

echo ""
echo "🎯 CHANGES MADE:"
echo "   - Added currentRoomId and isInRoom state"
echo "   - Auto-detect /r/room-id URLs"
echo "   - Show chat interface for room URLs"
echo "   - Pass roomId to WebSocket connection"
echo "   - Display room name in header"

echo ""
echo "⚠️  NEXT STEPS:"
echo "   1. Add join room modal for non-logged users"
echo "   2. Update backend WebSocket to handle room messages"
echo "   3. Show room participants instead of all online users"
echo "   4. Add leave room functionality"