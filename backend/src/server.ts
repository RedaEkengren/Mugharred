import "dotenv/config";
import express from "express";
import { createServer } from "http";
import { WebSocketServer, WebSocket } from "ws";
import { randomUUID } from "crypto";
import cors from "cors";
import helmet from "helmet";
import session from "express-session";
import RedisStore from "connect-redis";
type RedisStoreType = new (options: any) => any;
import { createClient } from "redis";
import rateLimit from "express-rate-limit";
import { body, param, query, validationResult } from "express-validator";
import winston from "winston";
import cookieParser from "cookie-parser";
import { doubleCsrf } from "csrf-csrf";
import bcrypt from "bcrypt";
import jwt from "jsonwebtoken";
import DOMPurify from "dompurify";
import { JSDOM } from "jsdom";

// Security Configuration
const JWT_SECRET = process.env.JWT_SECRET || "your-super-secret-jwt-key-change-this";
const SESSION_SECRET = process.env.SESSION_SECRET || "your-super-secret-session-key-change-this";
const REDIS_URL = process.env.REDIS_URL || "redis://localhost:6379";
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

// Redis client setup
const redisClient = createClient({
  url: REDIS_URL,
});

redisClient.on('error', (err) => {
  logger.error("Redis Client Error", err);
});

await redisClient.connect();

const app = express();

// Trust proxy for rate limiting (behind Nginx)
// Only trust specific proxy (localhost)
app.set('trust proxy', '127.0.0.1');

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

// Rate limiting - IP based (uses global trust proxy setting)
const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limit each IP to 100 requests per windowMs
  message: "För många förfrågningar, försök igen senare.",
  standardHeaders: true,
  legacyHeaders: false,
});

const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5, // Limit login attempts
  message: "För många inloggningsförsök, försök igen senare.",
  skipSuccessfulRequests: true,
});

app.use("/api", apiLimiter);
app.use("/api/login", authLimiter);

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
app.use(express.json({ limit: "1kb" })); // Limit JSON payload size

// Session configuration with Redis
app.use(session({
  store: new (RedisStore as any)({ client: redisClient }),
  secret: SESSION_SECRET,
  resave: false,
  saveUninitialized: false,
  name: "mugharred.sid",
  cookie: {
    secure: NODE_ENV === "production", // HTTPS only in production
    httpOnly: true, // Prevent XSS
    maxAge: 1000 * 60 * 30, // 30 minutes
    sameSite: "strict", // CSRF protection
  },
}));

// CSRF Protection
const {
  invalidCsrfTokenError,
  generateCsrfToken,
  doubleCsrfProtection,
} = doubleCsrf({
  getSecret: () => SESSION_SECRET,
  getSessionIdentifier: (req) => req.session?.id || '',
  cookieName: "x-csrf-token",
  cookieOptions: {
    httpOnly: true,
    sameSite: "strict",
    secure: NODE_ENV === "production",
  },
  size: 64,
  ignoredMethods: ["GET", "HEAD", "OPTIONS"],
});

// CSRF token generation middleware
app.use((req: any, res, next) => {
  req.csrfToken = (options?: any) => generateCsrfToken(req, res, options);
  next();
});

// Types
type Message = {
  id: string;
  user: string;
  text: string;
  timestamp: number;
  sanitized: boolean;
};

type OnlineUser = {
  name: string;
  socket?: WebSocket;
  lastActivity: number;
  sessionId: string;
  isAuthenticated: boolean;
};

type AuthenticatedRequest = express.Request & {
  session: session.Session & {
    userId?: string;
    userName?: string;
    isAuthenticated?: boolean;
  };
  csrfToken?: () => string;
};

// Data stores (will be moved to Redis in production)
const messages: Message[] = [];
const onlineUsers = new Map<string, OnlineUser>();
const messageTimestamps = new Map<string, number[]>();

// Constants
const MAX_ONLINE_USERS = 5;
const MAX_MSG_PER_WINDOW = 5;
const WINDOW_MS = 10_000;
const INACTIVITY_TIMEOUT = 5 * 60 * 1000; // 5 minutes
const MAX_MESSAGE_LENGTH = 500;
const MAX_USERNAME_LENGTH = 50;
const MIN_USERNAME_LENGTH = 2;

// Validation middleware
const validateUsername = [
  body("name")
    .trim()
    .isLength({ min: MIN_USERNAME_LENGTH, max: MAX_USERNAME_LENGTH })
    .withMessage(`Namnet måste vara mellan ${MIN_USERNAME_LENGTH}-${MAX_USERNAME_LENGTH} tecken`)
    .matches(/^[a-zA-ZåäöÅÄÖ0-9\s\-_]+$/)
    .withMessage("Namnet får endast innehålla bokstäver, siffror, mellanslag, bindestreck och understreck")
    .escape(),
];

