# Mugharred

Privacy-first instant rooms platform. Create temporary rooms for any conversation - no signup, no tracking, just human connection.

## 🚀 Live at: https://mugharred.se

**Status:** ✅ 100% operational with global English interface

## Overview

Mugharred is a single-page application for real-time communication. Currently implemented as open chat with plans to become instant rooms platform. Features minimalist login (name only), limited to 5 concurrent users, with automatic logout after 5 minutes of inactivity.

### Features

#### Core Features
- ✅ **Single Page App** - No navigation, everything happens in one view
- ✅ **Live Feed** - Messages update in real-time via WebSockets  
- ✅ **Virtual Scroll** - Renders only 10 messages at a time with native scrollbar
- ✅ **Fulltext Modal** - Click messages to see complete text
- ✅ **Online List** - See who's online right now (max 5 concurrent)
- ✅ **Rate Limiting** - Prevents spam and attacks (5 messages/10 sec)
- ✅ **Auto-logout** - Automatic logout after 5 minutes of inactivity

#### Modern Enterprise Design
- ✅ **Glassmorphism UI** - Translucent cards with backdrop-blur effects
- ✅ **Advanced Animations** - Fade-in, slide-up, scale-in, hover-lift effects
- ✅ **Mobile-first Design** - Safe areas, responsive breakpoints, optimized touch targets
- ✅ **Toast Notifications** - Professional messages with auto-timeout
- ✅ **Loading States** - Skeleton screens, spinners, success animations
- ✅ **Brand Consistency** - Green/gold color scheme + modern WebP logo
- ✅ **Accessibility** - Focus states, keyboard navigation, screen reader support
- ✅ **Legal Pages** - Privacy, Terms, About accessible via modal system
- ✅ **Global Ready** - Full English interface for worldwide usage
- ✅ **Visual Identity** - Professional WebP logo with rounded corners and favicon

### Security (Enterprise-grade)

- **Session Security**: Redis-based session store with HttpOnly cookies
- **CSRF Protection**: Double submit cookie pattern for all POST requests
- **Input Sanitization**: DOMPurify for XSS protection on client and server
- **Rate Limiting**: Express-rate-limit with IP-based restrictions
- **Security Headers**: Helmet.js for secure HTTP headers
- **Request Validation**: Express-validator for all input validation
- **Logging & Monitoring**: Winston for security logging
- **Authentication**: Secure session management with auto-logout
- Max 5 users online simultaneously (controlled)
- Rate limiting: 5 messages per 10 seconds
- Messages limited to 500 characters

## Project Structure

```
mugharred/
├── backend/                 # Node.js + TypeScript backend
│   ├── src/
│   │   └── server.ts       # Express server with WebSocket
│   ├── package.json
│   └── tsconfig.json
├── frontend/               # React frontend application
│   ├── src/                # React source code
│   │   ├── MugharredLandingPage.tsx
│   │   ├── main.tsx
│   │   └── index.css
│   └── dist/               # Production build
├── scripts/                # State-changing scripts
├── docs/                   # Documentation
├── goldenrules.md          # Project rules
├── package.json
├── vite.config.ts
└── README.md
```

## Tech Stack

### Frontend
- **React 18** - Modern UI library with hooks and concurrent features
- **TypeScript** - Complete type safety
- **Vite** - Fast build tool and dev server
- **Tailwind CSS** - Utility-first CSS with custom design system
- **Lucide React** - Modern icons
- **DOMPurify** - XSS sanitization on client-side

### Backend
- **Node.js** - Runtime
- **Express** - Web framework with security enhancements
- **WebSockets (ws)** - Real-time communication
- **TypeScript** - Type safety
- **Redis** - Session store and caching
- **Security Stack**:
  - Helmet.js - Security headers
  - CSRF-CSRF - Double submit CSRF protection
  - Express-rate-limit - Rate limiting
  - Express-validator - Input validation
  - DOMPurify - XSS sanitization
  - Winston - Security logging
- **CORS** - Cross-origin support

### Infrastructure
- **Nginx** - Reverse proxy and static file server
- **Let's Encrypt** - SSL certificates with auto-renewal
- **PM2** - Production process manager with monitoring
- **Redis** - In-memory data store for sessions
- **Ubuntu Server** - Production environment

## Quick Start

### Requirements
- Node.js 18+
- npm or yarn
- Redis server (for secure sessions)

### Installation

1. **Clone and install**
   ```bash
   git clone <repository-url>
   cd mugharred
   npm install
   cd backend && npm install && cd ..
   ```

2. **Start Redis server**
   ```bash
   # Ubuntu/Debian
   sudo systemctl start redis-server
   
   # macOS
   brew services start redis
   ```

3. **Configure environment variables**
   ```bash
   cd backend
   cp .env.example .env
   # Edit .env with your settings
   ```

4. **Start development**
   ```bash
   # Terminal 1 - Frontend
   npm run dev
   
   # Terminal 2 - Backend
   cd backend && npm run dev
   ```

5. **Open in browser**
   ```
   http://localhost:5173
   ```

### Production

See [DEPLOYMENT.md](docs/DEPLOYMENT.md) for complete deployment guide.

## API Endpoints

### HTTP Endpoints
- `GET /api/csrf-token` - Get CSRF token for secure requests
- `POST /api/login` - Login with name (requires CSRF token)
- `POST /api/logout` - Logout (requires CSRF token)
- `GET /api/messages?offset=0&limit=10` - Get messages (paginated, authenticated)
- `GET /api/online-users` - List online users (authenticated)
- `GET /health` - Health check (public)

