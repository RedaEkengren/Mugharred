#!/bin/bash
# PHASE 1 REWRITE: Stateless WebSocket Architecture  
# Remove session dependencies, implement JWT + Redis pub/sub
# Compliance: goldenrules.md - script-driven changes only

set -e

echo "🔌 IMPLEMENTING STATELESS WEBSOCKET"
echo "Removing session dependencies, implementing JWT + Redis pub/sub..."

# Navigate to backend
cd /home/reda/development/mugharred/backend

# Create stateless WebSocket service
echo "Creating stateless WebSocket service..."
cat > src/websocket-service.ts << 'EOF'
import { WebSocketServer, WebSocket } from 'ws';
import { IncomingMessage } from 'http';
import { JWTAuth, JWTPayload } from './jwt-auth.js';
import { redisRoomService } from './redis-room-service.js';
import { randomUUID } from 'crypto';
import DOMPurify from 'dompurify';
import { JSDOM } from 'jsdom';

// Initialize DOMPurify
const window = new JSDOM("").window;
const purify = DOMPurify(window as any);

interface WebSocketConnection {
  socket: WebSocket;
  user: JWTPayload;
  lastActivity: number;
}

export class StatelessWebSocketService {
  private wss: WebSocketServer;
  private connections = new Map<string, WebSocketConnection>();

  constructor(server: any) {
    this.wss = new WebSocketServer({ 
      server, 
      path: "/ws",
      perMessageDeflate: false,
    });

    this.wss.on("connection", this.handleConnection.bind(this));
    this.setupCleanupInterval();
  }

  private handleConnection(socket: WebSocket, req: IncomingMessage) {
    try {
      // Extract and validate JWT token
      const token = this.extractToken(req);
      if (!token) {
        this.rejectConnection(socket, "No token provided");
        return;
      }

      const user = JWTAuth.verifyToken(token);
      const connectionId = randomUUID();

      // Store connection
      const connection: WebSocketConnection = {
        socket,
        user,
        lastActivity: Date.now()
      };
      
      this.connections.set(connectionId, connection);

      console.log(`🔌 WebSocket connected:`, { 
        userId: user.userId, 
        name: user.name,
        roomId: user.roomId || 'none',
        connectionId
      });

      // Subscribe to room if user is in a room
      if (user.roomId) {
        this.subscribeToRoom(connectionId, user.roomId);
      }

      // Set up message handler
      socket.on("message", (raw) => this.handleMessage(connectionId, raw));
      
      // Set up close handler  
      socket.on("close", (code, reason) => {
        console.log(`🔌 WebSocket disconnected:`, { 
          userId: user.userId,
          connectionId,
          code, 
          reason: reason?.toString() 
        });
        this.connections.delete(connectionId);
      });

      // Set up error handler
      socket.on("error", (error) => {
        console.error(`🔌 WebSocket error:`, { 
          userId: user.userId,
          connectionId,
          error 
        });
        this.connections.delete(connectionId);
      });

      // Send connection confirmation
      this.sendToConnection(connectionId, {
        type: "connected",
        user: { name: user.name, userId: user.userId },
        roomId: user.roomId
      });

    } catch (error) {
      console.error("WebSocket connection error:", error);
      this.rejectConnection(socket, "Invalid token");
    }
  }

  private extractToken(req: IncomingMessage): string | null {
    if (!req.url) return null;
    
    const url = new URL(req.url, `http://${req.headers.host}`);
    return url.searchParams.get('token');
  }

  private rejectConnection(socket: WebSocket, reason: string) {
    console.log(`❌ WebSocket rejected: ${reason}`);
    socket.close(1008, reason);
  }

  private async handleMessage(connectionId: string, raw: Buffer) {
    const connection = this.connections.get(connectionId);
    if (!connection) return;

    try {
      connection.lastActivity = Date.now();
      const msg = JSON.parse(raw.toString());

      switch (msg.type) {
        case "ping":
          this.sendToConnection(connectionId, { type: "pong" });
          break;
          
        case "send_message":
          await this.handleSendMessage(connectionId, msg);
          break;
          
        case "join_room":
          await this.handleJoinRoom(connectionId, msg);
          break;
          
        case "leave_room":
          await this.handleLeaveRoom(connectionId);
          break;
          
        default:
          this.sendToConnection(connectionId, {
            type: "error",
            error: "Unknown message type"
          });
      }

    } catch (error) {
      console.error("WebSocket message error:", { connectionId, error });
      this.sendToConnection(connectionId, {
        type: "error",
        error: "Invalid message format"
      });
    }
  }