const validateMessage = [
  body("text")
    .trim()
    .isLength({ min: 1, max: MAX_MESSAGE_LENGTH })
    .withMessage(`Meddelandet måste vara mellan 1-${MAX_MESSAGE_LENGTH} tecken`)
    .escape(),
];

const validatePagination = [
  query("offset")
    .optional()
    .isInt({ min: 0 })
    .withMessage("Offset måste vara ett positivt nummer"),
  query("limit")
    .optional()
    .isInt({ min: 1, max: 50 })
    .withMessage("Limit måste vara mellan 1-50"),
];

// Sanitization helpers
function sanitizeInput(input: string): string {
  return purify.sanitize(input, { ALLOWED_TAGS: [] });
}

// Authentication middleware
function requireAuth(req: AuthenticatedRequest, res: express.Response, next: express.NextFunction) {
  if (!req.session.isAuthenticated || !req.session.userId) {
    logger.warn("Unauthorized access attempt", { 
      ip: req.ip,
      userAgent: req.get("User-Agent"),
      url: req.url 
    });
    return res.status(401).json({ error: "Inte inloggad" });
  }
  next();
}

// Rate limiting helper
function canSendMessage(sessionId: string): boolean {
  const now = Date.now();
  const arr = messageTimestamps.get(sessionId) || [];
  const recent = arr.filter((t) => now - t < WINDOW_MS);
  
  if (recent.length >= MAX_MSG_PER_WINDOW) {
    messageTimestamps.set(sessionId, recent);
    return false;
  }
  
  recent.push(now);
  messageTimestamps.set(sessionId, recent);
  return true;
}

// Broadcast helper with error handling
function broadcast(payload: any) {
  const data = JSON.stringify(payload);
  const deadConnections: string[] = [];
  
  for (const [sessionId, user] of onlineUsers.entries()) {
    if (user.socket && user.socket.readyState === WebSocket.OPEN) {
      try {
        user.socket.send(data);
      } catch (error) {
        logger.error("Broadcast error", { sessionId, error });
        deadConnections.push(sessionId);
      }
    } else {
      deadConnections.push(sessionId);
    }
  }
  
  // Clean up dead connections
  deadConnections.forEach(sessionId => {
    onlineUsers.delete(sessionId);
    messageTimestamps.delete(sessionId);
  });
}

function broadcastOnlineUsers() {
  const users = Array.from(onlineUsers.values())
    .filter(u => u.isAuthenticated)
    .map(u => sanitizeInput(u.name));
  broadcast({ type: "online_users", users });
}

// Clean up inactive users
function cleanupInactiveUsers() {
  const now = Date.now();
  const toRemove: string[] = [];
  
  for (const [sessionId, user] of onlineUsers.entries()) {
    if (now - user.lastActivity > INACTIVITY_TIMEOUT) {
      logger.info("Cleaning up inactive user", { sessionId, userName: user.name });
      
      if (user.socket && user.socket.readyState === WebSocket.OPEN) {
        try {
          user.socket.send(JSON.stringify({
            type: "error",
            error: "Du har blivit utloggad på grund av inaktivitet."
          }));
          user.socket.close();
        } catch (error) {
          logger.error("Error closing inactive user socket", { error });
        }
      }
      toRemove.push(sessionId);
    }
  }
  
  // Remove inactive users
  for (const sessionId of toRemove) {
    onlineUsers.delete(sessionId);
    messageTimestamps.delete(sessionId);
  }
  
  if (toRemove.length > 0) {
    broadcastOnlineUsers();
  }
}

// Run cleanup every minute
setInterval(cleanupInactiveUsers, 60_000);

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

// Security logging middleware
app.use((req, res, next) => {
  logger.debug("Request received", {
    method: req.method,
    url: req.url,
    ip: req.ip,
    userAgent: req.get("User-Agent"),
    timestamp: new Date().toISOString()
  });
  next();
});

// CSRF token endpoint
app.get("/api/csrf-token", (req: AuthenticatedRequest, res) => {
  logger.debug("CSRF token requested", { session: req.session.id });
  const token = generateCsrfToken(req, res);
  res.json({ csrfToken: token });
});

