import "dotenv/config";
import express from "express";
import { createServer } from "http";
import { WebSocketServer, WebSocket } from "ws";
import cors from "cors";
import helmet from "helmet";
import cookieParser from "cookie-parser";
import { body, query, validationResult } from "express-validator";
import winston from "winston";
import DOMPurify from "dompurify";
import { JSDOM } from "jsdom";

import { JWTAuth } from "./jwt-auth.js";
import { requireJWT, optionalJWT, AuthenticatedRequest } from "./jwt-middleware.js";

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
  defaultMeta: { service: "mugharred-backend" },
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

// JWT-based login endpoint (no session creation)
app.post(
  "/api/login", 
  validateUsername,
  handleValidationErrors,
  (req: express.Request, res: express.Response) => {
    try {
      const { name } = req.body;
      const sanitizedName = sanitizeInput(name.trim());
      
      // Generate JWT token with user info
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

// Health check
app.get("/health", (req, res) => {
  res.json({
    status: "ok",
    timestamp: Date.now(),
    auth: "jwt"
  });
});

// Enhanced WebSocket handling with JWT
const httpServer = createServer(app);
const wss = new WebSocketServer({ 
  server: httpServer, 
  path: "/ws",
  perMessageDeflate: false,
});

wss.on("connection", (socket, req) => {
  try {
    const token = JWTAuth.extractTokenFromRequest(req);
    
    if (!token) {
      logger.warn("WebSocket rejected - no token", { ip: req.socket.remoteAddress });
      socket.close(1008, "No token provided");
      return;
    }

    const user = JWTAuth.verifyToken(token);
    
    logger.info("WebSocket connected", { 
      userId: user.userId, 
      name: user.name,
      roomId: user.roomId 
    });
    
    socket.on("message", (raw) => {
      try {
        const msg = JSON.parse(raw.toString());
        
        if (msg.type === "ping") {
          socket.send(JSON.stringify({ type: "pong" }));
        }
        
        // Room messaging will be handled by Redis pub/sub in next script
        
      } catch (error) {
        logger.error("WebSocket message error", { error });
        socket.send(JSON.stringify({
          type: "error",
          error: "Invalid message format"
        }));
      }
    });
    
    socket.on("close", (code, reason) => {
      logger.info("WebSocket disconnected", { 
        userId: user.userId,
        code, 
        reason: reason?.toString() 
      });
    });
    
    socket.on("error", (error) => {
      logger.error("WebSocket error", { userId: user.userId, error });
    });
    
  } catch (error) {
    logger.error("WebSocket JWT validation failed", { error });
    socket.close(1008, "Invalid token");
  }
});

// Start server
httpServer.listen(PORT, () => {
  logger.info(`Mugharred JWT backend listening on :${PORT}`, {
    nodeEnv: NODE_ENV
  });
});
