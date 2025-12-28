# Mugharred - Instant Rooms Platform

**Live at:** https://mugharred.se  
**Status:** 🚀 Phase 1 MVP Complete - Production Ready! (December 27, 2024)

## What is Mugharred?

Instant rooms for everything. Create a room, share a link, start talking.

- **No signup required** - Just enter your name
- **Privacy-first** - Rooms auto-expire, no permanent storage
- **Zero friction** - Works in any browser instantly
- **Enterprise security** - JWT tokens, Redis persistence

## Architecture

- **Backend:** Node.js + Express + JWT + Redis + WebSocket
- **Frontend:** React + TypeScript + Tailwind CSS
- **Authentication:** Stateless JWT tokens
- **Storage:** Redis for room persistence
- **Communication:** WebSocket for real-time

## Quick Start

### Development
```bash
# Clone and install
git clone https://github.com/user/mugharred.git
cd mugharred

# Backend
cd backend
npm install
npm run dev  # Port 3010

# Frontend  
cd frontend
npm install
npm run dev  # Port 5173
```

### Production
```bash
# Build and deploy
npm run build  # Both backend and frontend
sudo cp -r frontend/dist/* /var/www/html/
node backend/dist/server.js
```

## Features

### Phase 1 - MVP Complete! ✅
- ✅ Instant room creation with auto-generated IDs
- ✅ Share room links (copy/share buttons)
- ✅ Real-time bidirectional chat
- ✅ Online users list with names
- ✅ Auto-expiring rooms (15/30/60/120 min)
- ✅ JWT stateless authentication
- ✅ Redis persistence with TTL
- ✅ Mobile-responsive design
- ✅ WebSocket real-time communication
- ✅ Enterprise-grade security

### Phase 2 - Media (Next)
- 🔄 Voice/video calling (WebRTC P2P)
- 🔄 Host controls (kick, mute, extend time, lock room)
- 🔄 Screen sharing
- 🔄 Audio-only mode

### Phase 3 - Enhanced Features
- 🔄 Room templates (Interview, Planning, Study)
- 🔄 Link previews (safe image sharing)
- 🔄 Pin important messages
- 🔄 Vote-to-kick mechanism

## Documentation

- **[MVP.md](docs/MVP.md)** - Product specification
- **[TECHNICAL.md](docs/TECHNICAL.md)** - Technical implementation
- **[DEPLOYMENT.md](docs/DEPLOYMENT.md)** - Deployment guide
- **[PROJECT-STRUCTURE.md](docs/PROJECT-STRUCTURE.md)** - Code structure

## Project Structure

```
mugharred/
├── backend/          # JWT + Redis backend (port 3010)
├── frontend/         # React frontend  
├── scripts/          # Deployment scripts
├── docs/            # Documentation
└── goldenrules.md   # Development guidelines
```

## Development Rules

This project follows **goldenrules.md**:
- Single source of truth for each component
- Script-driven changes only
- No backups, duplicates, or alternative versions
- Clean canonical structure

## Security

- JWT stateless authentication
- Input validation and sanitization
- XSS protection with DOMPurify
- Rate limiting and auto-cleanup
- HTTPS only in production
- Redis security configuration

## API Endpoints

### Authentication
- `POST /api/login` - Get JWT token
- `POST /api/refresh-token` - Refresh JWT

### Rooms  
- `POST /api/create-room` - Create new room
- `POST /api/join-room` - Join existing room
- `GET /api/room/:id` - Get room info

### WebSocket
- `WS /ws?token=<jwt>` - Real-time communication

## Contributing

1. Read **goldenrules.md** first
2. Follow canonical structure principles
3. Use scripts in `/scripts/` for changes
4. Update documentation in `/docs/`

## License

Private project - All rights reserved

## Support

For technical issues, check:
- **Health endpoint:** https://mugharred.se/api/health
- **Logs:** Backend Winston logs
- **Documentation:** `/docs/` directory