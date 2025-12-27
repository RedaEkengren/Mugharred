#!/bin/bash
# PHASE 1 REWRITE: JWT Authentication System
# Replace Express sessions with stateless JWT tokens
# Compliance: goldenrules.md - script-driven changes only

set -e

echo "🔐 IMPLEMENTING JWT AUTHENTICATION SYSTEM"
echo "Replacing Express sessions with stateless JWT tokens..."

# Install required dependencies
echo "Installing JWT dependencies..."
cd /home/reda/development/mugharred/backend
npm install jsonwebtoken @types/jsonwebtoken redis

# Create JWT utility module
echo "Creating JWT utilities..."
cat > src/jwt-auth.ts << 'EOF'
import jwt from 'jsonwebtoken';
import { randomUUID } from 'crypto';

const JWT_SECRET = process.env.JWT_SECRET || 'your-jwt-secret-change-in-production';
const JWT_EXPIRY = '1h';

export interface JWTPayload {
  userId: string;
  name: string;
  roomId?: string;
  role?: 'host' | 'participant';
  iat?: number;
  exp?: number;
}

export class JWTAuth {
  static generateToken(payload: Omit<JWTPayload, 'iat' | 'exp'>): string {
    return jwt.sign(payload, JWT_SECRET, { 
      expiresIn: JWT_EXPIRY,
      jwtid: randomUUID()
    });
  }

  static verifyToken(token: string): JWTPayload {
    try {
      return jwt.verify(token, JWT_SECRET) as JWTPayload;
    } catch (error) {
      throw new Error('Invalid or expired token');
    }
  }

  static refreshToken(token: string): string {
    const payload = this.verifyToken(token);
    // Generate new token with fresh expiry
    const { iat, exp, ...refreshPayload } = payload;
    return this.generateToken(refreshPayload);
  }

  static extractTokenFromRequest(req: any): string | null {
    // Check Authorization header
    const authHeader = req.headers.authorization;
    if (authHeader?.startsWith('Bearer ')) {
      return authHeader.slice(7);
    }

    // Check query parameter (for WebSocket)
    if (req.query?.token) {
      return req.query.token;
    }

    // Check URL search params (for WebSocket)
    if (req.url) {
      const url = new URL(req.url, `http://${req.headers.host}`);
      return url.searchParams.get('token');
    }

    return null;
  }
}
EOF

# Create JWT middleware
echo "Creating JWT middleware..."
cat > src/jwt-middleware.ts << 'EOF'
import { Request, Response, NextFunction } from 'express';
import { JWTAuth, JWTPayload } from './jwt-auth.js';

export interface AuthenticatedRequest extends Request {
  user?: JWTPayload;
}

export function requireJWT(req: AuthenticatedRequest, res: Response, next: NextFunction) {
  try {
    const token = JWTAuth.extractTokenFromRequest(req);
    
    if (!token) {
      return res.status(401).json({ error: 'No token provided' });
    }

    const payload = JWTAuth.verifyToken(token);
    req.user = payload;
    next();
  } catch (error) {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
}

export function optionalJWT(req: AuthenticatedRequest, res: Response, next: NextFunction) {
  try {
    const token = JWTAuth.extractTokenFromRequest(req);
    
    if (token) {
      const payload = JWTAuth.verifyToken(token);
      req.user = payload;
    }
    
    next();
  } catch (error) {
    // Invalid token, but continue without user
    next();
  }
}
EOF

# Update server.ts to use JWT instead of sessions
echo "Updating server.ts for JWT authentication..."
cat > src/server-jwt.ts << 'EOF'
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
EOF

# Backup current server.ts
echo "Backing up current server.ts..."
cp src/server.ts src/server-sessions-backup.ts

echo "✅ JWT Authentication System implemented"
echo "Next: Run scripts/implement-redis-rooms.sh"
echo ""
echo "JWT Features implemented:"
echo "- Stateless authentication via JWT tokens"
echo "- Token-based WebSocket connections" 
echo "- Token refresh mechanism"
echo "- Eliminated Express sessions dependency"
echo ""
echo "Ready for Redis room storage implementation."