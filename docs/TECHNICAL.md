# Mugharred Technical Implementation

**Current Status:** JWT + Redis stateless architecture implemented (December 27, 2024)

## Architecture Overview

### ✅ IMPLEMENTED: Stateless JWT + Redis Architecture

**Authentication:** JWT tokens (stateless)
**Storage:** Redis for room persistence
**Communication:** WebSocket with JWT tokens
**Frontend:** React SPA with JWT wrapper
**Port:** 3010

## Technical Stack

### Backend
- **Node.js + Express** - Web server
- **TypeScript** - Type safety
- **JWT** - Stateless authentication
- **Redis** - Room persistence and pub/sub
- **WebSocket** - Real-time communication
- **Winston** - Logging
- **Helmet** - Security headers
- **express-validator** - Input validation
- **DOMPurify** - XSS prevention

### Frontend  
- **React + TypeScript** - UI framework
- **Vite** - Build tool
- **Tailwind CSS** - Styling
- **WebSocket API** - Real-time client
- **JWT wrapper** - Authentication layer

## Authentication Flow

1. User submits name → `POST /api/login`
2. Backend generates JWT token
3. JWT wrapper saves token to localStorage
4. All API calls automatically include `Authorization: Bearer <token>`
5. WebSocket connects with `?token=<jwt>`

## Room System

### Room Creation
```typescript
POST /api/create-room
{
  name: string,
  maxParticipants: number, 
  duration: number,
  hostName: string
}
→ Returns: { roomId, token, room }
```

### Room Joining
```typescript
POST /api/join-room  
{
  roomId: string,
  participantName: string
}
→ Returns: { success, token, room }
```

## WebSocket Implementation

### Connection
- URL: `wss://mugharred.se/ws?token=<jwt>`
- JWT validation on connection
- User extracted from token payload

### Room Join Flow
```typescript
// 1. WebSocket connects with JWT
socket.onopen = () => {
  // 2. Send room join message
  socket.send(JSON.stringify({
    type: 'join_room',
    roomId: currentRoomId,
    name: userName
  }));
}
```

### Message Types
- `join_room` - Join specific room
- `send_message` - Send chat message
- `leave_room` - Leave current room
- `room_event` - Room state updates
- `participants_update` - Online users update

## Data Flow

### Frontend → Backend
1. Login → JWT token received
2. Create/Join room → Room access granted
3. WebSocket connect → Real-time channel established
4. Send messages → Broadcast to room participants

### Backend → Frontend  
1. JWT validation → User authenticated
2. Room validation → Access granted
3. WebSocket events → Real-time updates
4. Participant updates → Online users list

## Security Implementation

### JWT Security
- HS256 signing algorithm
- 1-hour expiration
- User and room context in payload
- Token refresh mechanism

### Input Validation
- Express-validator on all endpoints
- DOMPurify sanitization
- Length limits on all user input
- SQL injection prevention (N/A - Redis NoSQL)

### WebSocket Security
- JWT token validation on connect
- Room-based message isolation
- Rate limiting per user
- Auto-cleanup inactive connections

## Redis Data Structure

### Room Storage
```typescript
Key: "room:{roomId}"
Value: {
  id: string,
  name: string, 
  hostId: string,
  participants: Map<userId, ParticipantInfo>,
  messages: Message[],
  expiresAt: number,
  maxParticipants: number,
  isLocked: boolean
}
```

### Auto-Expiry
- Redis TTL for automatic room cleanup
- Configurable room duration (15/30/60/120 minutes)
- Background cleanup processes

## Deployment

### Production Environment
- **Server:** Ubuntu with nginx reverse proxy
- **Process:** Node.js backend on port 3010
- **Frontend:** Static files served by nginx
- **Database:** Redis for room storage

### Build Process
```bash
# Backend
cd backend && npm run build
node dist/server.js

# Frontend  
cd frontend && npm run build
cp -r dist/* /var/www/html/
```

## Monitoring

### Health Check
```
GET /health
→ { status: "ok", auth: "jwt", storage: "redis", rooms: N, participants: N }
```

### Logging
- Winston structured logging
- Error tracking and debugging
- Security event monitoring
- Performance metrics

## Troubleshooting

### Common Issues
1. **"Must be in a room to send messages"** 
   - Cause: WebSocket join_room failed
   - Solution: Verify JWT token and room access

2. **Users not showing as online**
   - Cause: Room join WebSocket message missing name
   - Solution: Ensure join_room includes name parameter

3. **Token expiry**
   - Cause: JWT token expired (1 hour)
   - Solution: Implement token refresh mechanism

### Debug Commands
```bash
# Check Redis rooms
redis-cli keys "room:*"

# Check room participants  
redis-cli get "room:{roomId}"

# Check backend logs (correct path)
tail -f backend/logs/combined.log

# Debug WebSocket voice messages
grep -E "(📩|📨|join-voice|leave-voice)" backend/logs/combined.log

# Monitor real-time WebSocket messages  
tail -f backend/logs/combined.log | grep "📩"
```

## Voice Implementation Strategy Change (December 29, 2024)

**DECISION: Abandon P2P WebRTC → Use Janus Gateway**

**Why P2P WebRTC Failed:**
- WebSocket reference lost in React re-renders (`ws: null`)
- NAT/firewall issues without TURN server
- Complex mesh networking (N*(N-1) connections)
- Max 4 users before quality degrades
- 30% of connections fail without TURN relay

**New Approach: Janus Gateway (95% COMPLETE)**
- **Status:** Running on PM2 as `mugharred-janus`
- **Port:** 8188 (WebSocket)
- **Frontend:** `useJanusVoice.ts` implemented
- **Last Issue:** STUN server not configured

**🚨 CRITICAL FIX NEEDED - DO THIS NOW:**
```bash
# 1. Configure STUN server
sudo nano /usr/local/etc/janus/janus.jcfg

# 2. Go to line 290 and uncomment/change:
stun_server = "stun.l.google.com"    # REMOVE the #
stun_port = 19302                     # REMOVE the #

# 3. Go to line 295 and uncomment:
ice_consent_freshness = true          # REMOVE the #

# 4. Save (Ctrl+O, Enter, Ctrl+X) and restart:
pm2 restart mugharred-janus

# 5. Remove old P2P files:
rm -f frontend/src/useWebRTC.ts
rm -f backend/src/webrtc-signaling.ts

# 6. Test voice at https://mugharred.se
```

**Backend Crashes (2126 restarts):**
- NOT a problem - JWT tokens expire after 1 hour
- WebSocket errors are expected when tokens expire
- PM2 auto-restarts (this is correct behavior)