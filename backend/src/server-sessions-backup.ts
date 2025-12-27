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