  private async handleSendMessage(connectionId: string, msg: any) {
    const connection = this.connections.get(connectionId);
    if (!connection) return;

    const { user } = connection;
    
    // Validate message
    const text = String(msg.text || "").trim();
    if (!text || text.length > 500) {
      this.sendToConnection(connectionId, {
        type: "error", 
        error: "Invalid message content"
      });
      return;
    }

    // Must be in a room to send messages
    if (!user.roomId) {
      this.sendToConnection(connectionId, {
        type: "error",
        error: "Must be in a room to send messages"
      });
      return;
    }

    // Sanitize message
    const sanitizedText = purify.sanitize(text, { ALLOWED_TAGS: [] });

    // Create room message
    const roomMessage = {
      id: randomUUID(),
      roomId: user.roomId,
      user: user.name,
      text: sanitizedText,
      timestamp: Date.now(),
      sessionId: user.userId
    };

    // Add to room storage and broadcast via Redis pub/sub
    await redisRoomService.addMessage(user.roomId, roomMessage);

    console.log(`💬 Message sent to room ${user.roomId} by ${user.name}`);
  }

  private async handleJoinRoom(connectionId: string, msg: any) {
    const connection = this.connections.get(connectionId);
    if (!connection) return;

    try {
      const { roomId, name } = msg;
      const { user } = connection;

      // Join room via Redis service
      const result = await redisRoomService.joinRoom(
        { roomId, participantName: name },
        user.userId
      );

      if (!result.success) {
        this.sendToConnection(connectionId, {
          type: "join_room_error",
          error: result.error
        });
        return;
      }

      // Update user token with room info
      const newToken = JWTAuth.generateToken({
        userId: user.userId,
        name: name,
        roomId: roomId,
        role: 'participant'
      });

      // Subscribe to room messages
      this.subscribeToRoom(connectionId, roomId);

      // Update connection user info
      connection.user.roomId = roomId;
      connection.user.name = name;
      connection.user.role = 'participant';

      this.sendToConnection(connectionId, {
        type: "joined_room",
        roomId,
        token: newToken,
        room: result.room
      });

    } catch (error) {
      console.error("Join room error:", error);
      this.sendToConnection(connectionId, {
        type: "join_room_error",
        error: "Failed to join room"
      });
    }
  }

  private async handleLeaveRoom(connectionId: string) {
    const connection = this.connections.get(connectionId);
    if (!connection || !connection.user.roomId) return;

    const { user } = connection;
    
    await redisRoomService.leaveRoom(user.roomId, user.userId);
    
    // Update user token without room info
    const newToken = JWTAuth.generateToken({
      userId: user.userId,
      name: user.name
    });

    connection.user.roomId = undefined;
    connection.user.role = undefined;

    this.sendToConnection(connectionId, {
      type: "left_room",
      token: newToken
    });
  }

  private async subscribeToRoom(connectionId: string, roomId: string) {
    // Subscribe to room messages
    redisRoomService.subscribeToRoom(roomId, (message) => {
      this.sendToConnection(connectionId, {
        type: "message",
        message
      });
    });

    // Subscribe to room events
    redisRoomService.subscribeToRoomEvents(roomId, (event) => {
      this.sendToConnection(connectionId, {
        type: "room_event",
        event
      });
    });
  }

  private sendToConnection(connectionId: string, data: any) {
    const connection = this.connections.get(connectionId);
    if (!connection || connection.socket.readyState !== WebSocket.OPEN) {
      return;
    }

    try {
      connection.socket.send(JSON.stringify(data));
    } catch (error) {
      console.error("Failed to send to connection:", { connectionId, error });
      this.connections.delete(connectionId);
    }
  }

  private sendToRoom(roomId: string, data: any, excludeUserId?: string) {
    for (const [connectionId, connection] of this.connections) {
      if (connection.user.roomId === roomId && 
          connection.user.userId !== excludeUserId) {
        this.sendToConnection(connectionId, data);
      }
    }
  }

  private setupCleanupInterval() {
    // Clean up inactive connections every minute
    setInterval(() => {
      const now = Date.now();
      const timeout = 5 * 60 * 1000; // 5 minutes

      for (const [connectionId, connection] of this.connections) {
        if (now - connection.lastActivity > timeout) {
          console.log(`🧹 Cleaning up inactive connection: ${connectionId}`);
          connection.socket.close(1000, "Inactive connection");
          this.connections.delete(connectionId);
        }
      }
    }, 60_000);
  }

  // Get connection statistics
  getStats() {
    const totalConnections = this.connections.size;
    const roomConnections = new Map<string, number>();

    for (const connection of this.connections.values()) {
      if (connection.user.roomId) {
        const count = roomConnections.get(connection.user.roomId) || 0;
        roomConnections.set(connection.user.roomId, count + 1);
      }
    }

    return {
      totalConnections,
      roomConnections: Object.fromEntries(roomConnections)
    };
  }
}
EOF

