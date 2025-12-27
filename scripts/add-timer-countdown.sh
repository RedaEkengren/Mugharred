#!/bin/bash

# STEG 6: Add Timer Countdown UI for Room Expiration
# Per MVP.md: "Timer countdown (visible to all)"

set -e

echo "⏰ STEG 6: Adding Timer Countdown UI..."

FRONTEND_FILE="frontend/src/MugharredLandingPage.tsx"

# Backup current file
echo "📦 Creating backup of frontend component..."
cp "$FRONTEND_FILE" "${FRONTEND_FILE}.backup.timer.$(date +%Y%m%d_%H%M%S)"

echo "📝 Adding timer countdown component..."

# Add timer state and useEffect after existing useState declarations
sed -i '/const \[toast, setToast\] = useState.*null>/a\
  const [roomTimer, setRoomTimer] = useState<{timeLeft: number, expiresAt: number} | null>(null)' "$FRONTEND_FILE"

# Add timer useEffect after existing useEffect hooks
sed -i '/}, \[sessionId, socket\])/a\
\
  // Room timer countdown\
  useEffect(() => {\
    if (!roomTimer) return\
    \
    const interval = setInterval(() => {\
      const now = Date.now()\
      const timeLeft = Math.max(0, roomTimer.expiresAt - now)\
      \
      if (timeLeft === 0) {\
        setRoomTimer(null)\
        setToast({ type: "error", message: "Room has expired" })\
        return\
      }\
      \
      setRoomTimer(prev => prev ? { ...prev, timeLeft } : null)\
    }, 1000)\
    \
    return () => clearInterval(interval)\
  }, [roomTimer?.expiresAt])' "$FRONTEND_FILE"

# Add timer display component before the chat messages section
sed -i '/\{sessionId && (/i\
        {/* Room Timer Display */}\
        {roomTimer && (\
          <div className="mb-4 p-3 bg-orange-500/10 border border-orange-500/20 rounded-xl">\
            <div className="flex items-center justify-center space-x-2">\
              <Clock className="w-4 h-4 text-orange-400" />\
              <span className="text-orange-300 text-sm font-medium">\
                Room expires in {Math.floor(roomTimer.timeLeft / 60000)}:{String(Math.floor((roomTimer.timeLeft % 60000) / 1000)).padStart(2, "0")}\
              </span>\
            </div>\
          </div>\
        )}' "$FRONTEND_FILE"

# Add Clock import from lucide-react
sed -i 's/import { Send, Users, MessageSquare, Sparkles, Shield, Globe }/import { Send, Users, MessageSquare, Sparkles, Shield, Globe, Clock }/' "$FRONTEND_FILE"

# Update room creation to set timer
sed -i '/setToast({ type: "success", message: `Room "${roomName}" created!` })/a\
        // Set room timer\
        const duration = parseInt(roomDuration) * 60 * 1000 // Convert to ms\
        setRoomTimer({\
          timeLeft: duration,\
          expiresAt: Date.now() + duration\
        })' "$FRONTEND_FILE"

# Update join room to get timer info
sed -i '/setToast({ type: "success", message: `Joined room "${roomData.name}"!` })/a\
        // Set room timer from join response\
        if (roomData.expiresAt) {\
          const timeLeft = Math.max(0, roomData.expiresAt - Date.now())\
          setRoomTimer({\
            timeLeft,\
            expiresAt: roomData.expiresAt\
          })\
        }' "$FRONTEND_FILE"

echo "✅ Timer countdown UI added!"

echo ""
echo "🎯 NEW TIMER FEATURES:"
echo "   - Real-time countdown display (MM:SS format)"
echo "   - Orange warning styling for urgency"
echo "   - Auto-expires at 00:00"
echo "   - Clock icon for visual clarity"
echo "   - Set on room creation and join"

echo ""
echo "⏰ TIMER COUNTDOWN COMPLETED!"