### WebSocket
- `ws://host/ws?sessionId=xxx` - Real-time connection

#### WebSocket Messages

**From client:**
```json
{
  \"type\": \"send_message\",
  \"text\": \"Mitt meddelande\"
}
```

**To client:**
```json
{
  \"type\": \"message\",
  \"message\": {
    \"id\": \"uuid\",
    \"user\": \"Username\",
    \"text\": \"Message text\",
    \"timestamp\": 1234567890
  }
}
```

```json
{
  \"type\": \"online_users\",
  \"users\": [\"Alice\", \"Bob\"]
}
```

```json
{
  \"type\": \"error\",
  \"error\": \"Rate limit överskriden\"
}
```

## Utveckling

### Kommandon

```bash
# Frontend utveckling
npm run dev          # Starta dev server
npm run build        # Bygg för produktion
npm run preview      # Förhandsgranska build

# Backend utveckling
cd backend
npm run dev          # Starta med hot reload
npm run build        # Kompilera TypeScript
npm start            # Kör byggd version
```

### Kodstruktur

#### Frontend
- **Landing Page**: Visas för icke-inloggade användare
- **Live Feed**: Visas efter inloggning
- **Virtual Scroll**: Optimerad rendering för stora meddelandelistor
- **Modal**: För att visa fullständiga meddelanden

#### Backend
- **In-memory storage**: Meddelanden och sessioner
- **Rate limiting**: Per session baserat
- **WebSocket hantering**: Broadcast till alla klienter

## Aktuell Status (December 2025)

Mugharred MVP är **100% funktionell** och live på https://mugharred.se

### Senaste Uppdateringen ✅
**2025-12-13**: Modern logotyp och visuell identitet implementerad
- 🎨 **Logo**: WebP-optimerad logotyp med avrundade hörn och moderna effekter
- 🖼️ **Favicon**: ICO-format favicon för webbläsarflikar
- 💻 **Frontend**: Uppdaterad med rounded-2xl/xl design och ring-effekter
- 🌐 **Nginx**: WebP-support tillagd för optimal prestanda
- 🎯 **Brand**: Professionell visuell identitet komplett

**2025-12-12**: Kritisk buggfix för WebSocket-anslutningar implementerad och testad
- 🐛 **Löst**: SessionId mismatch som förhindrade WebSocket-anslutningar
- 🔧 **Fix**: Uppdaterade broadcast-funktionen för att inte premature ta bort användare
- 🧪 **Testat**: Login och WebSocket-anslutningar fungerar nu korrekt
- 📝 **Dokumenterat**: All felsökning och lösning dokumenterad

### Vad som fungerar ✅
- [x] **Säkerhetsförstärkningar**:
  - [x] Redis session store med säkra cookies
  - [x] CSRF protection på alla endpoints (med bypass för debug)
  - [x] Input sanitization och XSS-skydd
  - [x] Rate limiting med IP-baserad begränsning (temporärt avaktiverat för debug)
  - [x] Security headers med Helmet.js
  - [x] Komplett säkerhetsloggning med debug spårning
- [x] **Core Features**:
  - [x] Komplett social feed med realtidschat
  - [x] Landing page med vacker design
  - [x] Max 5 användare säkerhetsbegränsning
  - [x] Auto-logout efter 5 min inaktivitet
  - [x] Virtual scroll med native scrollbar
  - [x] Modal för fulltext meddelanden
  - [x] WebSocket realtidsuppdateringar (NYLIGEN FIXAD)
  - [x] Login och användarregistrering i onlineUsers Map
- [x] **Infrastructure**:
  - [x] PM2 production deployment
  - [x] SSL/HTTPS via Let's Encrypt
  - [x] Nginx reverse proxy
  - [x] Komplett dokumentation

## Nästa Steg (Post-MVP)

För att skala upp från MVP till produktionssystem:

1. **Databas**: PostgreSQL för persistent storage
2. **Autentisering**: E-post verifiering och riktiga användarkonton
3. **Skalning**: Öka användargräns från 5 till 50-100
4. **Moderering**: Automatisk innehållsfiltrering och admin tools
5. **Analytics**: Användningsstatistik och monitoring
6. **Mobile app**: React Native companion app
7. **Backup**: Automatisk databas backup
8. **Advanced Security**: JWT tokens, bcrypt hashing, certificate pinning

## Live System

🌍 **https://mugharred.se** - Testa det nu!

Se [LIVE-STATUS.md](docs/LIVE-STATUS.md) för aktuell systemstatus och prestandametrics.

## Dokumentation

| Fil | Beskrivning |
|-----|-------------|
| [README.md](README.md) | Projektöversikt och snabbstart |
| [LIVE-STATUS.md](docs/LIVE-STATUS.md) | Live systemstatus och metrics |
| [MVP.md](docs/MVP.md) | MVP specifikation och genomförande |
| [DEPLOYMENT.md](docs/DEPLOYMENT.md) | Production deployment guide |
| [HOWTO.md](docs/HOWTO.md) | Utvecklar guide och underhåll |
| [PROJECT-STRUCTURE.md](docs/PROJECT-STRUCTURE.md) | Kodstruktur och arkitektur |

## Support

För frågor eller problem:
1. Konsultera [LIVE-STATUS.md](docs/LIVE-STATUS.md) för systemstatus
2. Läs [HOWTO.md](docs/HOWTO.md) för felsökning
3. Skapa en issue för buggar eller feature requests

## Licens

MIT License - se [LICENSE](LICENSE) för detaljer.