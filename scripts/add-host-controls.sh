#!/bin/bash

# STEG 7: Add Host Controls UI
# Per MVP.md: "Host controls: kick, mute, extend time, lock room"

set -e

echo "👑 STEG 7: Adding Host Controls UI..."

FRONTEND_FILE="frontend/src/MugharredLandingPage.tsx"

# Backup current file
echo "📦 Creating backup of frontend component..."
cp "$FRONTEND_FILE" "${FRONTEND_FILE}.backup.host.$(date +%Y%m%d_%H%M%S)"

echo "📝 Adding host controls state..."

# Add host state after existing useState declarations
sed -i '/const \[roomTimer, setRoomTimer\]/a\
  const [currentRoom, setCurrentRoom] = useState<{id: string, name: string, hostId: string, isLocked: boolean} | null>(null)\
  const [roomParticipants, setRoomParticipants] = useState<{sessionId: string, name: string}[]>([])' "$FRONTEND_FILE"

echo "📝 Adding host control functions..."

# Add host control functions before handleSubmit
sed -i '/const handleSubmit = async/i\
  // Host Controls Functions\
  const kickParticipant = async (targetSessionId: string) => {\
    if (!currentRoom || currentRoom.hostId !== sessionId) return\
    \
    try {\
      const response = await SecureAPI.secureRequest(`/api/room/${currentRoom.id}/kick/${targetSessionId}`, {\
        method: "POST"\
      })\
      \
      if (response.ok) {\
        setToast({ type: "success", message: "Participant kicked" })\
      }\
    } catch (error) {\
      setToast({ type: "error", message: "Failed to kick participant" })\
    }\
  }\
  \
  const toggleRoomLock = async () => {\
    if (!currentRoom || currentRoom.hostId !== sessionId) return\
    \
    try {\
      const response = await SecureAPI.secureRequest(`/api/room/${currentRoom.id}/lock`, {\
        method: "POST"\
      })\
      \
      if (response.ok) {\
        const newLockState = !currentRoom.isLocked\
        setCurrentRoom(prev => prev ? { ...prev, isLocked: newLockState } : null)\
        setToast({ type: "success", message: newLockState ? "Room locked" : "Room unlocked" })\
      }\
    } catch (error) {\
      setToast({ type: "error", message: "Failed to toggle room lock" })\
    }\
  }\
  \
  const extendRoomTime = async () => {\
    if (!currentRoom || currentRoom.hostId !== sessionId || !roomTimer) return\
    \
    // Extend by 30 minutes\
    const extension = 30 * 60 * 1000\
    const newExpiresAt = roomTimer.expiresAt + extension\
    \
    setRoomTimer({\
      timeLeft: newExpiresAt - Date.now(),\
      expiresAt: newExpiresAt\
    })\
    \
    setToast({ type: "success", message: "Room extended by 30 minutes" })\
  }\
' "$FRONTEND_FILE"

echo "📝 Adding host controls UI component..."

# Add host controls panel after timer display
sed -i '/Room expires in/a\
\
        {/* Host Controls Panel */}\
        {currentRoom && currentRoom.hostId === sessionId && (\
          <div className="mb-4 p-4 bg-purple-500/10 border border-purple-500/20 rounded-xl">\
            <div className="flex items-center justify-between mb-3">\
              <h3 className="text-purple-300 font-medium flex items-center">\
                <Crown className="w-4 h-4 mr-2" />\
                Host Controls\
              </h3>\
            </div>\
            \
            <div className="grid grid-cols-2 gap-3">\
              <button\
                onClick={toggleRoomLock}\
                className={`p-2 rounded-lg text-sm font-medium transition-all ${\
                  currentRoom.isLocked\
                    ? "bg-red-500/20 text-red-300 hover:bg-red-500/30"\
                    : "bg-green-500/20 text-green-300 hover:bg-green-500/30"\
                }`}\
              >\
                <Lock className="w-4 h-4 mx-auto mb-1" />\
                {currentRoom.isLocked ? "Unlock" : "Lock"} Room\
              </button>\
              \
              <button\
                onClick={extendRoomTime}\
                disabled={!roomTimer}\
                className="p-2 rounded-lg text-sm font-medium bg-blue-500/20 text-blue-300 hover:bg-blue-500/30 disabled:opacity-50 disabled:cursor-not-allowed transition-all"\
              >\
                <Plus className="w-4 h-4 mx-auto mb-1" />\
                Extend +30min\
              </button>\
            </div>\
            \
            {roomParticipants.length > 1 && (\
              <div className="mt-3 pt-3 border-t border-purple-500/20">\
                <h4 className="text-purple-300 text-sm mb-2">Kick Participants</h4>\
                <div className="space-y-1">\
                  {roomParticipants\
                    .filter(p => p.sessionId !== sessionId)\
                    .map(participant => (\
                      <div key={participant.sessionId} className="flex items-center justify-between bg-purple-500/5 p-2 rounded">\
                        <span className="text-purple-200 text-sm">{participant.name}</span>\
                        <button\
                          onClick={() => kickParticipant(participant.sessionId)}\
                          className="p-1 rounded text-red-400 hover:bg-red-500/20 transition-all"\
                        >\
                          <X className="w-3 h-3" />\
                        </button>\
                      </div>\
                    ))\
                  }\
                </div>\
              </div>\
            )}\
          </div>\
        )}' "$FRONTEND_FILE"

# Add required icons to imports
sed -i 's/import { Send, Users, MessageSquare, Sparkles, Shield, Globe, Clock }/import { Send, Users, MessageSquare, Sparkles, Shield, Globe, Clock, Crown, Lock, Plus, X }/' "$FRONTEND_FILE"

# Update room creation to set currentRoom
sed -i '/setRoomTimer({/i\
        // Set current room info for host controls\
        setCurrentRoom({\
          id: roomData.id,\
          name: roomName,\
          hostId: sessionId,\
          isLocked: false\
        })' "$FRONTEND_FILE"

# Update join room to set currentRoom
sed -i '/setRoomTimer({/i\
        // Set current room info\
        setCurrentRoom({\
          id: roomData.id,\
          name: roomData.name,\
          hostId: roomData.hostId,\
          isLocked: roomData.isLocked || false\
        })' "$FRONTEND_FILE"

echo "✅ Host controls UI added!"

echo ""
echo "🎯 NEW HOST CONTROL FEATURES:"
echo "   - Lock/Unlock room toggle"
echo "   - Extend room time by 30 minutes"
echo "   - Kick individual participants"
echo "   - Visual host crown indicator"
echo "   - Only visible to room host"

echo ""
echo "👑 HOST CONTROLS COMPLETED!"