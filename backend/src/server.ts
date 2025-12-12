import "dotenv/config";
import express from "express";
import { createServer } from "http";
import { WebSocketServer, WebSocket } from "ws";
import { randomUUID } from "crypto";
import cors from "cors";

const app = express();
app.use(cors({ 
  origin: ["http://localhost:5173", "https://mugharred.se", "http://mugharred.se"], 
  credentials: true 
}));
app.use(express.json());

const httpServer = createServer(app);
const wss = new WebSocketServer({ server: httpServer, path: "/ws" });

type Message = {
  id: string;
  user: string;
  text: string;
  timestamp: number;
};

type OnlineUser = {
  name: string;
  socket?: WebSocket;
  lastActivity: number;
};

const messages: Message[] = [];
const onlineUsers = new Map<string, OnlineUser>();

// Rate limit: sessionId => array of timestamps (message sends)
const messageTimestamps = new Map<string, number[]>();

const MAX_ONLINE_USERS = 5;
const MAX_MSG_PER_WINDOW = 5;
const WINDOW_MS = 10_000;
const INACTIVITY_TIMEOUT = 5 * 60 * 1000; // 5 minutes

// Simple rate limit check
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

function broadcast(payload: any) {
  const data = JSON.stringify(payload);
  for (const [sid, user] of onlineUsers.entries()) {
    if (user.socket && user.socket.readyState === WebSocket.OPEN) {
      user.socket.send(data);
    }
  }
}

function broadcastOnlineUsers() {
  const users = Array.from(onlineUsers.values()).map((u) => u.name);
  broadcast({ type: "online_users", users });
}

// Clean up inactive users
function cleanupInactiveUsers() {
  const now = Date.now();
  const toRemove: string[] = [];
  
  for (const [sessionId, user] of onlineUsers.entries()) {
    if (now - user.lastActivity > INACTIVITY_TIMEOUT) {
      // Close WebSocket if still connected
      if (user.socket && user.socket.readyState === WebSocket.OPEN) {
        user.socket.send(JSON.stringify({
          type: "error",
          error: "Du har blivit utloggad på grund av inaktivitet."
        }));
        user.socket.close();
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

// LOGIN endpoint (register+login by name)
app.post("/api/login", (req, res) => {
  const { name } = req.body as { name?: string };
  if (!name || name.trim().length < 2) {
    return res.status(400).json({ error: "Skriv minst 2 tecken." });
  }

  if (onlineUsers.size >= MAX_ONLINE_USERS) {
    return res
      .status(429)
      .json({ error: "För många användare online, försök igen senare." });
  }

  const sessionId = randomUUID();
  onlineUsers.set(sessionId, { 
    name: name.trim(),
    lastActivity: Date.now()
  });
  return res.json({ sessionId, name: name.trim() });
});

// Paginated messages
app.get("/api/messages", (req, res) => {
  const offset = parseInt((req.query.offset as string) ?? "0", 10);
  const limit = parseInt((req.query.limit as string) ?? "10", 10);

  const total = messages.length;
  const slice = messages
    .slice()
    .reverse() // newest first
    .slice(offset, offset + limit);

  res.json({ total, items: slice });
});

// Optional: online users HTTP
app.get("/api/online-users", (_req, res) => {
  const users = Array.from(onlineUsers.values()).map((u) => u.name);
  res.json({ users });
});

// Health check
app.get("/health", (_req, res) => {
  res.json({ status: "ok", online: onlineUsers.size, messages: messages.length });
});

// WebSocket handling
wss.on("connection", (socket, req) => {
  const url = new URL(req.url || "", `http://${req.headers.host}`);
  const sessionId = url.searchParams.get("sessionId");

  if (!sessionId || !onlineUsers.has(sessionId)) {
    socket.close();
    return;
  }

  const user = onlineUsers.get(sessionId)!;
  user.socket = socket;
  user.lastActivity = Date.now(); // Update activity on WebSocket connect
  broadcastOnlineUsers();

  socket.on("message", (raw) => {
    try {
      const msg = JSON.parse(raw.toString());
      if (msg.type === "send_message") {
        // Update user activity timestamp
        user.lastActivity = Date.now();
        
        if (!canSendMessage(sessionId)) {
          socket.send(
            JSON.stringify({
              type: "error",
              error: "Rate limit överskriden. Sakta ner lite.",
            }),
          );
          return;
        }

        const text = String(msg.text || "").trim();
        if (!text || text.length > 500) return;

        const message: Message = {
          id: randomUUID(),
          user: user.name,
          text,
          timestamp: Date.now(),
        };
        messages.push(message);
        broadcast({ type: "message", message });
      }
    } catch (e) {
      console.error("WS parse error", e);
    }
  });

  socket.on("close", () => {
    onlineUsers.delete(sessionId);
    broadcastOnlineUsers();
  });
});

const PORT = Number(process.env.PORT || 3001);
httpServer.listen(PORT, () => {
  console.log(`Mugharred backend listening on :${PORT}`);
});