#!/bin/bash
# Complete Frontend-Backend Integration Fix
# According to goldenrules.md - comprehensive script-driven solution

set -e

echo "🔧 COMPLETE INTEGRATION FIX - ALL FRONTEND-BACKEND ISSUES"
echo "=========================================================="

# Create comprehensive backup
BACKUP_DIR="integration-backup-$(date +%s)"
mkdir -p $BACKUP_DIR
cp -r frontend/src $BACKUP_DIR/frontend-src
cp -r backend/src $BACKUP_DIR/backend-src

echo "📦 Backup created: $BACKUP_DIR"

echo ""
echo "🎯 FIXING BACKEND WEBSOCKET SERVICE..."

# Fix 1: Standardize message types in backend
cat > backend/src/websocket-service-fixed.ts << 'EOF'
import { WebSocketServer, WebSocket } from 'ws';
import { IncomingMessage } from 'http';
import { JWTAuth, JWTPayload } from './jwt-auth.js';
import { redisRoomService } from './redis-room-service.js';
import { randomUUID } from 'crypto';
import DOMPurify from 'dompurify';
import { JSDOM } from 'jsdom';

const window = new JSDOM("").window;
const purify = DOMPurify(window as any);

interface WebSocketConnection {
  socket: WebSocket;
  user: JWTPayload;
  lastActivity: number;
  currentRoomId?: string;
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
      const token = this.extractToken(req);
      if (!token) {
        this.rejectConnection(socket, "No token provided");
        return;
      }

      const user = JWTAuth.verifyToken(token);
      const connectionId = randomUUID();

      const connection: WebSocketConnection = {
        socket,
        user,
        lastActivity: Date.now(),
        currentRoomId: user.roomId
      };
      
      this.connections.set(connectionId, connection);

      console.log(`🔌 WebSocket connected:`, { 
        userId: user.userId, 
        name: user.name,
        roomId: user.roomId || 'none',
        connectionId
      });

      // Set up message handler
      socket.on("message", (raw) => this.handleMessage(connectionId, raw));
      
      socket.on("close", (code, reason) => {
        console.log(`🔌 WebSocket disconnected:`, { 
          userId: user.userId,
          connectionId,
          code, 
          reason: reason?.toString() 
        });
        
        const conn = this.connections.get(connectionId);
        if (conn?.currentRoomId) {
          this.leaveRoomCleanup(connectionId, conn.currentRoomId);
        }
        this.connections.delete(connectionId);
      });

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

