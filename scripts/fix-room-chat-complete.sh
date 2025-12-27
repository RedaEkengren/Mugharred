#!/bin/bash

# Fix Room Chat Implementation Completely
# Följer goldenrules.md och MVP.md strikt

set -e

echo "🚀 Fixing Room Chat Implementation..."

FRONTEND_FILE="frontend/src/MugharredLandingPage.tsx"

echo "📝 STEG 1: Fix syntax error in CreateRoomForm..."

# Fix the broken if statement
sed -i '59s/if (!sessionId if (!sessionId) {if (!sessionId) { !currentRoomId) {/if (!sessionId) {/' "$FRONTEND_FILE"

echo "📝 STEG 2: Remove duplicate useEffect..."

# Remove the duplicate useEffect (lines 50-67)
sed -i '50,67d' "$FRONTEND_FILE"

echo "📝 STEG 3: Add proper room detection in main component..."

# Find the line with const [sessionId, setSessionId] and add room state after it
sed -i '/const \[sessionId, setSessionId\] = useState<string | null>(null);/a\
  const [currentRoomId, setCurrentRoomId] = useState<string | null>(null);\
  const [isInRoom, setIsInRoom] = useState(false);' "$FRONTEND_FILE"

echo "📝 STEG 4: Add useEffect to detect room URL in main component..."

# Add after the WebSocket useEffect
sed -i '/const messagesEndRef = useRef<HTMLDivElement>(null);/a\
\
  // Check for room URL on mount\
  useEffect(() => {\
    const path = window.location.pathname;\
    const roomMatch = path.match(/^\\/r\\/([a-z0-9-]+)$/);\
    \
    if (roomMatch) {\
      const roomId = roomMatch[1];\
      console.log("Detected room URL:", roomId);\
      setCurrentRoomId(roomId);\
      \
      // If already logged in, mark as in room\
      if (sessionId) {\
        setIsInRoom(true);\
      }\
    }\
  }, [sessionId]);' "$FRONTEND_FILE"

echo "📝 STEG 5: Update condition to show chat for rooms..."

# Change the main render condition to show chat for room URLs
sed -i 's/if (sessionId) {/if (sessionId || currentRoomId) {/' "$FRONTEND_FILE"

echo "📝 STEG 6: Add room info to chat header..."

# Update header to show room name
sed -i 's/<h1 className="text-xl font-bold text-gray-900">Mugharred<\/h1>/<h1 className="text-xl font-bold text-gray-900">{currentRoomId ? `Room: ${currentRoomId}` : "Mugharred"}<\/h1>/' "$FRONTEND_FILE"

echo "📝 STEG 7: Update WebSocket URL to include roomId..."

