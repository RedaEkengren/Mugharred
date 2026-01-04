#!/bin/bash
set -e

echo "🎙️ PHASE 2 - Sprint 2A: WebRTC Signaling Implementation"
echo "=================================================="
echo ""

# Ensure we're in project root
cd /home/reda/development/mugharred

echo "📋 This script will:"
echo "1. Extend WebSocket service with WebRTC signaling"
echo "2. Add passcode support to rooms"
echo "3. Update room types for voice support"
echo "4. PRESERVE all existing functionality"
echo "5. PRESERVE all UI/design elements"
echo ""

read -p "Proceed with Phase 2 WebRTC signaling? (y/N): " -r
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Phase 2 implementation cancelled"
    exit 0
fi

echo ""
echo "🔧 Step 1: Backing up current files..."
mkdir -p backend/src/phase2-backup
cp backend/src/websocket-service.ts backend/src/phase2-backup/
cp backend/src/room-types.ts backend/src/phase2-backup/
echo "✅ Backup created in backend/src/phase2-backup/"

echo ""
echo "🔧 Step 2: Extending room types for WebRTC..."

cat >> backend/src/room-types.ts << 'EOF'

// Phase 2: WebRTC Extensions
export interface WebRTCSignal {
  type: 'offer' | 'answer' | 'ice-candidate';
  from: string;
  to: string;
  data: any;
}

export interface ParticipantVoiceState {
  connectionId: string;
  peerState: 'disconnected' | 'connecting' | 'connected';
  isMuted: boolean;
  isPTT: boolean;
}

// Extend Room interface in implementation
export interface RoomVoiceSettings {
  voiceEnabled: boolean;
  passcode?: string;
  maxVoiceParticipants: number;
}
EOF

echo "✅ Room types extended with WebRTC interfaces"

echo ""
echo "🔧 Step 3: Creating WebRTC signaling handler..."

cat > backend/src/webrtc-signaling.ts << 'EOF'
// WebRTC Signaling Handler for Phase 2
import { WebSocket } from 'ws';
import { redisRoomService } from './redis-room-service.js';

export class WebRTCSignaling {
  static async handleSignal(
    roomId: string,
    fromUserId: string,
    signal: any,
    broadcast: (roomId: string, message: any, excludeUserId?: string) => void
  ): Promise<void> {
    const room = await redisRoomService.getRoom(roomId);
    if (!room) return;

    switch (signal.type) {
      case 'offer':
      case 'answer':
      case 'ice-candidate':
        // Relay signal to specific peer
        broadcast(roomId, {
          type: 'webrtc-signal',
          signal: {
            type: signal.type,
            from: fromUserId,
            data: signal.data
          }
        }, fromUserId);
        break;

      case 'join-voice':
        // Notify others that user wants to join voice
        broadcast(roomId, {
          type: 'voice-participant-joined',
          userId: fromUserId
        }, fromUserId);
        break;

      case 'leave-voice':
        // Notify others that user left voice
        broadcast(roomId, {
          type: 'voice-participant-left',
          userId: fromUserId
        }, fromUserId);
        break;
    }
  }
}
EOF

echo "✅ WebRTC signaling handler created"

echo ""
echo "🔧 Step 4: Updating WebSocket service..."

# This would normally modify websocket-service.ts
# For now, we'll create a patch file that can be applied
cat > backend/src/websocket-service-phase2.patch << 'EOF'
// Add to imports:
import { WebRTCSignaling } from './webrtc-signaling.js';

// Add to handleMessage switch statement:
case "webrtc-signal":
  await WebRTCSignaling.handleSignal(
    connection.currentRoomId!,
    connection.user.userId,
    message,
    (roomId, msg, exclude) => this.broadcastToRoom(roomId, msg, exclude)
  );
  break;

// Add passcode validation to handleJoinRoom:
if (room.passcode && message.passcode !== room.passcode) {
  this.sendToConnection(connectionId, {
    type: "error",
    error: "Invalid passcode"
  });
  return;
}
EOF

echo "✅ WebSocket service patch created (manual application needed)"

echo ""
echo "🔧 Step 5: Building backend..."
cd backend
npm run build

echo ""
echo "✅ Phase 2 WebRTC signaling backend ready!"
echo ""
echo "📝 NEXT STEPS:"
echo "1. Manually apply websocket-service-phase2.patch"
echo "2. Run phase2-voice-ui.sh for frontend changes"
echo "3. Test with 2 users in same room"
echo ""
echo "⚠️  IMPORTANT: UI/Design remains UNCHANGED"
echo "🔄 Rollback: restore from backend/src/phase2-backup/"