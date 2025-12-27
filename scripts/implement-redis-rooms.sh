#!/bin/bash
# PHASE 1 REWRITE: Redis Room Storage
# Replace memory storage with Redis persistence
# Compliance: goldenrules.md - script-driven changes only

set -e

echo "🏠 IMPLEMENTING REDIS ROOM STORAGE"
echo "Replacing memory storage with Redis persistence..."

# Navigate to backend
cd /home/reda/development/mugharred/backend

# Install Redis client
echo "Installing Redis dependencies..."
npm install redis @types/redis

# Create Redis room storage service
echo "Creating Redis room service..."
cat > src/redis-room-service.ts << 'EOF'
import { createClient, RedisClientType } from 'redis';
import { Room, Participant, RoomMessage, CreateRoomRequest, JoinRoomRequest } from './room-types.js';
import { JWTAuth } from './jwt-auth.js';

export class RedisRoomService {
  private client: RedisClientType;
  private pubClient: RedisClientType;
  private subClient: RedisClientType;

  constructor() {
    const redisUrl = process.env.REDIS_URL || 'redis://localhost:6379';
    
    this.client = createClient({ url: redisUrl });
    this.pubClient = createClient({ url: redisUrl });
    this.subClient = createClient({ url: redisUrl });

    this.client.on('error', (err) => console.error('Redis Client Error:', err));
    this.pubClient.on('error', (err) => console.error('Redis Pub Error:', err));
    this.subClient.on('error', (err) => console.error('Redis Sub Error:', err));
  }

  async connect(): Promise<void> {
    await Promise.all([
      this.client.connect(),
      this.pubClient.connect(),
      this.subClient.connect()
    ]);
    console.log('✅ Redis connected for room storage');
  }

  async disconnect(): Promise<void> {
    await Promise.all([
      this.client.disconnect(),
      this.pubClient.disconnect(),
      this.subClient.disconnect()
    ]);
  }

  // Create room with Redis persistence
  async createRoom(request: CreateRoomRequest, hostUserId: string): Promise<{ success: boolean; room?: Room; token?: string; error?: string }> {
    try {
      const roomId = this.generateRoomId();
      const now = Date.now();
      const expiresAt = now + (request.duration * 60 * 1000);

      const room: Room = {
        id: roomId,
        name: request.name,
        hostId: hostUserId,
        maxParticipants: request.maxParticipants,
        duration: request.duration,
        createdAt: now,
        expiresAt,
        participants: new Map(),
        messages: [],
        isLocked: false,
        settings: {
          allowGuests: request.settings?.allowGuests ?? true,
          requireApproval: request.settings?.requireApproval ?? false,
          maxMessageLength: request.settings?.maxMessageLength ?? 500
        }
      };

      // Add host as participant
      const host: Participant = {
        sessionId: hostUserId,
        name: request.hostName,
        joinedAt: now,
        lastActivity: now,
        isHost: true
      };
      
      room.participants.set(hostUserId, host);

      // Store room in Redis with TTL
      const ttlSeconds = Math.ceil(request.duration * 60);
      await this.client.setEx(
        `room:${roomId}`, 
        ttlSeconds, 
        JSON.stringify(this.serializeRoom(room))
      );

      // Store participants separately for faster lookups
      await this.client.setEx(
        `room:${roomId}:participants`,
        ttlSeconds,
        JSON.stringify([{ userId: hostUserId, ...host }])
      );

      // Generate JWT token with room permissions
      const token = JWTAuth.generateToken({
        userId: hostUserId,
        name: request.hostName,
        roomId,
        role: 'host'
      });

      console.log(`🏠 Room created: ${roomId} by ${request.hostName} (${request.duration}min)`);
      
      return { success: true, room, token };

    } catch (error) {
      console.error('Failed to create room:', error);
      return { success: false, error: 'Failed to create room' };
    }
  }