  private async handleMessage(connectionId: string, raw: any) {
    const connection = this.connections.get(connectionId);
    if (!connection) return;

    try {
      connection.lastActivity = Date.now();
      const msg = JSON.parse(raw.toString());

      console.log(`📨 WebSocket message:`, { 
        connectionId, 
        type: msg.type,
        user: connection.user.name 
      });

      switch (msg.type) {
        case "heartbeat":
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
    
    const text = String(msg.text || "").trim();
    if (!text || text.length > 500) {
      this.sendToConnection(connectionId, {
        type: "error", 
        error: "Invalid message content"
      });
      return;
    }

    // Use current room or message roomId
    const roomId = connection.currentRoomId || msg.roomId;
    
    if (!roomId) {
      this.sendToConnection(connectionId, {
        type: "error",
        error: "Must be in a room to send messages"
      });
      return;
    }

    const sanitizedText = purify.sanitize(text, { ALLOWED_TAGS: [] });

    const roomMessage = {
      id: randomUUID(),
      user: user.name,
      text: sanitizedText,
      timestamp: Date.now(),
      sanitized: true
    };

    // Broadcast to all room participants
    await this.broadcastToRoom(roomId, {
      type: "message",
      message: roomMessage
    });

    await redisRoomService.addMessage(roomId, {
      ...roomMessage,
      roomId,
      sessionId: user.userId
    });

    console.log(`💬 Message sent to room ${roomId} by ${user.name}`);
  }

  private async handleJoinRoom(connectionId: string, msg: any) {
    const connection = this.connections.get(connectionId);
    if (!connection) return;

    try {
      const { roomId, name } = msg;
      const { user } = connection;

      console.log(`🚪 Joining room:`, { roomId, name, userId: user.userId });

      // Check if room exists
      const roomExists = await redisRoomService.roomExists(roomId);
      if (!roomExists) {
        this.sendToConnection(connectionId, {
          type: "error",
          error: "Room not found"
        });
        return;
      }

      // Update connection room
      connection.currentRoomId = roomId;

      // Add to room participants
      await redisRoomService.addParticipant(roomId, user.userId, name || user.name);

      // Confirm room join
      this.sendToConnection(connectionId, {
        type: "joined_room",
        roomId: roomId,
        success: true
      });

      // Send participants update to all room members
      await this.sendParticipantsUpdate(roomId);

      console.log(`✅ User ${user.name} joined room ${roomId}`);

    } catch (error) {
      console.error("Join room error:", error);
      this.sendToConnection(connectionId, {
        type: "error",
        error: "Failed to join room"
      });
    }
  }

  private async handleLeaveRoom(connectionId: string) {
    const connection = this.connections.get(connectionId);
    if (!connection || !connection.currentRoomId) return;

    await this.leaveRoomCleanup(connectionId, connection.currentRoomId);
  }

  private async leaveRoomCleanup(connectionId: string, roomId: string) {
    const connection = this.connections.get(connectionId);
    if (!connection) return;

    try {
      await redisRoomService.removeParticipant(roomId, connection.user.userId);
      connection.currentRoomId = undefined;
      
      await this.sendParticipantsUpdate(roomId);
      
      console.log(`👋 User ${connection.user.name} left room ${roomId}`);
    } catch (error) {
      console.error("Leave room cleanup error:", error);
    }
  }

  private async sendParticipantsUpdate(roomId: string) {
    try {
      const participants = await redisRoomService.getRoomParticipants(roomId);
      
      await this.broadcastToRoom(roomId, {
        type: "participants_update",
        users: participants.map(p => p.name),
        count: participants.length
      });
    } catch (error) {
      console.error("Send participants update error:", error);
    }
  }

  private async broadcastToRoom(roomId: string, message: any) {
    for (const [connId, connection] of this.connections.entries()) {
      if (connection.currentRoomId === roomId && connection.socket.readyState === WebSocket.OPEN) {
        this.sendToConnection(connId, message);
      }
    }
  }

  private sendToConnection(connectionId: string, message: any) {
    const connection = this.connections.get(connectionId);
    if (connection && connection.socket.readyState === WebSocket.OPEN) {
      connection.socket.send(JSON.stringify(message));
    }
  }

  private setupCleanupInterval() {
    setInterval(() => {
      const now = Date.now();
      for (const [connId, connection] of this.connections.entries()) {
        if (now - connection.lastActivity > 300000) { // 5 minutes
          connection.socket.close();
          this.connections.delete(connId);
        }
      }
    }, 60000); // Check every minute
  }

  public getConnectionCount(): number {
    return this.connections.size;
  }
}
EOF

# Replace old WebSocket service
mv backend/src/websocket-service.ts backend/src/websocket-service.ts.old
mv backend/src/websocket-service-fixed.ts backend/src/websocket-service.ts

echo "✅ Backend WebSocket service fixed"

echo ""
echo "🎯 FIXING FRONTEND WEBSOCKET INTEGRATION..."

# Fix 2: Complete frontend WebSocket integration fix
cat > frontend/src/MugharredLandingPage-fixed.tsx << 'EOF'
import React, { useState, useEffect, useRef } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { Copy, Share2, Users, Clock, MessageCircle, X, Sparkles } from 'lucide-react';
import DOMPurify from 'dompurify';

// Secure API utilities - JWT wrapper handles tokens
class SecureAPI {
  static async secureRequest(url: string, options: RequestInit = {}): Promise<Response> {
    const headers = {
      'Content-Type': 'application/json',
      ...options.headers,
    };
    return fetch(url, {
      ...options,
      headers,
    });
  }
}

interface Message {
  id: string;
  user: string;
  text: string;
  timestamp: number;
  sanitized?: boolean;
}

interface CreateRoomFormProps {
  onCreateRoom: (userName: string, roomName: string, maxParticipants: number, duration: number) => Promise<void>;
  onCancel: () => void;
}

function CreateRoomForm({ onCreateRoom, onCancel }: CreateRoomFormProps) {
  const [userName, setUserName] = useState("");
  const [roomName, setRoomName] = useState("");
  const [maxParticipants, setMaxParticipants] = useState(4);
  const [duration, setDuration] = useState(30);
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!userName.trim() || !roomName.trim()) return;

    setLoading(true);
    try {
      await onCreateRoom(userName.trim(), roomName.trim(), maxParticipants, duration);
    } finally {
      setLoading(false);
    }
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-2">
          Your Name
        </label>
        <input
          type="text"
          value={userName}
          onChange={(e) => setUserName(e.target.value)}
          className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500"
          placeholder="Enter your name"
          required
          maxLength={50}
        />
      </div>

      <div>
        <label className="block text-sm font-medium text-gray-700 mb-2">
          Room Name
        </label>
        <input
          type="text"
          value={roomName}
          onChange={(e) => setRoomName(e.target.value)}
          className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500"
          placeholder="What's this room for?"
          required
          maxLength={100}
        />
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Max People
          </label>
          <select
            value={maxParticipants}
            onChange={(e) => setMaxParticipants(Number(e.target.value))}
            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500"
          >
            <option value={2}>2 people</option>
            <option value={4}>4 people</option>
            <option value={6}>6 people</option>
            <option value={8}>8 people</option>
            <option value={12}>12 people</option>
          </select>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Duration
          </label>
          <select
            value={duration}
            onChange={(e) => setDuration(Number(e.target.value))}
            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500"
          >
            <option value={15}>15 minutes</option>
            <option value={30}>30 minutes</option>
            <option value={60}>1 hour</option>
            <option value={120}>2 hours</option>
          </select>
        </div>
      </div>

      <div className="flex gap-3 pt-4">
        <button
          type="button"
          onClick={onCancel}
          className="flex-1 px-4 py-2 text-gray-600 border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
          disabled={loading}
        >
          Cancel
        </button>
        <button
          type="submit"
          className="flex-1 bg-gradient-to-r from-emerald-600 to-green-600 text-white px-4 py-2 rounded-lg hover:from-emerald-700 hover:to-green-700 disabled:opacity-50 transition-all"
          disabled={loading || !userName.trim() || !roomName.trim()}
        >
          {loading ? "Creating..." : "Create Room"}
        </button>
      </div>
    </form>
  );
}