// Secure LOGIN endpoint
app.post(
  "/api/login", 
  validateUsername,
  handleValidationErrors,
  doubleCsrfProtection,
  (req: AuthenticatedRequest, res: express.Response) => {
    try {
      const { name } = req.body;
      const sanitizedName = sanitizeInput(name.trim());
      
      if (onlineUsers.size >= MAX_ONLINE_USERS) {
        logger.warn("Login rejected - server full", { 
          name: sanitizedName, 
          ip: req.ip,
          currentUsers: onlineUsers.size 
        });
        return res.status(429).json({ 
          error: "För många användare online, försök igen senare." 
        });
      }
      
      // Check for duplicate names (case insensitive)
      const existingUser = Array.from(onlineUsers.values())
        .find(user => user.name.toLowerCase() === sanitizedName.toLowerCase());
      
      if (existingUser) {
        return res.status(409).json({ 
          error: "Namnet är redan taget, välj ett annat." 
        });
      }
      
      const sessionId = randomUUID();
      
      // Set secure session
      req.session.userId = sessionId;
      req.session.userName = sanitizedName;
      req.session.isAuthenticated = true;
      
      onlineUsers.set(sessionId, { 
        name: sanitizedName,
        lastActivity: Date.now(),
        sessionId,
        isAuthenticated: true
      });
      
      logger.info("User logged in", { 
        sessionId, 
        name: sanitizedName, 
        ip: req.ip 
      });
      
      broadcastOnlineUsers();
      
      const csrfToken = generateCsrfToken(req, res);
      res.json({ 
        sessionId, 
        name: sanitizedName,
        csrfToken
      });
      
    } catch (error) {
      logger.error("Login error", { error });
      res.status(500).json({ error: "Serverfel vid inloggning" });
    }
  }
);

// Secure logout endpoint
app.post(
  "/api/logout",
  requireAuth,
  doubleCsrfProtection,
  (req: AuthenticatedRequest, res: express.Response) => {
    try {
      const sessionId = req.session.userId!;
      const user = onlineUsers.get(sessionId);
      
      if (user) {
        if (user.socket && user.socket.readyState === WebSocket.OPEN) {
          user.socket.close();
        }
        onlineUsers.delete(sessionId);
        messageTimestamps.delete(sessionId);
      }
      
      req.session.destroy((err: any) => {
        if (err) {
          logger.error("Session destroy error", { error: err });
        }
      });
      
      logger.info("User logged out", { sessionId });
      broadcastOnlineUsers();
      
      res.json({ success: true });
      
    } catch (error) {
      logger.error("Logout error", { error });
      res.status(500).json({ error: "Serverfel vid utloggning" });
    }
  }
);

// Secure messages endpoint with pagination
app.get(
  "/api/messages", 
  requireAuth,
  validatePagination,
  handleValidationErrors,
  (req: AuthenticatedRequest, res: express.Response) => {
    try {
      const offset = parseInt((req.query.offset as string) ?? "0", 10);
      const limit = Math.min(parseInt((req.query.limit as string) ?? "10", 10), 50);
      
      const user = onlineUsers.get(req.session.userId!);
      if (user) {
        user.lastActivity = Date.now();
      }
      
      const total = messages.length;
      const slice = messages
        .slice()
        .reverse() // newest first
        .slice(offset, offset + limit);
      
      res.json({ total, items: slice });
      
    } catch (error) {
      logger.error("Messages fetch error", { error });
      res.status(500).json({ error: "Serverfel vid hämtning av meddelanden" });
    }
  }
);

// Secure online users endpoint
app.get("/api/online-users", requireAuth, (req: AuthenticatedRequest, res: express.Response) => {
  try {
    const user = onlineUsers.get(req.session.userId!);
    if (user) {
      user.lastActivity = Date.now();
    }
    
    const users = Array.from(onlineUsers.values())
      .filter(u => u.isAuthenticated)
      .map(u => sanitizeInput(u.name));
    
    res.json({ users });
    
  } catch (error) {
    logger.error("Online users fetch error", { error });
    res.status(500).json({ error: "Serverfel vid hämtning av användare" });
  }
});

// Health check with limited info
app.get("/health", (req, res) => {
  const healthData = {
    status: "ok",
    timestamp: Date.now(),
    // Remove sensitive information in production
    ...(NODE_ENV !== "production" && {
      online: onlineUsers.size,
      messages: messages.length
    })
  };
  
  res.json(healthData);
});

// Enhanced WebSocket handling
const httpServer = createServer(app);
const wss = new WebSocketServer({ 
  server: httpServer, 
  path: "/ws",
  perMessageDeflate: false, // Disable compression for security
});

