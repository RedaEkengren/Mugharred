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
  
  // Get room by ID
  getRoom(roomId: string): Room | undefined {
    return this.rooms.get(roomId);
  }

  // Add message to room
  addMessage(roomId: string, message: any): void {
    const room = this.rooms.get(roomId);
    if (!room) {
      throw new Error(`Room ${roomId} not found`);
    }
    
    const roomMessage: RoomMessage = {
      id: message.id,
      user: message.user,
      text: message.text,
      timestamp: message.timestamp,
      roomId: roomId
    };
    
    room.messages.push(roomMessage);
    
    // Limit message history per room
    if (room.messages.length > 1000) {
      room.messages.splice(0, 100); // Remove oldest 100 messages
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
