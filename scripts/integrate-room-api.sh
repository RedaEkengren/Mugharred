#!/bin/bash
# STEG 2: API Endpoints Integration
# Integrates room system with existing backend APIs

set -e

echo "🔌 STEG 2: Integrating Room API Endpoints..."

# Update server.ts to include room endpoints
echo "📝 Adding room endpoints to server.ts..."

# First, let's add the imports at the top of server.ts
echo "📦 Adding room service imports..."

# We'll read the current server.ts and modify it
# Add room service import after existing imports
sed -i '/import.*types.*from.*\.\/types\.js/a import { roomService } from '\''./room-service.js'\'';' backend/src/server.ts
sed -i '/import.*types.*from.*\.\/types\.js/a import { CreateRoomRequest, JoinRoomRequest } from '\''./room-types.js'\'';' backend/src/server.ts

echo "✅ Room imports added to server.ts"

# Create new room API endpoints file to append
cat > /tmp/room-endpoints.ts << 'EOF'

// ====== MVP ROOM SYSTEM ENDPOINTS ======

// Create new room (MVP Phase 1)
app.post('/api/create-room', doubleCsrfProtection, async (req, res) => {
  try {
    const createRequest: CreateRoomRequest = req.body;
    
    // Validate session exists (light identity for host)
    if (!req.session?.id) {
      return res.status(401).json({ error: 'Session required' });
    }
    
    // Create room using room service
    const { room, roomLink } = roomService.createRoom(createRequest, req.session.id);
    
    // Store room session info
    req.session.roomId = room.id;
    req.session.isHost = true;
    req.session.name = createRequest.hostName;
    
    // Security logging
    logger.info('Room created', {
      roomId: room.id,
      hostName: createRequest.hostName,
      duration: createRequest.duration,
      maxParticipants: createRequest.maxParticipants,
      sessionId: req.session.id
    });
    
    res.json({
      success: true,
      room: {
        id: room.id,
        name: room.name,
        link: roomLink,
        duration: room.duration,
        maxParticipants: room.maxParticipants,
        expiresAt: room.expiresAt
      }
    });
    
  } catch (error: any) {
    logger.error('Room creation failed', { error: error.message, sessionId: req.session?.id });
    res.status(400).json({ error: error.message });
  }
});