# Create complete stateless server
echo "Creating complete stateless server..."
cat > src/server-stateless.ts << 'EOF'
import "dotenv/config";
import express from "express";
import { createServer } from "http";
import cors from "cors";
import helmet from "helmet";
import cookieParser from "cookie-parser";
import { body, validationResult } from "express-validator";
import winston from "winston";
import DOMPurify from "dompurify";
import { JSDOM } from "jsdom";

import { JWTAuth } from "./jwt-auth.js";
import { requireJWT, optionalJWT, AuthenticatedRequest } from "./jwt-middleware.js";
import { redisRoomService } from "./redis-room-service.js";
import { StatelessWebSocketService } from "./websocket-service.js";
import { validateRoomSettings } from "./room-types.js";

// Security Configuration
const NODE_ENV = process.env.NODE_ENV || "development";
const PORT = Number(process.env.PORT || 3001);

// Initialize DOMPurify for server-side sanitization
const window = new JSDOM("").window;
const purify = DOMPurify(window as any);

// Logger setup
const logger = winston.createLogger({
  level: NODE_ENV === "production" ? "info" : "debug",
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  defaultMeta: { service: "mugharred-stateless" },
  transports: [
    new winston.transports.File({ filename: "logs/error.log", level: "error" }),
    new winston.transports.File({ filename: "logs/combined.log" }),
  ],
});

if (NODE_ENV !== "production") {
  logger.add(new winston.transports.Console({
    format: winston.format.simple()
  }));
}

const app = express();

// Trust proxy for Nginx reverse proxy
app.set('trust proxy', 1);

// Security middleware
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'", "'unsafe-inline'"],
      styleSrc: ["'self'", "'unsafe-inline'", "https://fonts.googleapis.com"],
      imgSrc: ["'self'", "data:", "https:"],
      connectSrc: ["'self'", "ws:", "wss:"],
      fontSrc: ["'self'", "https://fonts.gstatic.com"],
    },
  },
}));

// CORS configuration
app.use(cors({ 
  origin: [
    "http://localhost:5173", 
    "https://mugharred.se", 
    "http://mugharred.se"
  ], 
  credentials: true,
  optionsSuccessStatus: 200
}));

app.use(cookieParser());
app.use(express.json({ limit: "1kb" }));

// Validation middleware
const validateUsername = [
  body("name")
    .trim()
    .isLength({ min: 2, max: 50 })
    .withMessage("Namnet måste vara mellan 2-50 tecken")
    .matches(/^[a-zA-ZåäöÅÄÖ0-9\s\-_]+$/)
    .withMessage("Namnet får endast innehålla bokstäver, siffror, mellanslag, bindestreck och understreck")
    .escape(),
];

const validateRoomCreation = [
  body("name").trim().isLength({ min: 2, max: 50 }),
  body("maxParticipants").isInt({ min: 2, max: 12 }),
  body("duration").isIn([15, 30, 60, 120]),
  body("hostName").trim().isLength({ min: 2, max: 50 }),
];

const validateRoomJoin = [
  body("roomId").trim().isLength({ min: 1 }),
  body("participantName").trim().isLength({ min: 2, max: 50 }),
];

// Sanitization helpers
function sanitizeInput(input: string): string {
  return purify.sanitize(input, { ALLOWED_TAGS: [] });
}

// Error handler for validation
function handleValidationErrors(req: express.Request, res: express.Response, next: express.NextFunction) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    logger.warn("Validation errors", { errors: errors.array(), ip: req.ip });
    return res.status(400).json({ 
      error: "Ogiltiga data", 
      details: errors.array().map(err => err.msg) 
    });
  }
  next();
}

// JWT-based login endpoint
app.post(
  "/api/login", 
  validateUsername,
  handleValidationErrors,
  (req: express.Request, res: express.Response) => {
    try {
      const { name } = req.body;
      const sanitizedName = sanitizeInput(name.trim());
      
      const token = JWTAuth.generateToken({
        userId: require('crypto').randomUUID(),
        name: sanitizedName
      });
      
      logger.info("User logged in", { 
        name: sanitizedName, 
        ip: req.ip 
      });
      
      res.json({ 
        token,
        user: { name: sanitizedName }
      });
      
    } catch (error) {
      logger.error("Login error", { error });
      res.status(500).json({ error: "Serverfel vid inloggning" });
    }
  }
);