  // Join room with Redis lookup
  async joinRoom(request: JoinRoomRequest, userId: string): Promise<{ success: boolean; room?: Room; token?: string; error?: string }> {
    try {
      // Get room from Redis
      const roomData = await this.client.get(`room:${request.roomId}`);
      if (!roomData) {
        return { success: false, error: 'Room not found or expired' };
      }

      const room = this.deserializeRoom(JSON.parse(roomData));

      // Validation checks
      if (Date.now() > room.expiresAt) {
        await this.deleteRoom(request.roomId);
        return { success: false, error: 'Room has expired' };
      }

      if (room.isLocked) {
        return { success: false, error: 'Room is locked' };
      }

      if (room.participants.size >= room.maxParticipants) {
        return { success: false, error: 'Room is full' };
      }

      if (room.participants.has(userId)) {
        return { success: false, error: 'Already in room' };
      }

      // Add participant
      const participant: Participant = {
        sessionId: userId,
        name: request.participantName,
        joinedAt: Date.now(),
        lastActivity: Date.now(),
        isHost: false
      };

      room.participants.set(userId, participant);

      // Update room in Redis
      const remainingTtl = await this.client.ttl(`room:${request.roomId}`);
      if (remainingTtl > 0) {
        await this.client.setEx(
          `room:${request.roomId}`,
          remainingTtl,
          JSON.stringify(this.serializeRoom(room))
        );

        // Update participants list
        const participants = Array.from(room.participants.values()).map(p => ({
          userId: p.sessionId,
          ...p
        }));
        await this.client.setEx(
          `room:${request.roomId}:participants`,
          remainingTtl,
          JSON.stringify(participants)
        );
      }

      // Generate JWT token with room permissions
      const token = JWTAuth.generateToken({
        userId,
        name: request.participantName,
        roomId: request.roomId,
        role: 'participant'
      });

      // Publish join event for real-time updates
      await this.pubClient.publish(`room:${request.roomId}:events`, JSON.stringify({
        type: 'user_joined',
        userId,
        name: request.participantName,
        timestamp: Date.now()
      }));

      console.log(`👋 ${request.participantName} joined room ${request.roomId}`);
      
      return { success: true, room, token };

    } catch (error) {
      console.error('Failed to join room:', error);
      return { success: false, error: 'Failed to join room' };
    }
  }

  // Leave room
  async leaveRoom(roomId: string, userId: string): Promise<boolean> {
    try {
      const roomData = await this.client.get(`room:${roomId}`);
      if (!roomData) return false;

      const room = this.deserializeRoom(JSON.parse(roomData));
      const participant = room.participants.get(userId);
      if (!participant) return false;

      room.participants.delete(userId);

      // If host left or room empty, delete room
      if (participant.isHost || room.participants.size === 0) {
        await this.deleteRoom(roomId);
        await this.pubClient.publish(`room:${roomId}:events`, JSON.stringify({
          type: 'room_closed',
          reason: participant.isHost ? 'host_left' : 'empty',
          timestamp: Date.now()
        }));
        return true;
      }

      // Update room in Redis
      const remainingTtl = await this.client.ttl(`room:${roomId}`);
      if (remainingTtl > 0) {
        await this.client.setEx(
          `room:${roomId}`,
          remainingTtl,
          JSON.stringify(this.serializeRoom(room))
        );

        const participants = Array.from(room.participants.values()).map(p => ({
          userId: p.sessionId,
          ...p
        }));
        await this.client.setEx(
          `room:${roomId}:participants`,
          remainingTtl,
          JSON.stringify(participants)
        );
      }

      // Publish leave event
      await this.pubClient.publish(`room:${roomId}:events`, JSON.stringify({
        type: 'user_left',
        userId,
        name: participant.name,
        timestamp: Date.now()
      }));

      console.log(`👋 ${participant.name} left room ${roomId}`);
      return true;

    } catch (error) {
      console.error('Failed to leave room:', error);
      return false;
    }
  }

  // Get room info
  async getRoom(roomId: string): Promise<Room | null> {
    try {
      const roomData = await this.client.get(`room:${roomId}`);
      if (!roomData) return null;
      
      return this.deserializeRoom(JSON.parse(roomData));
    } catch (error) {
      console.error('Failed to get room:', error);
      return null;
    }
  }

  // Add message to room
  async addMessage(roomId: string, message: RoomMessage): Promise<void> {
    try {
      const room = await this.getRoom(roomId);
      if (!room) return;

      // Add to room messages
      room.messages.push(message);

      // Keep only last 100 messages
      if (room.messages.length > 100) {
        room.messages = room.messages.slice(-100);
      }

      // Update room in Redis
      const remainingTtl = await this.client.ttl(`room:${roomId}`);
      if (remainingTtl > 0) {
        await this.client.setEx(
          `room:${roomId}`,
          remainingTtl,
          JSON.stringify(this.serializeRoom(room))
        );
      }

      // Publish message for real-time delivery
      await this.pubClient.publish(`room:${roomId}:messages`, JSON.stringify(message));

    } catch (error) {
      console.error('Failed to add message:', error);
    }
  }

  // Subscribe to room messages
  async subscribeToRoom(roomId: string, callback: (message: RoomMessage) => void): Promise<void> {
    await this.subClient.subscribe(`room:${roomId}:messages`, (data) => {
      try {
        const message = JSON.parse(data);
        callback(message);
      } catch (error) {
        console.error('Failed to parse room message:', error);
      }
    });
  }

  // Subscribe to room events (join/leave/etc)
  async subscribeToRoomEvents(roomId: string, callback: (event: any) => void): Promise<void> {
    await this.subClient.subscribe(`room:${roomId}:events`, (data) => {
      try {
        const event = JSON.parse(data);
        callback(event);
      } catch (error) {
        console.error('Failed to parse room event:', error);
      }
    });
  }

  // Delete room
  private async deleteRoom(roomId: string): Promise<void> {
    await Promise.all([
      this.client.del(`room:${roomId}`),
      this.client.del(`room:${roomId}:participants`),
      this.client.del(`room:${roomId}:messages`)
    ]);
    console.log(`💥 Room ${roomId} deleted`);
  }

