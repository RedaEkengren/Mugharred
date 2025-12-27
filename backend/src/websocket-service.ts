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

  private async handleMessage(connectionId: string, raw: any) {
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
    
    await redisRoomService.leaveRoom(user.roomId!, user.userId);
    
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
