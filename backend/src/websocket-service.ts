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

      // If user has roomId in JWT, automatically join WebSocket room
      if (user.roomId) {
        console.log(`🏠 Auto-joining room ${user.roomId} for JWT user ${user.name}`);
        this.handleJoinRoom(connectionId, { roomId: user.roomId, name: user.name });
      }

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
    if (!connection) {
      console.log(`❌ No connection found for ${connectionId}`);
      return;
    }

    console.log(`📩 Raw WebSocket message received:`, { 
      connectionId, 
      rawData: raw.toString(),
      user: connection.user.name 
    });

    try {
      connection.lastActivity = Date.now();
      const msg = JSON.parse(raw.toString());

      console.log(`📨 WebSocket message parsed:`, { 
        connectionId, 
        type: msg.type,
        fullMessage: msg,
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
    console.log(`💬 Message from ${user.name} (${user.userId}) in room ${connection.currentRoomId || msg.roomId}`);
    
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
      const participantName = name || user.name;
      console.log(`👤 Adding participant: userId=${user.userId}, name=${participantName} to room ${roomId}`);
      await redisRoomService.addParticipant(roomId, user.userId, participantName);

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
      console.log(`👥 Room ${roomId} participants:`, participants);
      
      const userNames = participants.map(p => p.name);
      console.log(`👥 Participant names:`, userNames);
      
      await this.broadcastToRoom(roomId, {
        type: "participants_update",
        users: userNames,
        count: participants.length
      });
    } catch (error) {
      console.error("Send participants update error:", error);
    }
  }

  private async broadcastToRoom(roomId: string, message: any, excludeUserId?: string) {
    console.log(`🔊 Broadcasting to room ${roomId}:`, message.type);
    let broadcastCount = 0;
    
    for (const [connId, connection] of this.connections.entries()) {
      console.log(`🔍 Connection ${connId}: roomId=${connection.currentRoomId}, user=${connection.user.name}`);
      if (connection.currentRoomId === roomId && 
          connection.socket.readyState === WebSocket.OPEN &&
          (!excludeUserId || connection.user.userId !== excludeUserId)) {
        this.sendToConnection(connId, message);
        broadcastCount++;
        console.log(`📤 Sent to ${connection.user.name}`);
      }
    }
    
    console.log(`✅ Broadcast complete: ${broadcastCount} recipients`);
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

  public getStats() {
    return {
      connections: this.connections.size
    };
  }
}
