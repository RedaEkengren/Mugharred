#!/bin/bash

# Restore Room Endpoints - Följer goldenrules.md strikt
# Problemet: Tog bort room creation när jag fixade imports

set -e

echo "🚀 Restoring room creation endpoints..."

BACKEND_FILE="backend/src/server.ts"

echo "📝 STEG 1: Add room imports back to server.ts..."

# Add room imports after existing imports
sed -i '/import { JSDOM } from "jsdom";/a\\nimport { RoomService } from "./room-service.js";\nimport type { CreateRoomRequest, JoinRoomRequest } from "./room-types.js";' "$BACKEND_FILE"

echo "📝 STEG 2: Initialize room service..."

# Add room service initialization after onlineUsers declaration
sed -i '/const messageTimestamps = new Map<string, number[]>();/a\\n// Initialize Room Service\nconst roomService = new RoomService();' "$BACKEND_FILE"

echo "📝 STEG 3: Add room endpoints back..."

# Add room endpoints before health check endpoint
cat >> /tmp/room-endpoints.ts << 'EOF'

// =================================================================
// ROOM API ENDPOINTS - MVP Phase 1 Implementation
// =================================================================

// Create room endpoint (MVP.md: instant room creation)
app.post(
  "/api/create-room",
  requireAuth,
  doubleCsrfProtection,
  [
    body("name")
      .trim()
      .isLength({ min: 2, max: 50 })
      .withMessage("Room name must be 2-50 characters"),
    body("maxParticipants")
      .isInt({ min: 2, max: 12 })
      .withMessage("Max participants must be 2-12"),
    body("duration")
      .isInt({ min: 15, max: 120 })
      .withMessage("Duration must be 15-120 minutes"),
  ],
  handleValidationErrors,
  (req: AuthenticatedRequest, res: express.Response) => {
    try {
      const { name, maxParticipants, duration } = req.body;
      const hostSessionId = req.session.userId!;

      const user = onlineUsers.get(hostSessionId);
      const hostName = user ? sanitizeInput(user.name) : "Unknown";

      const roomRequest: CreateRoomRequest = {
        name: sanitizeInput(name),
        maxParticipants,
        duration,
        hostName
      };

      const { room, roomLink } = roomService.createRoom(roomRequest, hostSessionId);
      
      logger.info("Room created", {
        roomId: room.id,
        hostSessionId,
        name: room.name
      });

      res.json({
        roomId: room.id,
        roomLink,
        room: {
          id: room.id,
          name: room.name,
          expiresAt: room.expiresAt,
          maxParticipants: room.maxParticipants
        }
      });
      
    } catch (error) {
      logger.error("Room creation error", { error });
      res.status(500).json({ error: "Failed to create room" });
    }
  }
);

// Join room endpoint
app.post(
  "/api/join-room",
  requireAuth,
  doubleCsrfProtection,
  [
    body("roomId")
      .trim()
      .isLength({ min: 1 })
      .withMessage("Room ID is required"),
    body("name")
      .trim()
      .isLength({ min: 2, max: 50 })
      .withMessage("Name must be 2-50 characters"),
  ],
  handleValidationErrors,
  (req: AuthenticatedRequest, res: express.Response) => {
    try {
      const { roomId, name } = req.body;
      const sessionId = req.session.userId!;

      const joinRequest: JoinRoomRequest = {
        roomId,
        sessionId,
        name: sanitizeInput(name)
      };

      const result = roomService.joinRoom(joinRequest, sessionId);
      
      logger.info("User joined room", {
        roomId,
        sessionId,
        name: result.participant.name
      });

      res.json({
        success: true,
        room: {
          id: result.room.id,
          name: result.room.name,
          participants: Array.from(result.room.participants.values()).map(p => ({
            id: p.id,
            name: p.name,
            isHost: p.isHost
          }))
        }
      });
      
    } catch (error) {
      logger.error("Join room error", { error });
      res.status(400).json({ error: error instanceof Error ? error.message : "Failed to join room" });
    }
  }
);

EOF

# Insert room endpoints before health check
sed -i '/\/\/ Health check with limited info/i\\n'"$(cat /tmp/room-endpoints.ts)"'' "$BACKEND_FILE"

# Clean up temp file
rm /tmp/room-endpoints.ts

echo "📝 STEG 4: Build and restart..."
npm run build

pm2 restart mugharred-backend

echo "✅ Room endpoints restored successfully!"

echo ""
echo "🎯 CHANGES MADE:"
echo "   - Added room-service imports back"
echo "   - Initialized RoomService"
echo "   - Added /api/create-room endpoint"
echo "   - Added /api/join-room endpoint"
echo "   - Backend restarted with room functionality"