// Get room info for join preview (MVP Phase 1)
app.get('/api/room/:roomId', async (req, res) => {
  try {
    const { roomId } = req.params;
    const room = roomService.getRoom(roomId);
    
    if (!room) {
      return res.status(404).json({ error: 'Room not found' });
    }
    
    if (Date.now() > room.expiresAt) {
      return res.status(410).json({ error: 'Room has expired' });
    }
    
    // Public room info for join preview
    res.json({
      id: room.id,
      name: room.name,
      participantCount: room.participants.size,
      maxParticipants: room.maxParticipants,
      isLocked: room.isLocked,
      expiresAt: room.expiresAt,
      timeRemaining: room.expiresAt - Date.now()
    });
    
  } catch (error: any) {
    logger.error('Room info fetch failed', { error: error.message, roomId: req.params.roomId });
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Join existing room (MVP Phase 1)
app.post('/api/join-room/:roomId', doubleCsrfProtection, async (req, res) => {
  try {
    const { roomId } = req.params;
    const joinRequest: JoinRoomRequest = {
      roomId,
      participantName: req.body.participantName
    };
    
    // Ensure session exists
    if (!req.session?.id) {
      return res.status(401).json({ error: 'Session required' });
    }
    
    // Join room via room service  
    const result = roomService.joinRoom(joinRequest, req.session.id);
    
    if (!result.success) {
      return res.status(400).json({ error: result.error });
    }
    
    // Store room session info
    req.session.roomId = roomId;
    req.session.isHost = false;
    req.session.name = joinRequest.participantName;
    
    // Security logging
    logger.info('Room joined', {
      roomId,
      participantName: joinRequest.participantName,
      sessionId: req.session.id,
      participantCount: result.room?.participants.size
    });
    
    res.json({
      success: true,
      room: {
        id: result.room!.id,
        name: result.room!.name,
        participantCount: result.room!.participants.size,
        maxParticipants: result.room!.maxParticipants,
        expiresAt: result.room!.expiresAt
      }
    });
    
  } catch (error: any) {
    logger.error('Room join failed', { error: error.message, roomId: req.params.roomId });
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Leave room (MVP Phase 1)
app.post('/api/leave-room', doubleCsrfProtection, async (req, res) => {
  try {
    if (!req.session?.id || !req.session?.roomId) {
      return res.status(400).json({ error: 'Not in a room' });
    }
    
    const success = roomService.leaveRoom(req.session.roomId, req.session.id);
    
    if (success) {
      // Clear room session info
      delete req.session.roomId;
      delete req.session.isHost;
      delete req.session.name;
      
      logger.info('Room left', { 
        roomId: req.session.roomId, 
        sessionId: req.session.id 
      });
      
      res.json({ success: true });
    } else {
      res.status(400).json({ error: 'Failed to leave room' });
    }
    
  } catch (error: any) {
    logger.error('Room leave failed', { error: error.message, sessionId: req.session?.id });
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get room messages (MVP Phase 1 - room-specific)
app.get('/api/room/:roomId/messages', async (req, res) => {
  try {
    const { roomId } = req.params;
    const { offset = 0, limit = 50 } = req.query;
    
    if (!req.session?.id) {
      return res.status(401).json({ error: 'Authentication required' });
    }
    
    // Verify user is in this room
    if (req.session.roomId !== roomId) {
      return res.status(403).json({ error: 'Not a member of this room' });
    }
    
    const messages = roomService.getRoomMessages(roomId, req.session.id);
    
    // Apply pagination
    const start = Math.max(0, parseInt(offset as string));
    const end = start + Math.min(100, parseInt(limit as string));
    const paginatedMessages = messages.slice(start, end);
    
    res.json({
      messages: paginatedMessages,
      total: messages.length,
      offset: start,
      limit: end - start
    });
    
  } catch (error: any) {
    logger.error('Room messages fetch failed', { error: error.message });
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get room participants (MVP Phase 1)
app.get('/api/room/:roomId/participants', async (req, res) => {
  try {
    const { roomId } = req.params;
    
    if (!req.session?.id) {
      return res.status(401).json({ error: 'Authentication required' });
    }
    
    // Verify user is in this room
    if (req.session.roomId !== roomId) {
      return res.status(403).json({ error: 'Not a member of this room' });
    }
    
    const participants = roomService.getRoomParticipants(roomId);
    
    // Return participant info (without sensitive session data)
    const participantList = participants.map(p => ({
      name: p.name,
      isHost: p.isHost,
      joinedAt: p.joinedAt,
      lastActivity: p.lastActivity
    }));
    
    res.json({
      participants: participantList,
      count: participantList.length
    });
    
  } catch (error: any) {
    logger.error('Room participants fetch failed', { error: error.message });
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Host controls: Lock room (MVP Phase 1)
app.post('/api/room/:roomId/lock', doubleCsrfProtection, async (req, res) => {
  try {
    const { roomId } = req.params;
    
    if (!req.session?.id || !req.session?.isHost) {
      return res.status(403).json({ error: 'Only room host can lock room' });
    }
    
    if (req.session.roomId !== roomId) {
      return res.status(400).json({ error: 'Not in this room' });
    }
    
    const success = roomService.lockRoom(roomId, req.session.id);
    
    if (success) {
      logger.info('Room locked', { roomId, hostId: req.session.id });
      res.json({ success: true, message: 'Room locked' });
    } else {
      res.status(400).json({ error: 'Failed to lock room' });
    }
    
  } catch (error: any) {
    logger.error('Room lock failed', { error: error.message });
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Host controls: Kick participant (MVP Phase 1)
app.post('/api/room/:roomId/kick/:targetSessionId', doubleCsrfProtection, async (req, res) => {
  try {
    const { roomId, targetSessionId } = req.params;
    
    if (!req.session?.id || !req.session?.isHost) {
      return res.status(403).json({ error: 'Only room host can kick participants' });
    }
    
    if (req.session.roomId !== roomId) {
      return res.status(400).json({ error: 'Not in this room' });
    }
    
    const success = roomService.kickParticipant(roomId, req.session.id, targetSessionId);
    
    if (success) {
      logger.info('Participant kicked', { 
        roomId, 
        hostId: req.session.id, 
        targetSessionId 
      });
      res.json({ success: true, message: 'Participant removed' });
    } else {
      res.status(400).json({ error: 'Failed to kick participant' });
    }
    
  } catch (error: any) {
    logger.error('Participant kick failed', { error: error.message });
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Room stats for monitoring (MVP Phase 1)
app.get('/api/rooms/stats', async (req, res) => {
  try {
    const stats = roomService.getStats();
    res.json(stats);
  } catch (error: any) {
    logger.error('Room stats fetch failed', { error: error.message });
    res.status(500).json({ error: 'Internal server error' });
  }
});
EOF

echo "📝 Appending room endpoints to server.ts..."

# Append the new endpoints before the WebSocket section
sed -i '/\/\/ WebSocket server/i\
// Import room endpoints\
' backend/src/server.ts

# Read the room endpoints and append them to server.ts (before WebSocket section)
cat /tmp/room-endpoints.ts >> /tmp/server_with_rooms.ts
sed '/\/\/ WebSocket server/r /tmp/room-endpoints.ts' backend/src/server.ts > /tmp/server_updated.ts
mv /tmp/server_updated.ts backend/src/server.ts

# Clean up temp files
rm -f /tmp/room-endpoints.ts /tmp/server_with_rooms.ts

echo "✅ Room API endpoints added to server.ts"

# Update WebSocket to support room-specific messaging
echo "📝 Updating WebSocket for room support..."

# Create WebSocket room patch
cat > /tmp/websocket-room-patch.ts << 'EOF'
  
  // ROOM-SPECIFIC WEBSOCKET HANDLING (MVP Phase 1)
  socket.on('message', async (rawMessage) => {
    try {
      const data = JSON.parse(rawMessage.toString());
      const sessionId = url.parse(socket.url, true).query.sessionId as string;
      
      if (!sessionId) {
        socket.send(JSON.stringify({ 
          type: 'error', 
          error: 'Session ID required' 
        }));
        return;
      }

      if (data.type === 'send_message') {
        const messageText = sanitizeInput(data.text?.substring(0, 500) || '');
        if (!messageText.trim()) return;

        // Get user's current room
        const user = onlineUsers.get(sessionId);
        if (!user) {
          socket.send(JSON.stringify({ 
            type: 'error', 
            error: 'User not found' 
          }));
          return;
        }

        let message;
        
        if (user.roomId) {
          // ROOM-SPECIFIC MESSAGE (MVP Phase 1)
          message = roomService.addMessage(user.roomId, sessionId, messageText);
          
          if (message) {
            // Broadcast to room participants only
            const room = roomService.getRoom(user.roomId);
            if (room) {
              const roomMessage = {
                type: 'message',
                message: message
              };
              
              // Send to all participants in this room
              for (const [participantId] of room.participants) {
                const participantUser = onlineUsers.get(participantId);
                if (participantUser?.socket && participantUser.socket.readyState === WebSocket.OPEN) {
                  participantUser.socket.send(JSON.stringify(roomMessage));
                }
              }
              
              // Update participant activity
              user.lastActivity = Date.now();
            }
          }
        } else {
          // FALLBACK: Global message (backward compatibility)
          message = {
            id: `msg-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
            user: user.name,
            text: messageText,
            timestamp: Date.now()
          };
          
          messages.push(message);
          if (messages.length > 100) {
            messages.splice(0, messages.length - 100);
          }
          
          // Broadcast to all global users
          broadcast({
            type: 'message',
            message: message
          });
        }
      } else if (data.type === 'heartbeat') {
        socket.send(JSON.stringify({ type: 'pong' }));
        
        // Update activity for room users
        const user = onlineUsers.get(sessionId);
        if (user) {
          user.lastActivity = Date.now();
        }
      }
    } catch (error) {
      console.error('WebSocket message error:', error);
      socket.send(JSON.stringify({ 
        type: 'error', 
        error: 'Message processing failed' 
      }));
    }
  });
EOF

echo "✅ WebSocket room support prepared"

echo ""
echo "✅ STEG 2 API INTEGRATION COMPLETED!"
echo "📝 Changes made:"
echo "   - Room service imports added to server.ts"
echo "   - 8 new room API endpoints added"
echo "   - WebSocket room messaging support prepared"
echo ""
echo "🎯 NEW API ENDPOINTS:"
echo "   - POST /api/create-room (MVP room creation)"
echo "   - GET /api/room/:id (room preview)"  
echo "   - POST /api/join-room/:id (join via link)"
echo "   - POST /api/leave-room (leave current room)"
echo "   - GET /api/room/:id/messages (room messages)"
echo "   - GET /api/room/:id/participants (room members)"
echo "   - POST /api/room/:id/lock (host: lock room)"
echo "   - POST /api/room/:id/kick/:sessionId (host: kick user)"
echo "   - GET /api/rooms/stats (monitoring)"
echo ""
echo "⚠️  NEXT: Need to finish WebSocket integration manually"