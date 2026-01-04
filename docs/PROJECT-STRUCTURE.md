# Project Structure

**Current Status:** ✅ Canonical structure fully cleaned (December 28, 2024)

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
├── scripts/                    # Deployment & maintenance scripts
│   ├── cleanup-canonical.sh   # Structure cleanup
│   ├── cleanup-duplicates.sh  # Remove backup files  
│   ├── complete-cleanup.sh    # Complete cleanup
│   └── deploy-favicon-update.sh # Favicon deployment
├── docs/                       # Documentation
│   ├── MVP.md                 # Product specification
│   ├── TECHNICAL.md           # Technical details
│   ├── DEPLOYMENT.md          # Deploy instructions
│   ├── PROJECT-STRUCTURE.md   # This file
│   ├── CHANGELOG.md           # Version history
│   ├── HOWTO.md              # How-to guides
│   └── LIVE-STATUS.md        # Live system status
├── logs/                      # Application logs
│   ├── combined.log          # All logs
│   └── error.log             # Error logs only
├── goldenrules.md             # Development rules (MANDATORY)
├── CHANGELOG.md              # Version history (root)
└── README.md                 # Project overview
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
- **Voice (in transition)**: P2P WebRTC → Janus Gateway

### Frontend
- JWT wrapper intercepts API calls
- Room-based architecture
- WebSocket integration with JWT tokens
- Clean build deployment
- **Voice UI**: VoiceControls.tsx (keeping)
- **Voice Logic**: useWebRTC.ts (removing) → Janus client

## Voice Implementation Status (December 30, 2024 - 95% COMPLETE)

**✅ JANUS GATEWAY INTEGRATION COMPLETED**

**Completed Changes:**
- ✅ All P2P WebRTC code REMOVED (mostly)
- ✅ Janus Gateway 1.4.0 installed and running on PM2
- ✅ `frontend/src/useJanusVoice.ts` - NEW Janus hook created
- ✅ Frontend deployed with Janus integration
- ✅ Janus JavaScript library loading from CDN
- ✅ SDP generation FIXED with proper media configuration

**🔴 LAST REMAINING ISSUE:** STUN server not configured
**Error:** "ICE failed for component 1 in stream 1"
**Fix:** Enable STUN in `/usr/local/etc/janus/janus.jcfg`

**FILES TO REMOVE IMMEDIATELY:**
```bash
# OLD P2P FILES STILL PRESENT - REMOVE THESE:
rm -f /home/reda/development/mugharred/frontend/src/useWebRTC.ts
rm -f /home/reda/development/mugharred/backend/src/webrtc-signaling.ts
```

**ACTIVE VOICE FILES:**
- ✅ `frontend/src/VoiceControls.tsx` - Voice UI components
- ✅ `frontend/src/useJanusVoice.ts` - Janus implementation
- ✅ `/usr/local/etc/janus/janus.jcfg` - Needs STUN config
- ✅ PM2 process: `mugharred-janus` - Running

**CRITICAL FIX NEEDED:**
```bash
# Edit Janus config and uncomment STUN server
sudo nano /usr/local/etc/janus/janus.jcfg
# Line 290: stun_server = "stun.l.google.com"
# Line 291: stun_port = 19302
# Line 295: ice_consent_freshness = true
```

## Cleanup History

**Removed chaos (December 28, 2024):**
- ❌ `integration-backup-1766875262/` - backup directory
- ❌ `frontend/src.backup.1766873629/` - backup directory  
- ❌ `*.backup.*` files - backup files
- ❌ `*.tmp` files - temporary files
- ❌ `*.old` files - old versions

**Previous chaos (December 27, 2024):**
- ❌ 30+ redundant scripts
- ❌ Multiple server versions (server.ts, server-jwt.ts, server-stateless.ts)
- ❌ Mixed authentication systems

**Result:** ✅ Clean canonical structure per goldenrules.md

## Compliance Verification

Run this to verify clean structure:
```bash
find . -name "*.backup.*" -o -name "*.tmp" -o -name "*.old" | grep -v node_modules
# Should return empty (no results)
```

**GitHub Integration:** All code versions safely stored in version control.