# Find the WebSocket URL and add roomId parameter
sed -i 's|const wsUrl = `${protocol}//${window.location.host}/ws?sessionId=${encodeURIComponent(sessionId || '\'''\'')}`;|const wsUrl = `${protocol}//${window.location.host}/ws?sessionId=${encodeURIComponent(sessionId || '\'''\'')}${currentRoomId ? `\&roomId=${currentRoomId}` : '\'''\''}\&timestamp=${Date.now()}`;|' "$FRONTEND_FILE"

echo "📝 STEG 8: Add join room modal for non-logged users..."

# Add JoinRoomModal component before CreateRoomForm
cat >> /tmp/join-room-modal.tsx << 'EOF'

// Join Room Modal Component
const JoinRoomModal: React.FC<{
  roomId: string;
  onJoin: (userName: string) => Promise<void>;
  onCancel: () => void;
}> = ({ roomId, onJoin, onCancel }) => {
  const [userName, setUserName] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (userName.trim().length < 2) return;
    
    setLoading(true);
    try {
      await onJoin(userName.trim());
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
      <div className="bg-white rounded-xl shadow-xl p-8 max-w-md w-full">
        <h2 className="text-2xl font-bold text-gray-900 mb-2">Join Room</h2>
        <p className="text-gray-600 mb-6">Room ID: {roomId}</p>
        
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Your Name
            </label>
            <input
              type="text"
              value={userName}
              onChange={(e) => setUserName(e.target.value)}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-emerald-500 focus:border-transparent"
              placeholder="Enter your name..."
              required
              minLength={2}
              maxLength={50}
              autoFocus
            />
          </div>
          
          <div className="flex gap-4">
            <button
              type="button"
              onClick={onCancel}
              className="flex-1 px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors"
              disabled={loading}
            >
              Cancel
            </button>
            <button
              type="submit"
              className="flex-1 bg-emerald-500 text-white px-4 py-2 rounded-lg hover:bg-emerald-600 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
              disabled={loading || userName.trim().length < 2}
            >
              {loading ? 'Joining...' : 'Join Room'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
EOF

# Insert the component after CreateRoomForm
sed -i '/^};$/,/^const MugharredLandingPage/{ /^const MugharredLandingPage/i\
'"$(cat /tmp/join-room-modal.tsx)"'
}' "$FRONTEND_FILE"

echo "📝 STEG 9: Add state and handler for join room modal..."

# Add state for join room modal
sed -i '/const \[showCreateRoomModal, setShowCreateRoomModal\] = useState(false);/a\
  const [showJoinRoomModal, setShowJoinRoomModal] = useState(false);' "$FRONTEND_FILE"

echo "📝 STEG 10: Add join room handler..."

# Add handleJoinRoom after handleCreateRoom
sed -i '/};$/,/return (/{/return (/i\
  const handleJoinRoom = async (userName: string) => {\
    try {\
      // First login the user\
      const loginResponse = await SecureAPI.secureRequest("/api/login", {\
        method: "POST",\
        body: JSON.stringify({ name: userName }),\
      });\
      \
      if (!loginResponse.ok) {\
        const errorData = await loginResponse.json();\
        showToast(errorData.error || "Failed to login", "error");\
        return;\
      }\
      \
      const loginData = await loginResponse.json();\
      setSessionId(loginData.sessionId);\
      setName(userName);\
      \
      // Update CSRF token after login\
      SecureAPI.clearToken();\
      \
      // Now join the room\
      const response = await SecureAPI.secureRequest("/api/join-room", {\
        method: "POST",\
        body: JSON.stringify({ \
          roomId: currentRoomId,\
          name: userName \
        }),\
      });\
      \
      if (response.ok) {\
        setShowJoinRoomModal(false);\
        setIsInRoom(true);\
        showToast("Joined room successfully!", "success");\
      } else {\
        const errorData = await response.json();\
        showToast(errorData.error || "Failed to join room", "error");\
      }\
    } catch (error) {\
      console.error("Join room error:", error);\
      showToast("Network error joining room", "error");\
    }\
  };
}' "$FRONTEND_FILE"

echo "📝 STEG 11: Update room detection to show join modal..."

# Update the room detection useEffect to show join modal
sed -i '/console.log("Detected room URL:", roomId);/a\
      \
      // If not logged in, show join modal\
      if (!sessionId) {\
        setShowJoinRoomModal(true);\
      }' "$FRONTEND_FILE"

echo "📝 STEG 12: Add join room modal to render..."

# Add join room modal render after create room modal
sed -i '/{showCreateRoomModal && (/,/)}/a\
\
      {showJoinRoomModal && currentRoomId && (\
        <JoinRoomModal\
          roomId={currentRoomId}\
          onJoin={handleJoinRoom}\
          onCancel={() => {\
            setShowJoinRoomModal(false);\
            window.location.href = "/";\
          }}\
        />\
      )}' "$FRONTEND_FILE"

# Clean up temp file
rm -f /tmp/join-room-modal.tsx

echo "✅ Room Chat Implementation Fixed!"

echo ""
echo "🎯 CHANGES MADE:"
echo "   - Fixed syntax errors from previous script"
echo "   - Added proper room URL detection"
echo "   - Show chat interface for room URLs"
echo "   - Added join room modal for non-logged users"
echo "   - Room ID shown in chat header"
echo "   - WebSocket includes roomId parameter"

echo ""
echo "📋 NÄSTA STEG:"
echo "   1. Build and deploy frontend"
echo "   2. Test room creation → room chat flow"
echo "   3. Update backend WebSocket to handle room-specific messages"
echo "   4. Implement room participant list"