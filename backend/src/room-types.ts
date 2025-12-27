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
