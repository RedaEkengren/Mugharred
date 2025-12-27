#!/bin/bash

# Room-First Onboarding Implementation
# Per MVP.md: No global chat, instant rooms only
# Reuses existing chat code but scoped to rooms

set -e

echo "🚀 Implementing Room-First Onboarding..."

FRONTEND_FILE="frontend/src/MugharredLandingPage.tsx"

# Backup current file
echo "📦 Creating backup..."
cp "$FRONTEND_FILE" "${FRONTEND_FILE}.backup.room-first.$(date +%Y%m%d_%H%M%S)"

echo "📝 STEG 1: Update CreateRoomForm to include name field..."

# Add name field to CreateRoomForm props
sed -i '/onCreateRoom: (roomName: string, maxParticipants: number, duration: number) => Promise<void>;/s/roomName: string, maxParticipants: number, duration: number/userName: string, roomName: string, maxParticipants: number, duration: number/' "$FRONTEND_FILE"

# Add userName state to CreateRoomForm
sed -i "/const \[roomName, setRoomName\] = useState('');/a\\
  const [userName, setUserName] = useState('');" "$FRONTEND_FILE"

# Update handleSubmit in CreateRoomForm to include userName
sed -i 's/await onCreateRoom(roomName.trim(), maxParticipants, duration);/await onCreateRoom(userName.trim(), roomName.trim(), maxParticipants, duration);/' "$FRONTEND_FILE"

# Add name input field to CreateRoomForm (before room name)
sed -i '/<form onSubmit={handleSubmit} className="space-y-4">/a\
      <div>\
        <label className="block text-sm font-medium text-gray-700 mb-2">\
          Your Name\
        </label>\
        <input\
          type="text"\
          value={userName}\
          onChange={(e) => setUserName(e.target.value)}\
          className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-emerald-500 focus:border-transparent"\
          placeholder="Enter your name..."\
          required\
          minLength={2}\
          maxLength={50}\
        />\
      </div>' "$FRONTEND_FILE"

# Update submit button disabled state
sed -i 's/disabled={loading || roomName.trim().length < 2}/disabled={loading || userName.trim().length < 2 || roomName.trim().length < 2}/' "$FRONTEND_FILE"

echo "📝 STEG 2: Update hero section for Room-First approach..."

# Replace the login form in hero with Create Room button
sed -i '/<div className="max-w-md mx-auto">/,/<\/form>/c\
              <div className="max-w-md mx-auto">\
                <button\
                  onClick={() => setShowCreateRoomModal(true)}\
                  className="w-full bg-gradient-to-r from-emerald-500 to-green-600 text-white font-semibold py-4 px-6 rounded-xl hover:from-emerald-600 hover:to-green-700 transition-all duration-300 flex items-center justify-center gap-2 text-lg shadow-xl hover:shadow-2xl"\
                >\
                  Create Instant Room\
                  <ArrowRight size={20} />\
                </button>' "$FRONTEND_FILE"

echo "📝 STEG 3: Update handleCreateRoom to include login..."

# Update handleCreateRoom to accept userName and handle login
sed -i '/const handleCreateRoom = async (roomName: string, maxParticipants: number, duration: number) => {/c\
  const handleCreateRoom = async (userName: string, roomName: string, maxParticipants: number, duration: number) => {' "$FRONTEND_FILE"

# Add login logic before room creation
sed -i '/const handleCreateRoom = async (userName: string, roomName: string, maxParticipants: number, duration: number) => {/a\
    try {\
      // First login the user\
      const loginResponse = await SecureAPI.secureRequest("/api/login", {\
        method: "POST",\
        body: JSON.stringify({ name: userName }),\
      });\
      \
      if (!loginResponse.ok) {\
        showToast("Failed to login", "error");\
        return;\
      }\
      \
      const loginData = await loginResponse.json();\
      setSessionId(loginData.sessionId);\
      setName(userName);' "$FRONTEND_FILE"

# Move the existing try block content inside the login success
sed -i '/try {/{N;/const response = await SecureAPI.secureRequest/,/} catch (error) {/s/try {/      // Now create the room/}' "$FRONTEND_FILE"

echo "📝 STEG 4: Redirect directly to room after creation..."

# Update redirect to use room URL
sed -i 's|window.location.href = `/r/${data.roomId}`;|// Store room info and redirect\
        setShowCreateRoomModal(false);\
        window.location.href = `/r/${data.room.id}`;|' "$FRONTEND_FILE"

echo "📝 STEG 5: Remove global chat references..."

# Comment out the chat interface return block
sed -i '/\/\/ Chat interface for logged in users/,/return (/{s/return (/return null; \/\/ Global chat disabled per MVP.md\n  \/\/ Original chat code preserved below for room-specific use:\n  \/\* return (/}' "$FRONTEND_FILE"

# Close the comment at the end of the component
sed -i '/^}$/i\  *\/ \/\/ End of preserved chat code' "$FRONTEND_FILE"

echo "✅ Room-First Onboarding Implementation Complete!"

echo ""
echo "🎯 CHANGES MADE:"
echo "   - CreateRoomForm now includes name field"
echo "   - Hero shows 'Create Instant Room' instead of login"
echo "   - Room creation handles login automatically"
echo "   - Global chat disabled (code preserved for room use)"
echo "   - Direct redirect to room after creation"

echo ""
echo "⚠️  NEXT STEPS:"
echo "   1. Build and test the new flow"
echo "   2. Implement room-specific chat view"
echo "   3. Update backend to handle combined login+create"
echo "   4. Test complete room creation → chat flow"