# Project Structure

**Current Status:** Canonical structure established (December 27, 2024)

## Directory Structure

```
mugharred/
├── backend/                    # JWT + Redis stateless backend
│   ├── src/
│   │   ├── server.ts          # Main server (JWT + Redis + WebSocket)
│   │   ├── jwt-auth.ts        # JWT authentication
│   │   ├── jwt-middleware.ts  # JWT middleware
│   │   ├── redis-room-service.ts # Room management
│   │   ├── websocket-service.ts  # WebSocket handling
│   │   ├── room-types.ts      # Type definitions
│   │   └── types.ts           # General types
│   ├── package.json
│   └── tsconfig.json
├── frontend/                   # React + TypeScript frontend
│   ├── src/
│   │   ├── MugharredLandingPage.tsx # Main component
│   │   ├── jwt-wrapper.ts     # JWT integration layer
│   │   ├── main.tsx           # Entry point
│   │   └── index.css          # Styles
│   ├── package.json
│   └── vite.config.ts
├── scripts/                    # Deployment scripts
│   ├── cleanup-canonical.sh   # Structure cleanup
│   └── complete-cleanup.sh    # Complete cleanup
├── docs/                       # Documentation
│   ├── MVP.md                 # Product specification
│   ├── TECHNICAL.md           # Technical details
│   ├── DEPLOYMENT.md          # Deploy instructions
│   └── PROJECT-STRUCTURE.md   # This file
├── goldenrules.md             # Development rules
└── README.md                  # Project overview
```

## Key Principles

1. **Single Source of Truth:** One canonical file per function
2. **No Redundancy:** No backups, duplicates, or alternative versions
3. **Script-Driven:** All changes via scripts in `/scripts/`
4. **Clean Builds:** Always build from clean state

## Architecture

- **Authentication:** JWT tokens (stateless)
- **Storage:** Redis for room persistence
- **Communication:** WebSocket for real-time
- **Frontend:** React SPA with JWT integration
- **Deployment:** Direct to `/var/www/html/`
- **Port:** 3010 (JWT backend)

## Current Implementation

### Backend (Port 3010)
- JWT authentication with Redis room storage
- WebSocket service for real-time communication
- Room management with auto-expiry
- Stateless architecture

### Frontend
- JWT wrapper intercepts API calls
- Room-based architecture
- WebSocket integration with JWT tokens
- Clean build deployment

## Removed Chaos

Previously had:
- 30+ redundant scripts
- Multiple server versions (server.ts, server-jwt.ts, server-stateless.ts)
- Backup folders and duplicate files
- Mixed authentication systems

Now: Clean canonical structure per goldenrules.md