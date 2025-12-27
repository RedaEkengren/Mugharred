# Mugharred MVP Specification

Minimal Viable Product specification for Mugharred - Instant Rooms for Everything.

## Vision: Global Instant Rooms Platform

Mugharred is a primitive that can be used for anything - not a niche app. 
**Core koncept**: Instant rooms → share link → join → talk → leave → room expires

## MVP Core Principles

1. **No accounts required** to join (but host can have account)
2. **Privacy-first**: no ads, no tracking, minimal logging
3. **One link = one room** (zero friction)
4. **Neutral space** - for everything from planning to interviews to study sessions

## What is the MVP?

A fully functional instant rooms platform that demonstrates:
- Simplicity over complexity  
- Real-time over optimization
- Enterprise-grade security
- Instant rooms for all use cases
- Automatic room management with time limits

## MVP v1.0 Roadmap - Instant Rooms

### Phase 1: Core Room System (Current → MVP)
Transform current open chat into instant rooms system:

1. **Create Room Flow**
   - Big CTA: "Create a room" 
   - Room settings: name, duration (15/30/60/120 min), max participants (2-12)
   - Auto-generated room link: `mugharred.se/r/quiet-sun-5821`
   - No signup required for room creator (light identity)

2. **Join Room Flow**
   - Open link → Enter display name → Join
   - See who's in the room before joining
   - No accounts, no friction

3. **Room Features**
   - Timer countdown (visible to all)
   - Text chat (current implementation)
   - Voice/Video toggles (WebRTC P2P for 2-4 people)
   - Host controls: kick, mute, extend time, lock room
   - Auto-expire: room destroyed when time ends

4. **Privacy & Safety**
   - Vote-to-kick (host + 1)
   - Report button
   - Block in room (local)
   - Rate limiting on joins
   - No message history after room expires

### Phase 2: Enhanced Communication (v1.1)
5. **WebRTC Integration**
   - Voice chat with push-to-talk option
   - Video with cam on/off toggle
   - Mute by default option
   - P2P for small rooms (2-4), consider SFU for larger

6. **Room Roles**
   - Host (creator) with admin powers
   - Speaker/Listener modes for presentations
   - Lobby mode (host approves joins)

7. **Share & Invite**
   - Copy link button
   - Optional passcode
   - Share to social/messaging apps

### Phase 3: Light Features (v1.2)
8. **Templates**
   - Pre-configured room types: Interview, Planning, Study Session
   - Just presets, not different products

9. **Link Sharing & Preview**
   - Safe link preview for images
   - Pin important messages
   - NO file uploads in MVP (legal/abuse risks)

10. **Monetization (Optional)**
    - Free: 30-60 min rooms, max 4 video participants
    - Supporter (€5/mo): longer rooms, more participants, passcode protection

## Landing Page Copy

**Hero Section:**
```
Create a room
No signup. No downloads. Just a link.

Instant Rooms for → Planning → Interviews → Study Sessions → Customer Calls → Hangouts
(rotating text animation)
```

## Technical Architecture for Instant Rooms

### Current Stack (Keep)
- Frontend: React + TypeScript + Tailwind
- Backend: Node.js + Express + WebSocket
- Security: Redis sessions, CSRF, rate limiting
- Deployment: PM2 + Nginx

### New Components Needed
- Room management service
- WebRTC signaling 
- Timer/expiry system
- Room state in Redis (temporary)

### Scaling Strategy
- Start with P2P WebRTC (light on server)
- Add SFU later if needed (LiveKit/mediasoup)
- Keep text chat as primary (low bandwidth)
- Video as optional enhancement

## Smart MVP Prioritization

### Do First (Sprint 1 - Core "Wow") - ✅ 95% COMPLETE

**IMPLEMENTERAT (2024-12-27):**
1. ✅ Room creation modal på landing page
2. ✅ **API endpoints** - Full room management API (RESTORED) 
3. ✅ **Join room flow** - /r/room-id routing implementerat
4. ✅ **Room-First Onboarding** - No global chat, create room includes login
5. ✅ **Room chat interface** - Reuses existing chat for rooms
6. ✅ **Share functionality** - Copy link / native share buttons
7. ✅ **Auto-expire** - 60s cleanup i RoomService
8. ✅ **Backend stability** - Fixed import errors, clean build process

