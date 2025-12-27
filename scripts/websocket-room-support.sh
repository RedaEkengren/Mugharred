#!/bin/bash
# STEG 4: WebSocket Room-Specific Messaging
# Updates WebSocket handling for room functionality per MVP.md
set -e

echo "🔌 STEG 4: Adding WebSocket Room Support..."

# Backup current server
echo "📦 Creating backup of server.ts..."
cp backend/src/server.ts backend/src/server.ts.backup.$(date +%Y%m%d_%H%M%S)

echo "📝 Adding room WebSocket message handling to server.ts..."

# Add room-specific WebSocket handling after existing WebSocket setup
cat >> backend/src/server.ts << 'EOF'

// Room WebSocket Message Handling
interface RoomWebSocketMessage {
  type: 'join_room' | 'leave_room' | 'room_message' | 'room_participants';
  roomId?: string;
  text?: string;
  displayName?: string;
}

// Extend WebSocket with room info
interface RoomWebSocket extends WebSocket {
  sessionId?: string;
  currentRoomId?: string;
  displayName?: string;
}

// Update WebSocket message handling for rooms
const handleRoomWebSocketMessage = (ws: RoomWebSocket, message: RoomWebSocketMessage) => {
  try {
    switch (message.type) {
      case 'join_room':
        if (message.roomId && message.displayName && ws.sessionId) {
          const joinResult = roomService.joinRoom(
            { roomId: message.roomId, displayName: message.displayName },
            ws.sessionId
          );
          
          if (joinResult.success) {
            ws.currentRoomId = message.roomId;
            ws.displayName = message.displayName;
            
            // Broadcast to room participants
            broadcastToRoom(message.roomId, {
              type: 'participant_joined',
              participant: { sessionId: ws.sessionId, displayName: message.displayName }
            });
            
            ws.send(JSON.stringify({ type: 'room_joined', roomId: message.roomId }));
          } else {
            ws.send(JSON.stringify({ type: 'error', message: joinResult.error }));
          }
        }
        break;
        
      case 'room_message':
        if (ws.currentRoomId && message.text && ws.sessionId) {
          const result = roomService.addMessage(ws.currentRoomId, ws.sessionId, message.text);
          
          if (result.success && result.message) {
            // Broadcast message to all room participants
            broadcastToRoom(ws.currentRoomId, {
              type: 'room_message',
              message: result.message
            });
          }
        }
        break;
        
      case 'leave_room':
        if (ws.currentRoomId && ws.sessionId) {
          roomService.leaveRoom(ws.currentRoomId, ws.sessionId);
          
          // Notify other participants
          broadcastToRoom(ws.currentRoomId, {
            type: 'participant_left',
            sessionId: ws.sessionId
          });
          
          ws.currentRoomId = undefined;
          ws.displayName = undefined;
        }
        break;
    }
  } catch (error) {
    logger.error('Room WebSocket message error:', error);
    ws.send(JSON.stringify({ type: 'error', message: 'Internal server error' }));
  }
};

// Broadcast message to all participants in a room
const broadcastToRoom = (roomId: string, message: any) => {
  const room = roomService.getRoom(roomId);
  if (!room) return;
  
  wss.clients.forEach((client) => {
    const roomClient = client as RoomWebSocket;
    if (roomClient.readyState === WebSocket.OPEN && roomClient.currentRoomId === roomId) {
      roomClient.send(JSON.stringify(message));
    }
  });
};

// Update existing WebSocket connection handler to support rooms
const originalMessageHandler = wss.clients;

EOF

echo "✅ Room WebSocket support added!"
echo ""
echo "🎯 NEW WEBSOCKET FEATURES:"
echo "   - Room join/leave messaging"
echo "   - Room-specific message broadcasting"
echo "   - Participant management notifications"
echo "   - Error handling for room operations"
echo ""
echo "⚠️  NEXT: Need to integrate with existing WebSocket setup"