wss.on("connection", (socket, req) => {
  try {
    const url = new URL(req.url || "", `http://${req.headers.host}`);
    const sessionId = url.searchParams.get("sessionId");
    const authToken = url.searchParams.get("token");
    
    logger.debug("WebSocket connection attempt", { 
      sessionId, 
      ip: req.socket.remoteAddress,
      userAgent: req.headers["user-agent"]
    });
    
    // Enhanced session validation
    if (!sessionId || !onlineUsers.has(sessionId)) {
      logger.warn("WebSocket rejected - invalid session", { sessionId, ip: req.socket.remoteAddress });
      socket.close(1008, "Ogiltig session");
      return;
    }
    
    const user = onlineUsers.get(sessionId)!;
    
    // Verify user is authenticated
    if (!user.isAuthenticated) {
      logger.warn("WebSocket rejected - not authenticated", { sessionId });
      socket.close(1008, "Inte autentiserad");
      return;
    }
    
    // Check for connection timeout (prevent replay attacks)
    const connectionAge = Date.now() - user.lastActivity;
    if (connectionAge > INACTIVITY_TIMEOUT) {
      logger.warn("WebSocket rejected - session timeout", { sessionId, connectionAge });
      socket.close(1008, "Session timeout");
      onlineUsers.delete(sessionId);
      return;
    }
    
    user.socket = socket;
    user.lastActivity = Date.now();
    broadcastOnlineUsers();
    
    logger.info("WebSocket connected", { sessionId, userName: user.name });
    
    socket.on("message", (raw) => {
      try {
        // Rate limit check
        if (!canSendMessage(sessionId)) {
          socket.send(JSON.stringify({
            type: "error",
            error: "Rate limit överskriden. Sakta ner lite."
          }));
          return;
        }
        
        const msg = JSON.parse(raw.toString());
        
        if (msg.type === "send_message") {
          user.lastActivity = Date.now();
          
          const text = String(msg.text || "").trim();
          if (!text || text.length > MAX_MESSAGE_LENGTH) {
            socket.send(JSON.stringify({
              type: "error",
              error: "Ogiltigt meddelande"
            }));
            return;
          }
          
          // Sanitize message content
          const sanitizedText = sanitizeInput(text);
          
          const message: Message = {
            id: randomUUID(),
            user: user.name,
            text: sanitizedText,
            timestamp: Date.now(),
            sanitized: true
          };
          
          messages.push(message);
          
          // Limit message history to prevent memory issues
          if (messages.length > 10000) {
            messages.splice(0, 1000); // Remove oldest 1000 messages
          }
          
          broadcast({ type: "message", message });
          
          logger.info("Message sent", { 
            sessionId, 
            userName: user.name, 
            messageLength: sanitizedText.length 
          });
        }
        else if (msg.type === "heartbeat") {
          user.lastActivity = Date.now();
          socket.send(JSON.stringify({ type: "pong" }));
        }
        
      } catch (error) {
        logger.error("WebSocket message error", { sessionId, error });
        socket.send(JSON.stringify({
          type: "error",
          error: "Ogiltigt meddelande format"
        }));
      }
    });
    
    socket.on("close", (code, reason) => {
      logger.info("WebSocket disconnected", { 
        sessionId, 
        code, 
        reason: reason?.toString() 
      });
      onlineUsers.delete(sessionId);
      messageTimestamps.delete(sessionId);
      broadcastOnlineUsers();
    });
    
    socket.on("error", (error) => {
      logger.error("WebSocket error", { sessionId, error });
      onlineUsers.delete(sessionId);
      messageTimestamps.delete(sessionId);
      broadcastOnlineUsers();
    });
    
  } catch (error) {
    logger.error("WebSocket connection error", { error });
    socket.close(1011, "Serverfel");
  }
});

// Global error handler
app.use((err: any, req: express.Request, res: express.Response, next: express.NextFunction) => {
  if (err === invalidCsrfTokenError) {
    logger.warn("CSRF token validation failed", { 
      ip: req.ip, 
      url: req.url,
      userAgent: req.get("User-Agent")
    });
    return res.status(403).json({ error: "Ogiltig CSRF token" });
  }
  
  logger.error("Unhandled error", { 
    error: err, 
    url: req.url, 
    method: req.method,
    ip: req.ip 
  });
  
  res.status(500).json({ error: "Internt serverfel" });
});

// Graceful shutdown
process.on('SIGTERM', async () => {
  logger.info('SIGTERM received, shutting down gracefully');
  
  // Close all WebSocket connections
  for (const [sessionId, user] of onlineUsers.entries()) {
    if (user.socket && user.socket.readyState === WebSocket.OPEN) {
      user.socket.close(1001, "Server shutdown");
    }
  }
  
  // Close Redis connection
  await redisClient.quit();
  
  // Close HTTP server
  httpServer.close(() => {
    logger.info('Process terminated');
    process.exit(0);
  });
});

// Start server
httpServer.listen(PORT, () => {
  logger.info(`Mugharred secure backend listening on :${PORT}`, {
    nodeEnv: NODE_ENV,
    redisUrl: REDIS_URL
  });
});