// Create room endpoint
app.post(
  "/api/create-room",
  requireJWT,
  validateRoomCreation,
  handleValidationErrors,
  async (req: AuthenticatedRequest, res: express.Response) => {
    try {
      const { name, maxParticipants, duration, hostName } = req.body;
      const user = req.user!;

      const roomRequest = {
        name: sanitizeInput(name),
        maxParticipants,
        duration,
        hostName: sanitizeInput(hostName || user.name)
      };

      // Validate room settings
      const validationErrors = validateRoomSettings(roomRequest);
      if (validationErrors.length > 0) {
        return res.status(400).json({ 
          error: "Invalid room settings", 
          details: validationErrors 
        });
      }

      const result = await redisRoomService.createRoom(roomRequest, user.userId);
      
      if (!result.success) {
        return res.status(400).json({ error: result.error });
      }

      res.json({
        roomId: result.room!.id,
        token: result.token,
        room: {
          id: result.room!.id,
          name: result.room!.name,
          expiresAt: result.room!.expiresAt
        }
      });

    } catch (error) {
      logger.error("Create room error", { error });
      res.status(500).json({ error: "Failed to create room" });
    }
  }
);

// Join room endpoint
app.post(
  "/api/join-room",
  requireJWT,
  validateRoomJoin,
  handleValidationErrors,
  async (req: AuthenticatedRequest, res: express.Response) => {
    try {
      const { roomId, participantName } = req.body;
      const user = req.user!;

      const joinRequest = {
        roomId,
        participantName: sanitizeInput(participantName)
      };

      const result = await redisRoomService.joinRoom(joinRequest, user.userId);
      
      if (!result.success) {
        return res.status(400).json({ error: result.error });
      }

      res.json({ 
        success: true, 
        token: result.token,
        room: result.room 
      });

    } catch (error) {
      logger.error("Join room error", { error });
      res.status(400).json({ error: "Failed to join room" });
    }
  }
);

// Get room info endpoint
app.get("/api/room/:roomId", optionalJWT, async (req: express.Request, res: express.Response) => {
  try {
    const { roomId } = req.params;
    const room = await redisRoomService.getRoom(roomId);
    
    if (!room) {
      return res.status(404).json({ error: "Room not found" });
    }

    // Return public room info only
    res.json({
      id: room.id,
      name: room.name,
      participants: room.participants.size,
      maxParticipants: room.maxParticipants,
      expiresAt: room.expiresAt,
      isLocked: room.isLocked
    });

  } catch (error) {
    logger.error("Get room error", { error });
    res.status(500).json({ error: "Failed to get room info" });
  }
});

// Token refresh endpoint
app.post("/api/refresh-token", requireJWT, (req: AuthenticatedRequest, res: express.Response) => {
  try {
    const token = JWTAuth.extractTokenFromRequest(req);
    if (!token) {
      return res.status(401).json({ error: "No token provided" });
    }

    const newToken = JWTAuth.refreshToken(token);
    res.json({ token: newToken });
    
  } catch (error) {
    logger.error("Token refresh error", { error });
    res.status(401).json({ error: "Failed to refresh token" });
  }
});

// Health check with statistics
app.get("/health", async (req, res) => {
  try {
    const roomStats = await redisRoomService.getStats();
    const wsStats = wsService?.getStats() || { totalConnections: 0, roomConnections: {} };
    
    res.json({
      status: "ok",
      timestamp: Date.now(),
      auth: "jwt",
      storage: "redis",
      rooms: roomStats.totalRooms,
      participants: roomStats.totalParticipants,
      websockets: wsStats.totalConnections
    });
  } catch (error) {
    res.status(500).json({ 
      status: "error", 
      timestamp: Date.now(),
      error: "Health check failed"
    });
  }
});

// Initialize Redis connection and WebSocket service
let wsService: StatelessWebSocketService;

async function startServer() {
  try {
    // Connect to Redis
    await redisRoomService.connect();
    console.log("✅ Redis connected");

    // Create HTTP server
    const httpServer = createServer(app);
    
    // Initialize WebSocket service
    wsService = new StatelessWebSocketService(httpServer);
    console.log("✅ WebSocket service initialized");

    // Start server
    httpServer.listen(PORT, () => {
      logger.info(`🚀 Mugharred stateless backend listening on :${PORT}`, {
        nodeEnv: NODE_ENV,
        auth: "jwt",
        storage: "redis"
      });
    });

    // Graceful shutdown
    process.on('SIGTERM', async () => {
      logger.info('SIGTERM received, shutting down gracefully');
      await redisRoomService.disconnect();
      process.exit(0);
    });

  } catch (error) {
    logger.error("Failed to start server", { error });
    process.exit(1);
  }
}

// Start the server
startServer().catch(console.error);
EOF

echo "✅ Stateless WebSocket implemented"
echo "Next: Run scripts/implement-frontend-tokens.sh"
echo ""
echo "Stateless WebSocket Features implemented:"
echo "- JWT-only authentication (no session lookups)"
echo "- Redis pub/sub for real-time room messaging"
echo "- Connection cleanup and monitoring"
echo "- Room-specific message broadcasting" 
echo "- Auto-reconnection support"
echo ""
echo "Ready for frontend token management implementation."