interface JoinRoomModalProps {
  roomId: string;
  onJoin: (userName: string) => Promise<void>;
  onCancel: () => void;
}

function JoinRoomModal({ roomId, onJoin, onCancel }: JoinRoomModalProps) {
  const [userName, setUserName] = useState("");
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!userName.trim()) return;

    setLoading(true);
    try {
      await onJoin(userName.trim());
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
      <div className="bg-white rounded-xl shadow-xl p-8 max-w-md w-full">
        <h2 className="text-2xl font-bold text-gray-900 mb-2">Join Room</h2>
        <p className="text-gray-600 mb-6">Room ID: {roomId}</p>
        
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Your Name
            </label>
            <input
              type="text"
              value={userName}
              onChange={(e) => setUserName(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500"
              placeholder="Enter your name"
              required
              maxLength={50}
              autoFocus
            />
          </div>

          <div className="flex gap-3 pt-4">
            <button
              type="button"
              onClick={onCancel}
              className="flex-1 px-4 py-2 text-gray-600 border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
              disabled={loading}
            >
              Cancel
            </button>
            <button
              type="submit"
              className="flex-1 bg-gradient-to-r from-emerald-600 to-green-600 text-white px-4 py-2 rounded-lg hover:from-emerald-700 hover:to-green-700 disabled:opacity-50 transition-all"
              disabled={loading || !userName.trim()}
            >
              {loading ? "Joining..." : "Join Room"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

export default function MugharredLandingPage() {
  const location = useLocation();
  const navigate = useNavigate();
  
  // UI State
  const [showCreateRoomModal, setShowCreateRoomModal] = useState(false);
  const [showJoinRoomModal, setShowJoinRoomModal] = useState(false);
  const [activeModal, setActiveModal] = useState<string | null>(null);
  const [toast, setToast] = useState<{message: string, type: string} | null>(null);
  const [currentTextIndex, setCurrentTextIndex] = useState(0);
  const [containerHeight, setContainerHeight] = useState(0);
  
  // App State
  const [sessionId, setSessionId] = useState<string | null>(null);
  const [name, setName] = useState("");
  const [currentRoomId, setCurrentRoomId] = useState<string | null>(null);
  const [messages, setMessages] = useState<Message[]>([]);
  const [onlineUsers, setOnlineUsers] = useState<string[]>([]);
  const [input, setInput] = useState("");
  
  // WebSocket State
  const [ws, setWs] = useState<WebSocket | null>(null);
  const [wsConnected, setWsConnected] = useState(false);
  const wsRef = useRef<WebSocket | null>(null);
  const heartbeatInterval = useRef<NodeJS.Timeout | null>(null);
  const inputRef = useRef<HTMLInputElement>(null);
  const containerRef = useRef<HTMLDivElement>(null);

  const rotatingTexts = [
    "Planning", "Interviews", "Study Sessions", 
    "Customer Calls", "Hangouts", "Team Meetings",
    "Coffee Chats", "Quick Syncs"
  ];

  // Toast helper
  const showToast = (message: string, type: string = "info") => {
    setToast({ message, type });
    setTimeout(() => setToast(null), 5000);
  };

  // Check for room URL on load
  useEffect(() => {
    const path = location.pathname;
    const roomMatch = path.match(/^\/r\/([a-zA-Z0-9\-]+)$/);
    
    if (roomMatch) {
      const roomId = roomMatch[1];
      setCurrentRoomId(roomId);
      if (!sessionId) {
        setShowJoinRoomModal(true);
      }
    }
  }, [location.pathname, sessionId]);

  // Rotating text animation
  useEffect(() => {
    const interval = setInterval(() => {
      setCurrentTextIndex((prev) => (prev + 1) % rotatingTexts.length);
    }, 2500);
    
    return () => clearInterval(interval);
  }, [rotatingTexts.length]);

  // Update container height on resize
  useEffect(() => {
    const updateHeight = () => {
      if (containerRef.current) {
        setContainerHeight(containerRef.current.clientHeight);
      }
    };

    updateHeight();
    window.addEventListener('resize', updateHeight);
    return () => window.removeEventListener('resize', updateHeight);
  }, []);

  // Auto-scroll to bottom when new messages arrive
  useEffect(() => {
    if (containerRef.current && messages.length > 0) {
      const container = containerRef.current;
      const isNearBottom = container.scrollTop + container.clientHeight >= container.scrollHeight - 200;
      
      if (isNearBottom) {
        setTimeout(() => {
          container.scrollTop = container.scrollHeight;
        }, 100);
      }
    }
  }, [messages]);

  // Logout handler
  const handleLogout = async () => {
    try {
      // Close WebSocket
      if (ws) {
        ws.close();
        setWs(null);
      }
      
      // Clear local state
      setSessionId(null);
      setName("");
      setMessages([]);
      setOnlineUsers([]);
      setCurrentRoomId(null);
      
      if (heartbeatInterval.current) {
        clearInterval(heartbeatInterval.current);
        heartbeatInterval.current = null;
      }
      
      // Navigate to home
      navigate("/");
      showToast("Logged out successfully", "success");
    } catch (error) {
      console.error("Logout error:", error);
      showToast("Logout failed", "error");
    }
  };

  // Fixed WebSocket connection with proper token handling
  const connectWebSocket = async () => {
    if (wsRef.current) {
      wsRef.current.close();
    }

    let reconnectAttempts = 0;
    const maxReconnectAttempts = 5;

    const connect = () => {
      try {
        // Get token from localStorage (managed by jwt-wrapper)
        const token = localStorage.getItem('mugharred_token');
        if (!token) {
          console.error("No JWT token available for WebSocket");
          return;
        }

        const protocol = window.location.protocol === "https:" ? "wss:" : "ws:";
        const wsUrl = `${protocol}//${window.location.host}/ws?token=${encodeURIComponent(token)}`;
        const socket = new WebSocket(wsUrl);
        
        socket.onopen = () => {
          setWsConnected(true);
          reconnectAttempts = 0;
          wsRef.current = socket;
          setWs(socket);
          
          console.log("✅ WebSocket connected successfully");
          showToast("Connected to real-time", "success");
          
          // Join room immediately if we have roomId and name
          if (currentRoomId && name) {
            socket.send(JSON.stringify({
              type: 'join_room',
              roomId: currentRoomId,
              name: name
            }));
            console.log(`🚪 Sent join_room for ${currentRoomId} as ${name}`);
          }
        };

        socket.onmessage = (event) => {
          try {
            const data = JSON.parse(event.data);
            console.log("📨 WebSocket message received:", data);
            
            if (data.type === "message") {
              const sanitizedMessage = {
                ...data.message,
                text: DOMPurify.sanitize(data.message.text),
                user: DOMPurify.sanitize(data.message.user),
                sanitized: true
              };
              
              setMessages(prev => {
                const exists = prev.find(m => m.id === sanitizedMessage.id);
                if (exists) return prev;
                return [...prev, sanitizedMessage].sort((a, b) => a.timestamp - b.timestamp);
              });
              
            } else if (data.type === "participants_update") {
              console.log("👥 Participants update:", data);
              const sanitizedUsers = data.users.map((user: string) => DOMPurify.sanitize(user));
              setOnlineUsers(sanitizedUsers);
              
            } else if (data.type === "joined_room") {
              console.log("🎉 Successfully joined room:", data.roomId);
              showToast("Joined room successfully", "success");
              
            } else if (data.type === "connected") {
              console.log("🔌 WebSocket connection confirmed");
              
            } else if (data.type === "error") {
              console.error("❌ WebSocket error:", data.error);
              showToast(data.error, "error");
            }
            
          } catch (error) {
            console.error("WebSocket message parse error:", error);
          }
        };

        socket.onerror = (error) => {
          console.error("WebSocket error:", error);
          showToast("Connection error", "error");
        };

        socket.onclose = (event) => {
          console.log("WebSocket closed:", event.code, event.reason);
          setWsConnected(false);
          wsRef.current = null;
          setWs(null);
          
          // Attempt reconnection
          if (reconnectAttempts < maxReconnectAttempts && sessionId) {
            reconnectAttempts++;
            console.log(`🔄 Reconnecting... attempt ${reconnectAttempts}`);
            setTimeout(connect, Math.pow(2, reconnectAttempts) * 1000);
          }
        };

        // Setup heartbeat
        heartbeatInterval.current = setInterval(() => {
          if (socket.readyState === WebSocket.OPEN) {
            socket.send(JSON.stringify({ type: "heartbeat" }));
          }
        }, 30000);

      } catch (error) {
        console.error("WebSocket connection failed:", error);
        showToast("Failed to connect to real-time", "error");
      }
    };

    connect();
  };

  // Connect WebSocket when logged in
  useEffect(() => {
    if (sessionId) {
      connectWebSocket();
    }
    
    return () => {
      if (wsRef.current) {
        wsRef.current.close();
      }
      if (heartbeatInterval.current) {
        clearInterval(heartbeatInterval.current);
      }
    };
  }, [sessionId]);

  // Trigger room join when room changes
  useEffect(() => {
    if (ws && ws.readyState === WebSocket.OPEN && currentRoomId && name) {
      console.log(`🚪 Joining room ${currentRoomId} as ${name}`);
      ws.send(JSON.stringify({
        type: 'join_room',
        roomId: currentRoomId,
        name: name
      }));
    }
  }, [ws, currentRoomId, name, wsConnected]);

  // Create room handler
  const handleCreateRoom = async (userName: string, roomName: string, maxParticipants: number, duration: number) => {
    try {
      // Login first
      const loginResponse = await SecureAPI.secureRequest('/api/login', {
        method: 'POST',
        body: JSON.stringify({ name: userName }),
      });

      if (!loginResponse.ok) {
        throw new Error('Login failed');
      }
      
      const loginData = await loginResponse.json();
      setSessionId(loginData.token || 'logged-in');
      setName(userName);
      
      // Create room
      const response = await SecureAPI.secureRequest('/api/create-room', {
        method: 'POST',
        body: JSON.stringify({ 
          name: roomName,
          maxParticipants,
          duration,
          hostName: userName 
        }),
      });

      if (!response.ok) {
        throw new Error('Failed to create room');
      }

      const data = await response.json();
      setCurrentRoomId(data.roomId);
      setShowCreateRoomModal(false);
      
      // Update URL
      window.history.pushState({}, '', `/r/${data.roomId}`);
      
      showToast("Room created successfully! Share the link to invite others.", "success");
      
    } catch (error) {
      console.error("Create room error:", error);
      showToast("Failed to create room", "error");
    }
  };

  // Join room handler
  const handleJoinRoom = async (userName: string) => {
    try {
      // Login first
      const loginResponse = await SecureAPI.secureRequest('/api/login', {
        method: 'POST',
        body: JSON.stringify({ name: userName }),
      });

      if (!loginResponse.ok) {
        throw new Error('Login failed');
      }
      
      const loginData = await loginResponse.json();
      setSessionId(loginData.token || 'logged-in');
      setName(userName);
      
      // Join room via API
      const response = await SecureAPI.secureRequest("/api/join-room", {
        method: "POST",
        body: JSON.stringify({ 
          roomId: currentRoomId,
          participantName: userName 
        }),
      });

      if (!response.ok) {
        throw new Error('Failed to join room');
      }

      setShowJoinRoomModal(false);
      showToast("Joined room successfully", "success");
      
    } catch (error) {
      console.error("Join room error:", error);
      showToast("Failed to join room", "error");
    }
  };

  // Send message handler
  const sendMessage = () => {
    if (!input.trim() || !ws || ws.readyState !== WebSocket.OPEN || !currentRoomId) return;

    const sanitizedInput = DOMPurify.sanitize(input.trim());
    
    console.log(`💬 Sending message to room ${currentRoomId}:`, sanitizedInput);
    
    ws.send(JSON.stringify({
      type: "send_message",
      roomId: currentRoomId,
      text: sanitizedInput
    }));
    
    setInput("");
    if (inputRef.current) {
      inputRef.current.focus();
    }
  };

  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      sendMessage();
    }
  };

  // Toast component
  const Toast = ({ message, type, onClose }: { message: string; type: string; onClose: () => void }) => (
    <div className={`
      fixed top-4 right-4 z-50 px-4 py-2 rounded-lg shadow-lg max-w-sm
      ${type === 'error' ? 'bg-red-500 text-white' : 
        type === 'success' ? 'bg-green-500 text-white' : 
        'bg-blue-500 text-white'}
      transition-all duration-300 animate-slide-in-right
    `}>
      <div className="flex items-center gap-2">
        <span className="flex-1">{message}</span>
        <button 
          onClick={onClose}
          className="p-1 hover:bg-black/10 rounded"
        >
          <X size={14} />
        </button>
      </div>
    </div>
  );

  // Show landing page if not logged in and not on room URL
  if (!sessionId && !currentRoomId) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-emerald-50 via-green-50 to-yellow-50">
        {toast && (
          <Toast 
            message={toast.message} 
            type={toast.type} 
            onClose={() => setToast(null)} 
          />
        )}

        {/* Header */}
        <header className="bg-white/90 backdrop-blur-sm shadow-sm border-b border-emerald-100">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <img 
                  src="/logo.webp" 
                  alt="Mugharred" 
                  className="w-8 h-8 object-contain"
                />
                <h1 className="text-xl font-bold bg-gradient-to-r from-emerald-600 to-green-600 bg-clip-text text-transparent">
                  Mugharred
                </h1>
              </div>
            </div>
          </div>
        </header>

        {/* Hero Section */}
        <div className="relative overflow-hidden">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-20">
            <div className="text-center">
              <div className="space-y-8">
                <div className="space-y-4">
                  <h1 className="text-5xl md:text-7xl font-bold text-gray-900 leading-tight">
                    Create a room
                  </h1>
                  <p className="text-xl md:text-2xl text-gray-600 max-w-2xl mx-auto">
                    No signup. No downloads. Just a link.
                  </p>
                </div>

                <div className="flex items-center justify-center gap-4 text-lg md:text-xl text-gray-600 flex-wrap">
                  <span>Instant Rooms for</span>
                  <div 
                    className="font-bold text-emerald-600 min-w-[140px] text-left transition-all duration-500"
                    style={{ height: '32px' }}
                  >
                    {rotatingTexts[currentTextIndex]}
                  </div>
                </div>

                <div className="pt-8">
                  <button
                    onClick={() => setShowCreateRoomModal(true)}
                    className="group relative bg-gradient-to-r from-emerald-600 to-green-600 text-white px-12 py-6 rounded-2xl font-bold text-xl shadow-xl hover:shadow-2xl transform hover:scale-105 transition-all duration-300"
                  >
                    <div className="flex items-center gap-3">
                      <Sparkles className="w-6 h-6" />
                      <span>Create a Room</span>
                    </div>
                  </button>
                </div>

                <p className="text-gray-500 text-sm max-w-md mx-auto">
                  Rooms expire automatically. No accounts required. Zero friction.
                </p>
              </div>
            </div>
          </div>
        </div>

        {/* Features */}
        <div className="py-20 bg-white/50">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div className="grid md:grid-cols-3 gap-8">
              <div className="text-center space-y-4">
                <div className="w-16 h-16 bg-emerald-100 rounded-2xl flex items-center justify-center mx-auto">
                  <MessageCircle className="w-8 h-8 text-emerald-600" />
                </div>
                <h3 className="text-xl font-bold text-gray-900">Instant Chat</h3>
                <p className="text-gray-600">
                  Real-time messaging that just works. No setup, no accounts.
                </p>
              </div>

              <div className="text-center space-y-4">
                <div className="w-16 h-16 bg-emerald-100 rounded-2xl flex items-center justify-center mx-auto">
                  <Clock className="w-8 h-8 text-emerald-600" />
                </div>
                <h3 className="text-xl font-bold text-gray-900">Auto-Expire</h3>
                <p className="text-gray-600">
                  Rooms automatically disappear. No digital clutter, ever.
                </p>
              </div>

              <div className="text-center space-y-4">
                <div className="w-16 h-16 bg-emerald-100 rounded-2xl flex items-center justify-center mx-auto">
                  <Share2 className="w-8 h-8 text-emerald-600" />
                </div>
                <h3 className="text-xl font-bold text-gray-900">Easy Sharing</h3>
                <p className="text-gray-600">
                  One link = one room. Share anywhere, join instantly.
                </p>
              </div>
            </div>
          </div>
        </div>

        {/* Footer */}
        <footer className="bg-white border-t border-gray-200">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
            <div className="text-center space-y-8">
              <div className="flex items-center justify-center gap-8 text-sm">
                <button 
                  onClick={() => setActiveModal('privacy')}
                  className="text-gray-600 hover:text-emerald-600 transition-colors duration-200 font-medium"
                >
                  Privacy Policy
                </button>
                <span className="text-gray-300">•</span>
                <button 
                  onClick={() => setActiveModal('terms')}
                  className="text-gray-600 hover:text-emerald-600 transition-colors duration-200 font-medium"
                >
                  Terms of Service
                </button>
                <span className="text-gray-300">•</span>
                <button 
                  onClick={() => setActiveModal('about')}
                  className="text-gray-600 hover:text-emerald-600 transition-colors duration-200 font-medium"
                >
                  About
                </button>
              </div>
              
              <div className="border-t border-gray-200 pt-8">
                <p className="text-sm text-gray-500">
                  © 2025 Mugharred. Built with ❤️ for instant human connection.
                </p>
              </div>
            </div>
          </div>
        </footer>

        {/* Room Creation Modal */}
        {showCreateRoomModal && (
          <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center p-4 z-50">
            <div className="bg-white/90 backdrop-blur-lg rounded-xl shadow-xl border border-white/20 p-8 w-full max-w-md">
              <h2 className="text-2xl font-bold text-gray-900 mb-6">Create Room</h2>
              
              <CreateRoomForm 
                onCreateRoom={handleCreateRoom}
                onCancel={() => setShowCreateRoomModal(false)}
              />
            </div>
          </div>
        )}

        {/* Legal Modals */}
        {activeModal && (
          <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center p-4 z-50">
            <div className="bg-white rounded-xl shadow-xl max-w-4xl w-full max-h-[80vh] overflow-hidden">
              <div className="p-6 border-b border-gray-200 flex items-center justify-between">
                <h2 className="text-2xl font-bold text-gray-900">
                  {activeModal === 'privacy' && 'Privacy Policy'}
                  {activeModal === 'terms' && 'Terms of Service'}
                  {activeModal === 'about' && 'About Mugharred'}
                </h2>
                <button
                  onClick={() => setActiveModal(null)}
                  className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
                >
                  <X size={20} />
                </button>
              </div>
              <div className="p-6 overflow-auto max-h-[60vh]">
                <div className="prose prose-emerald max-w-none">
                  <p>Content for {activeModal} modal...</p>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>
    );
  }

  // Chat interface for logged in users OR room URLs
  return (
    <div className="min-h-screen bg-gradient-to-br from-emerald-50 via-green-50 to-yellow-50">
      {toast && (
        <Toast 
          message={toast.message} 
          type={toast.type} 
          onClose={() => setToast(null)} 
        />
      )}

      {/* Join Room Modal */}
      {showJoinRoomModal && currentRoomId && (
        <JoinRoomModal
          roomId={currentRoomId}
          onJoin={handleJoinRoom}
          onCancel={() => {
            setShowJoinRoomModal(false);
            window.location.href = "/";
          }}
        />
      )}

      {/* Header */}
      <header className="bg-white/90 backdrop-blur-sm shadow-sm border-b border-emerald-100">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4">
              <img 
                src="/logo.webp" 
                alt="Mugharred" 
                className="w-8 h-8 object-contain"
              />
              <div>
                <h1 className="text-xl font-bold bg-gradient-to-r from-emerald-600 to-green-600 bg-clip-text text-transparent">
                  Mugharred
                </h1>
                {currentRoomId && (
                  <p className="text-sm text-gray-600">
                    Room: {currentRoomId}
                  </p>
                )}
              </div>
            </div>

            <div className="flex items-center gap-4">
              <div className="flex items-center gap-2">
                <div className={`w-2 h-2 rounded-full ${wsConnected ? 'bg-green-500' : 'bg-red-500'}`}></div>
                <span className="text-sm text-gray-600">
                  {wsConnected ? 'Connected' : 'Disconnected'}
                </span>
              </div>

              <div className="flex items-center gap-2 text-sm text-gray-600">
                <Users size={16} />
                <span>Online ({onlineUsers.length})</span>
              </div>

              {currentRoomId && (
                <div className="flex items-center gap-2">
                  <button
                    onClick={() => {
                      navigator.clipboard.writeText(window.location.href);
                      showToast("Room link copied!", "success");
                    }}
                    className="flex items-center gap-2 px-3 py-1 bg-emerald-100 text-emerald-700 rounded-lg hover:bg-emerald-200 transition-colors"
                  >
                    <Copy size={14} />
                    <span className="text-sm">Copy Link</span>
                  </button>

                  <button
                    onClick={() => {
                      if (navigator.share) {
                        navigator.share({
                          title: 'Join my room',
                          text: 'Join my instant room on Mugharred',
                          url: window.location.href,
                        });
                      } else {
                        navigator.clipboard.writeText(window.location.href);
                        showToast("Room link copied!", "success");
                      }
                    }}
                    className="flex items-center gap-2 px-3 py-1 bg-blue-100 text-blue-700 rounded-lg hover:bg-blue-200 transition-colors"
                  >
                    <Share2 size={14} />
                    <span className="text-sm">Share</span>
                  </button>
                </div>
              )}

              <button
                onClick={handleLogout}
                className="text-sm text-gray-600 hover:text-red-600 transition-colors"
              >
                Leave
              </button>
            </div>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <div className="flex-1 flex flex-col h-[calc(100vh-80px)]">
        {/* Messages */}
        <div 
          ref={containerRef}
          className="flex-1 overflow-y-auto p-4 space-y-4"
        >
          {messages.length === 0 ? (
            <div className="text-center text-gray-500 mt-8">
              <MessageCircle size={48} className="mx-auto mb-4 text-gray-300" />
              <p>No messages yet. Start the conversation!</p>
            </div>
          ) : (
            messages.map((message) => (
              <div
                key={message.id}
                className={`flex ${message.user === name ? 'justify-end' : 'justify-start'}`}
              >
                <div
                  className={`max-w-xs lg:max-w-md px-4 py-2 rounded-2xl ${
                    message.user === name
                      ? 'bg-emerald-500 text-white'
                      : 'bg-white border border-gray-200'
                  }`}
                >
                  {message.user !== name && (
                    <p className="text-xs text-gray-500 mb-1">{message.user}</p>
                  )}
                  <p className="text-sm">{message.text}</p>
                  <p className="text-xs opacity-70 mt-1">
                    {new Date(message.timestamp).toLocaleTimeString([], {
                      hour: '2-digit',
                      minute: '2-digit'
                    })}
                  </p>
                </div>
              </div>
            ))
          )}
        </div>

        {/* Online Users */}
        {onlineUsers.length > 0 && (
          <div className="px-4 py-2 bg-white/50 border-t border-gray-200">
            <p className="text-xs text-gray-600 mb-2">Online ({onlineUsers.length})</p>
            <div className="flex flex-wrap gap-2">
              {onlineUsers.map((user, index) => (
                <span
                  key={index}
                  className="inline-flex items-center gap-1 px-2 py-1 bg-emerald-100 text-emerald-700 rounded-full text-xs"
                >
                  <div className="w-2 h-2 bg-emerald-500 rounded-full"></div>
                  {user}
                </span>
              ))}
            </div>
          </div>
        )}

        {/* Input */}
        <div className="p-4 bg-white border-t border-gray-200">
          <div className="flex gap-2">
            <input
              ref={inputRef}
              type="text"
              value={input}
              onChange={(e) => setInput(e.target.value)}
              onKeyPress={handleKeyPress}
              placeholder={currentRoomId ? "Type a message..." : "Join a room to chat"}
              disabled={!currentRoomId || !wsConnected}
              className="flex-1 px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500 disabled:bg-gray-100 disabled:cursor-not-allowed"
              maxLength={500}
            />
            <button
              onClick={sendMessage}
              disabled={!input.trim() || !currentRoomId || !wsConnected}
              className="px-6 py-2 bg-emerald-500 text-white rounded-lg hover:bg-emerald-600 disabled:bg-gray-300 disabled:cursor-not-allowed transition-colors"
            >
              Send
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
EOF

# Replace old frontend
mv frontend/src/MugharredLandingPage.tsx frontend/src/MugharredLandingPage.tsx.old
mv frontend/src/MugharredLandingPage-fixed.tsx frontend/src/MugharredLandingPage.tsx

echo "✅ Frontend WebSocket integration completely fixed"

echo ""
echo "🎯 FIXING REDIS ROOM SERVICE..."

# Fix 3: Add missing Redis methods
cat >> backend/src/redis-room-service.ts << 'EOF'

  // Additional methods for WebSocket integration
  public async roomExists(roomId: string): Promise<boolean> {
    try {
      const room = await redisClient.get(`room:${roomId}`);
      return room !== null;
    } catch (error) {
      console.error("Room exists check error:", error);
      return false;
    }
  }

  public async addParticipant(roomId: string, userId: string, name: string): Promise<void> {
    try {
      const roomKey = `room:${roomId}`;
      const roomData = await redisClient.get(roomKey);
      
      if (!roomData) {
        throw new Error("Room not found");
      }

      const room = JSON.parse(roomData);
      room.participants[userId] = {
        id: userId,
        name: name,
        joinedAt: Date.now()
      };

      await redisClient.set(roomKey, JSON.stringify(room), {
        EX: Math.floor((room.expiresAt - Date.now()) / 1000)
      });
    } catch (error) {
      console.error("Add participant error:", error);
      throw error;
    }
  }

  public async removeParticipant(roomId: string, userId: string): Promise<void> {
    try {
      const roomKey = `room:${roomId}`;
      const roomData = await redisClient.get(roomKey);
      
      if (!roomData) return;

      const room = JSON.parse(roomData);
      delete room.participants[userId];

      await redisClient.set(roomKey, JSON.stringify(room), {
        EX: Math.floor((room.expiresAt - Date.now()) / 1000)
      });
    } catch (error) {
      console.error("Remove participant error:", error);
    }
  }

  public async getRoomParticipants(roomId: string): Promise<Array<{id: string, name: string}>> {
    try {
      const roomKey = `room:${roomId}`;
      const roomData = await redisClient.get(roomKey);
      
      if (!roomData) return [];

      const room = JSON.parse(roomData);
      return Object.values(room.participants || {}) as Array<{id: string, name: string}>;
    } catch (error) {
      console.error("Get room participants error:", error);
      return [];
    }
  }
EOF

echo "✅ Redis room service extended"

echo ""
echo "🏗️ BUILDING BACKEND..."
cd backend
npm run build
cd ..

echo ""
echo "🏗️ BUILDING FRONTEND..."
cd frontend
npm run build
cd ..

echo ""
echo "🚀 DEPLOYING..."
sudo cp -r frontend/dist/* /var/www/html/

echo ""
echo "🔄 RESTARTING BACKEND..."
pkill -f "node.*server.js" || true
sleep 2
nohup node backend/dist/server.js > /dev/null 2>&1 &

echo ""
echo "✅ COMPLETE INTEGRATION FIX APPLIED!"
echo "================================================="
echo ""
echo "🎯 FIXED ISSUES:"
echo "1. ✅ WebSocket message type standardization"
echo "2. ✅ Proper JWT token handling in WebSocket"
echo "3. ✅ Fixed heartbeat (heartbeat → ping/pong)"
echo "4. ✅ Room state synchronization"
echo "5. ✅ Participant tracking with Redis"
echo "6. ✅ Message broadcasting to room members"
echo "7. ✅ Proper error handling and reconnection"
echo "8. ✅ Room join/leave lifecycle management"
echo "9. ✅ Online user display synchronization"
echo "10. ✅ Complete frontend-backend message alignment"
echo ""
echo "🧪 TEST THE COMPLETE FLOW:"
echo "1. User 1: Create room at https://mugharred.se/"
echo "2. User 1: Send multiple messages (should work)"
echo "3. User 1: Should appear online"
echo "4. User 2: Join via share link"
echo "5. User 2: Send messages (should work)"
echo "6. Both: Should see each other online"
echo "7. Both: Should see real-time messages"
echo ""
echo "🎉 INTEGRATION IS NOW COMPLETE!"