**KVAR ATT GÖRA - CRITICAL BUGS:**
- 🔲 **Room messaging broken** - Isabelle kan inte skriva meddelanden i rum
- 🔲 **TypeScript compile errors** - Duplicate functions i room-service.ts  
- 🔲 **Room-specific chat** - Meddelanden går till global istället för rum-specifikt
- 🔲 **WebSocket room support** - roomId parameter används inte korrekt för messaging

**IMMEDIATE FIXES NEEDED:**
1. Fix TypeScript compilation errors i backend
2. Fix room messaging så båda användare kan chatta i samma rum
3. Separera room messages från global messages
4. Test complete room creation → join → chat flow

**NÄSTA STEG:**
- Implementera Room-First onboarding enligt Option 1
- Ta bort global chat helt
- Återanvänd chat-kod för room-specifik chat

### Do Second (Sprint 2 - Media)
🔲 Voice/video with mic/cam toggles
🔲 Basic grid UI for video
🔲 P2P WebRTC (max 4 people)
🔲 Audio-only fallback for larger rooms

### Do Third (Sprint 3 - Safety)
🔲 Vote-to-kick mechanism
🔲 Report/block functionality
🔲 Lobby mode for host control
🔲 Rate limiting refinements

## Critical Decisions

### What NOT to Build (MVP)
❌ **NO file uploads** - Legal nightmares, abuse, storage costs
❌ **NO permanent accounts** - Keep it instant
❌ **NO message history** - Privacy first, no archives
❌ **NO DMs** - All communication in room (safer)
❌ **NO complex moderation** - Just kick/block/report

### Smart Alternatives
✅ Link sharing with preview (let others host files)
✅ Suggest Catbox/Drive/Dropbox for file needs
✅ Pin important messages temporarily
✅ Text snippets/code blocks instead of files

## Server Load Considerations

### P2P WebRTC (Recommended Start)
- Server load: Minimal (just signaling)
- User bandwidth: Each sends to all others
- Works well: 2-4 people
- Falls apart: 5+ people

### If You Need SFU Later
- Consider LiveKit (easiest) or mediasoup
- Only for "large rooms" or paid tiers
- Keep P2P for small rooms (cost optimization)

### Bandwidth Optimization Tips
- Default to audio-only
- Low video quality to start
- Auto-disable video when tab backgrounded
- Hard participant limits per room

## Why This Works (Philosophy)

### For Users
- **Zero friction** - No signup fatigue
- **No social pressure** - Not another social network
- **No permanence anxiety** - Everything disappears
- **No app install** - Works everywhere instantly

### For You (Developer)
- **Low cost** - Minimal server resources with P2P
- **Low legal risk** - No stored content, no moderation burden
- **Simple scaling** - Just add more signaling capacity
- **Clear mental model** - Rooms expire, period

### Market Fit
- ✅ **Simple** enough for grandparents
- ✅ **Flexible** enough for any use case  
- ✅ **Private** enough for sensitive conversations
- ✅ **Temporary** enough to feel safe
- ✅ **Global** - Works for any culture/language

## The Magic: It's NOT Another Platform

Mugharred is infrastructure, not destination.
Like a park bench - you use it, then leave.
No profiles. No feeds. No FOMO.
Just human connection when needed.

## Success Metrics for MVP

1. **Time to first room**: < 10 seconds
2. **Join friction**: 1 click + name
3. **Server cost per room**: < €0.01
4. **Abuse reports**: < 1%
5. **Natural growth**: Users create multiple rooms

## Final Note: Keep It Pure

The biggest risk is feature creep.
Every feature ask yourself:
"Does this make rooms better in the first 10 seconds?"
If no → skip it.

**Remember**: You're building digital park benches, not digital real estate.