  // Serialize room for Redis storage
  private serializeRoom(room: Room): any {
    return {
      ...room,
      participants: Array.from(room.participants.entries()).map(([key, value]) => [key, value])
    };
  }

  // Deserialize room from Redis storage
  private deserializeRoom(data: any): Room {
    const room = { ...data };
    room.participants = new Map(data.participants);
    return room as Room;
  }

  // Generate room ID (same logic as before)
  private generateRoomId(): string {
    const adjectives = [
      'quiet', 'bright', 'calm', 'swift', 'warm', 'cool', 'deep', 'wide',
      'light', 'dark', 'soft', 'bold', 'fresh', 'clear', 'sharp', 'smooth'
    ];
    
    const nouns = [
      'sun', 'moon', 'star', 'wind', 'wave', 'fire', 'snow', 'rain',
      'cloud', 'tree', 'rock', 'bird', 'fish', 'bear', 'wolf', 'deer'
    ];
    
    const adjective = adjectives[Math.floor(Math.random() * adjectives.length)];
    const noun = nouns[Math.floor(Math.random() * nouns.length)];
    const number = Math.floor(Math.random() * 9000) + 1000;
    
    return `${adjective}-${noun}-${number}`;
  }

  // Get room statistics
  async getStats(): Promise<{ totalRooms: number; totalParticipants: number }> {
    try {
      const keys = await this.client.keys('room:*');
      const roomKeys = keys.filter(key => !key.includes(':participants') && !key.includes(':messages'));
      
      let totalParticipants = 0;
      
      for (const key of roomKeys) {
        const roomData = await this.client.get(key);
        if (roomData) {
          const room = this.deserializeRoom(JSON.parse(roomData));
          totalParticipants += room.participants.size;
        }
      }
      
      return {
        totalRooms: roomKeys.length,
        totalParticipants
      };
    } catch (error) {
      console.error('Failed to get stats:', error);
      return { totalRooms: 0, totalParticipants: 0 };
    }
  }
}

// Singleton instance
export const redisRoomService = new RedisRoomService();
EOF

# Update room types to match JWT auth
echo "Updating room types for JWT compatibility..."
cat > src/room-types.ts << 'EOF'
// Room Management Types for MVP Implementation with JWT Auth

export interface Participant {
  sessionId: string;
  name: string;
  joinedAt: number;
  lastActivity: number;
  isHost: boolean;
}

export interface Room {
  id: string;           // "quiet-sun-5821" 
  name: string;         // User-friendly room name
  hostId: string;       // Creator userId (from JWT)
  maxParticipants: number; // 2-12 per MVP.md
  duration: number;     // 15/30/60/120 min per MVP.md
  createdAt: number;    // timestamp
  expiresAt: number;    // auto-calculated
  participants: Map<string, Participant>;
  messages: RoomMessage[];
  isLocked: boolean;    // Host can lock room
  settings: RoomSettings;
}

export interface RoomMessage {
  id: string;
  roomId: string;      
  user: string;
  text: string;
  timestamp: number;
  sessionId: string;   // From JWT userId
}

export interface RoomSettings {
  allowGuests: boolean;     // Join without name
  requireApproval: boolean; // Host approves joins
  maxMessageLength: number; // Per room limit
}

export interface CreateRoomRequest {
  name: string;
  duration: 15 | 30 | 60 | 120; // Minutes, per MVP.md
  maxParticipants: number;       // 2-12, per MVP.md
  hostName: string;
  settings?: Partial<RoomSettings>;
}

export interface JoinRoomRequest {
  roomId: string;
  participantName: string;
}

// Room validation
export function validateRoomSettings(settings: CreateRoomRequest): string[] {
  const errors: string[] = [];
  
  if (!settings.name || settings.name.trim().length < 2) {
    errors.push('Room name must be at least 2 characters');
  }
  
  if (settings.name.length > 50) {
    errors.push('Room name must be less than 50 characters');
  }
  
  if (![15, 30, 60, 120].includes(settings.duration)) {
    errors.push('Duration must be 15, 30, 60, or 120 minutes');
  }
  
  if (settings.maxParticipants < 2 || settings.maxParticipants > 12) {
    errors.push('Max participants must be between 2 and 12');
  }
  
  if (!settings.hostName || settings.hostName.trim().length < 2) {
    errors.push('Host name must be at least 2 characters');
  }
  
  return errors;
}
EOF

echo "✅ Redis Room Storage implemented"
echo "Next: Run scripts/implement-stateless-websocket.sh" 
echo ""
echo "Redis Features implemented:"
echo "- Persistent room storage in Redis"
echo "- Auto-expire via Redis TTL"
echo "- Real-time pub/sub for room events"
echo "- JWT-based room permissions"
echo "- Room statistics and monitoring"
echo ""
echo "Ready for stateless WebSocket implementation."