#!/bin/bash
# STEG 1: Room Management Foundation
# Creates backend room infrastructure without breaking current chat

set -e

echo "🏗️  STEG 1: Creating Room Management Foundation..."
echo "📍 Working directory: $(pwd)"

# Backup current backend
echo "📦 Creating backup..."
cp -r backend/src backend/src.backup.$(date +%Y%m%d_%H%M%S)

# Create room types file
echo "📝 Creating room types..."
cat > backend/src/room-types.ts << 'EOF'
// Room Management Types for MVP Implementation

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
  hostId: string;       // Creator sessionId
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
  roomId: string;      // NEW: Messages belong to rooms
  user: string;
  text: string;
  timestamp: number;
  sessionId: string;
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

// Room ID generation (MVP.md style: "quiet-sun-5821")
export function generateRoomId(): string {
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
  const number = Math.floor(Math.random() * 9000) + 1000; // 1000-9999
  
  return `${adjective}-${noun}-${number}`;
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

echo "✅ Room types created at backend/src/room-types.ts"

# Create room service
echo "📝 Creating room service..."
cat > backend/src/room-service.ts << 'EOF'
// Room Management Service for MVP Implementation

import { 
  Room, 
  Participant, 
  RoomMessage,
  CreateRoomRequest, 
  JoinRoomRequest,
  generateRoomId,
  validateRoomSettings
} from './room-types.js';

export class RoomService {
  private rooms = new Map<string, Room>();
  private cleanupInterval: NodeJS.Timeout;
  
  constructor() {
    // Auto-cleanup expired rooms every minute (per MVP.md)
    this.cleanupInterval = setInterval(() => {
      this.cleanupExpiredRooms();
    }, 60_000);
  }
  
  // Create new room (MVP.md: instant room creation)
  createRoom(request: CreateRoomRequest, hostSessionId: string): { room: Room; roomLink: string } {
    const errors = validateRoomSettings(request);
    if (errors.length > 0) {
      throw new Error(`Validation failed: ${errors.join(', ')}`);
    }
    
    const roomId = generateRoomId();
    const now = Date.now();
    const expiresAt = now + (request.duration * 60 * 1000); // Convert minutes to ms
    
    const host: Participant = {
      sessionId: hostSessionId,
      name: request.hostName,
      joinedAt: now,
      lastActivity: now,
      isHost: true
    };
    
    const room: Room = {
      id: roomId,
      name: request.name,
      hostId: hostSessionId,
      maxParticipants: request.maxParticipants,
      duration: request.duration,
      createdAt: now,
      expiresAt,
      participants: new Map([[hostSessionId, host]]),
      messages: [],
      isLocked: false,
      settings: {
        allowGuests: request.settings?.allowGuests ?? true,
        requireApproval: request.settings?.requireApproval ?? false,
        maxMessageLength: request.settings?.maxMessageLength ?? 500
      }
    };
    
    this.rooms.set(roomId, room);
    
    // Generate shareable link (MVP.md format)
    const roomLink = `/r/${roomId}`;
    
    console.log(`🏠 Room created: ${roomId} by ${request.hostName} (${request.duration}min)`);
    
    return { room, roomLink };
  }
  
  // Get room info (for join preview)
  getRoom(roomId: string): Room | null {
    return this.rooms.get(roomId) || null;
  }
  
  // Join existing room (MVP.md: join via link)
  joinRoom(request: JoinRoomRequest, sessionId: string): { success: boolean; error?: string; room?: Room } {
    const room = this.rooms.get(request.roomId);
    
    if (!room) {
      return { success: false, error: 'Room not found' };
    }
    
    if (Date.now() > room.expiresAt) {
      return { success: false, error: 'Room has expired' };
    }
    
    if (room.isLocked) {
      return { success: false, error: 'Room is locked' };
    }
    
    if (room.participants.size >= room.maxParticipants) {
      return { success: false, error: 'Room is full' };
    }
    
    if (room.participants.has(sessionId)) {
      return { success: false, error: 'Already in room' };
    }
    
    const participant: Participant = {
      sessionId,
      name: request.participantName,
      joinedAt: Date.now(),
      lastActivity: Date.now(),
      isHost: false
    };
    
    room.participants.set(sessionId, participant);
    
    console.log(`👋 ${request.participantName} joined room ${request.roomId}`);
    
    return { success: true, room };
  }
  
  // Leave room
  leaveRoom(roomId: string, sessionId: string): boolean {
    const room = this.rooms.get(roomId);
    if (!room) return false;
    
    const participant = room.participants.get(sessionId);
    if (!participant) return false;
    
    room.participants.delete(sessionId);
    
    console.log(`👋 ${participant.name} left room ${roomId}`);
    
    // If host left or room empty, destroy room
    if (participant.isHost || room.participants.size === 0) {
      this.destroyRoom(roomId);
      return true;
    }
    
    return true;
  }
  
  // Add message to room
  addMessage(roomId: string, sessionId: string, text: string): RoomMessage | null {
    const room = this.rooms.get(roomId);
    if (!room) return null;
    
    const participant = room.participants.get(sessionId);
    if (!participant) return null;
    
    // Update activity
    participant.lastActivity = Date.now();
    
    const message: RoomMessage = {
      id: `msg-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
      roomId,
      user: participant.name,
      text: text.substring(0, room.settings.maxMessageLength),
      timestamp: Date.now(),
      sessionId
    };
    
    room.messages.push(message);
    
    // Keep only last 100 messages per room (MVP constraint)
    if (room.messages.length > 100) {
      room.messages = room.messages.slice(-100);
    }
    
    return message;
  }
  
  // Get room messages
  getRoomMessages(roomId: string, sessionId: string): RoomMessage[] {
    const room = this.rooms.get(roomId);
    if (!room) return [];
    
    // Only participants can see messages
    if (!room.participants.has(sessionId)) return [];
    
    return room.messages;
  }
  
  // Get room participants
  getRoomParticipants(roomId: string): Participant[] {
    const room = this.rooms.get(roomId);
    if (!room) return [];
    
    return Array.from(room.participants.values());
  }
  
  // Host controls: Lock room
  lockRoom(roomId: string, hostSessionId: string): boolean {
    const room = this.rooms.get(roomId);
    if (!room || room.hostId !== hostSessionId) return false;
    
    room.isLocked = true;
    return true;
  }
  
  // Host controls: Kick participant  
  kickParticipant(roomId: string, hostSessionId: string, targetSessionId: string): boolean {
    const room = this.rooms.get(roomId);
    if (!room || room.hostId !== hostSessionId) return false;
    
    const target = room.participants.get(targetSessionId);
    if (!target || target.isHost) return false; // Can't kick host
    
    room.participants.delete(targetSessionId);
    console.log(`🚫 ${target.name} was kicked from room ${roomId}`);
    
    return true;
  }
  
  // Cleanup expired rooms (MVP.md: auto-expire)
  private cleanupExpiredRooms(): void {
    const now = Date.now();
    let cleanedCount = 0;
    
    for (const [roomId, room] of this.rooms) {
      if (now > room.expiresAt) {
        this.destroyRoom(roomId);
        cleanedCount++;
      }
    }
    
    if (cleanedCount > 0) {
      console.log(`🧹 Cleaned up ${cleanedCount} expired rooms`);
    }
  }
  
  // Destroy room completely
  private destroyRoom(roomId: string): void {
    const room = this.rooms.get(roomId);
    if (room) {
      console.log(`💥 Room ${roomId} destroyed (${room.participants.size} participants)`);
      this.rooms.delete(roomId);
    }
  }
  
  // Stats for monitoring
  getStats() {
    const totalRooms = this.rooms.size;
    const totalParticipants = Array.from(this.rooms.values())
      .reduce((sum, room) => sum + room.participants.size, 0);
    
    return {
      totalRooms,
      totalParticipants,
      rooms: Array.from(this.rooms.values()).map(room => ({
        id: room.id,
        name: room.name,
        participants: room.participants.size,
        duration: room.duration,
        expiresIn: Math.max(0, room.expiresAt - Date.now())
      }))
    };
  }
  
  // Cleanup on shutdown
  destroy(): void {
    if (this.cleanupInterval) {
      clearInterval(this.cleanupInterval);
    }
  }
}

// Singleton instance
export const roomService = new RoomService();
EOF

echo "✅ Room service created at backend/src/room-service.ts"

# Backup and preparation complete
echo ""
echo "✅ STEG 1 FOUNDATION COMPLETED!"
echo "📦 Backup created: backend/src.backup.$(date +%Y%m%d_%H%M%S)"
echo "📝 New files created:"
echo "   - backend/src/room-types.ts (Room interfaces & validation)"
echo "   - backend/src/room-service.ts (Room management logic)"
echo ""
echo "🎯 NEXT STEPS:"
echo "   1. Review the new files"  
echo "   2. Run: npm run build in backend/ to verify TypeScript"
echo "   3. Ready for STEG 2: API endpoints integration"
echo ""
echo "⚠️  IMPORTANT: Current chat still works - no breaking changes!"