# Mugharred Project Structure

Overview of the project's file structure and organization.

**Live Production System at https://mugharred.se**

This document describes how the current live installation is organized.

## 🌍 Latest Update (2025-12-27)

**Global English Interface & Modal System Implemented:**
- ✅ **Feature**: Complete English translation for worldwide usage
- ✅ **Legal Pages**: Privacy, Terms, About now work as React modals instead of broken HTML files
- ✅ **Footer**: Professional footer with working benbo.se legal connections
- ✅ **Compliance**: Fixed Golden Rules violations by removing unauthorized HTML files
- ✅ **Result**: Global-ready platform with properly functioning legal page system

## Rot Nivå

```
mugharred/
├── 📁 backend/              # Secure Node.js backend server
├── 📁 docs/                 # Project documentation
├── 📁 frontend/             # Production frontend build
├── 📁 src/                  # Frontend source code (React + Security)
├── 📄 .gitignore           # Git ignore patterns
├── 📄 README.md            # Main documentation
├── 📄 package.json         # Frontend dependencies (incl. DOMPurify)
├── 📄 tsconfig.json        # TypeScript configuration (frontend)
├── 📄 tailwind.config.js   # Tailwind CSS configuration
├── 📄 postcss.config.js    # PostCSS configuration
├── 📄 vite.config.ts       # Vite build tool configuration
└── 📄 index.html           # HTML template for SPA
```

## Backend (`/backend/`)

```
backend/
├── 📁 src/                  # Säker TypeScript källkod
│   ├── 📄 server.ts         # Säker server (Express + WebSocket + Security)
│   └── 📄 types.ts          # TypeScript definitioner
├── 📁 dist/                 # Kompilerad JavaScript (genererad)
├── 📁 logs/                 # Winston säkerhetsloggar
│   ├── 📄 combined.log      # Alla händelser
│   └── 📄 error.log         # Endast fel
├── 📄 package.json          # Backend dependencies (Security stack)
├── 📄 tsconfig.json         # TypeScript config för backend
├── 📄 .env                  # Environment variabler (SECRETS)
└── 📄 .env.example          # Environment mall
```

### Backend Filer

#### `src/server.ts` (Enterprise-Grade Security)
- **Security Stack**: 
  - Helmet.js för säkra HTTP headers
  - CSRF-CSRF double submit cookie protection
  - Express-rate-limit med IP-baserad begränsning
  - Express-validator för input validation
  - DOMPurify för XSS sanitization
  - Winston för säkerhetsloggning
- **Session Management**: 
  - Redis store med connect-redis v7.1.1
  - HttpOnly cookies med SameSite=strict
  - 30-minuters session expiry
  - Säker cookie settings i production
- **Express server setup**:
  - Trust proxy för localhost (127.0.0.1)
  - CORS konfiguration för frontend
  - Environment-baserad konfiguration
- **WebSocket hantering**:
  - Session-baserad autentisering
  - Input sanitization på alla meddelanden
  - Heartbeat/keepalive system
  - Auto-cleanup av inaktiva connections
  - 🔧 **FIXAD**: broadcast() logic för korrekt user management
- **API endpoints** med full säkerhet:
  - `GET /api/csrf-token` - CSRF token generering
  - `POST /api/login` - Säker inloggning med rate limiting
  - `POST /api/logout` - Säker utloggning med session cleanup
  - `GET /api/messages` - Paginerade meddelanden (auth required)
  - `GET /api/online-users` - Online användarlista (auth required)
  - `GET /health` - System hälsokontroll
- **Advanced Security Features**:
  - Auto-logout efter 5 minuters inaktivitet
  - Max 5 concurrent users (hårdkodad säkerhet)
  - Message rate limiting (5 msgs/10 sekunder)
  - All input/output sanitization med DOMPurify
  - Security logging för alla crítica events

#### `package.json`
```json
{
  "scripts": {
    "dev": "tsx watch src/server.ts",    // Dev server med hot reload
    "build": "tsc",                      // Kompilera TypeScript
    "start": "node dist/server.js"      // Kör production build
  }
}
```

## Frontend (`/src/`)

```
src/
├── 📄 main.tsx                    # React app entry point
├── 📄 MugharredLandingPage.tsx    # Huvud React komponent
└── 📄 index.css                   # Tailwind CSS imports
```

### Frontend Filer

#### `main.tsx`
- React app bootstrap
- DOM mounting
- Strict mode wrapper

#### `MugharredLandingPage.tsx` (Enterprise Security + Modern Design)
- **Enterprise Security Features**:
  - SecureAPI class för CSRF-skyddade requests
  - DOMPurify input/output sanitization
  - Säker autentisering med HttpOnly cookies
  - Auto-logout efter 5 minuters inaktivitet
  - Real-time CSRF token management
- **Modern Design System**:
  - Glassmorphism UI med backdrop-blur effekter
  - Avancerade CSS animationer (fade-in, slide-up, scale-in)
  - Mobile-first responsive design med safe areas
  - Toast notification system för user feedback
  - Loading states med skeleton screens och spinners
  - Brand-consistent green/gold color scheme
  - Legal page modal system (Privacy, Terms, About) replacing broken HTML files
  - Accessibility with focus states and keyboard navigation
- **Landing Page State** (Icke-inloggade användare):
  - Modern hero sektion med glassmorphism
  - Animated features showcase med hover effekter
  - Säker login formulär med loading states
  - Professional footer with working legal page modal triggers
- **Live Feed State** (Inloggade användare):
  - Clean header med connection status indicator
  - Säker logout med session cleanup
  - Animated online users lista
  - Virtual scrolled message feed med native scrollbar
  - Input area med character counter och validation
  - Message modal med sanitized content display
  - Real-time toast notifications för alla actions
- **Advanced Frontend Logic**:
  - Säker WebSocket med auto-reconnection
  - Virtual scroll performance optimization
  - State management med React hooks
  - CSRF token lifecycle management
  - Input sanitization på alla user interactions

#### `index.css`
```css
@tailwind base;      /* Tailwind reset */
@tailwind components; /* Tailwind komponenter */
@tailwind utilities; /* Tailwind utilities */
```

## Production Build (`/frontend/`)

```
frontend/
└── 📁 dist/                 # Nginx serverade filer
    ├── 📄 index.html        # SPA entry point
    └── 📁 assets/           # Bundled CSS/JS
        ├── 📄 index-[hash].css
        └── 📄 index-[hash].js
```

Denna mapp skapas av:
```bash
npm run build                # Vite bygger till /dist
cp -r dist/* frontend/dist/  # Kopierar för nginx
```

## Documentation (`/docs/`)

```
docs/
├── 📄 DEPLOYMENT.md         # Production deployment guide
├── 📄 HOWTO.md             # Utvecklar guide och tips
├── 📄 MVP.md               # MVP specification
└── 📄 PROJECT-STRUCTURE.md  # Denna fil
```

### Dokumentations Filer

- **DEPLOYMENT.md**: Komplett guide för att deploiera till produktion
- **HOWTO.md**: Praktiska tips för utveckling och underhåll  
- **MVP.md**: MVP specifikation och success criteria
- **PROJECT-STRUCTURE.md**: Denna översikt av filstruktur

## Konfigurationsfiler

### Frontend Konfiguration

#### `package.json`
```json
{
  "scripts": {
    "dev": "vite",           // Dev server på :5173
    "build": "tsc && vite build",  // TypeScript + Vite build  
    "preview": "vite preview"      // Preview production build
  }
}
```

#### `vite.config.ts`
- React plugin konfiguration
- Build optimering
- Dev server settings

#### `tailwind.config.js`
- Content paths för CSS purging
- Design tokens och tema
- Plugin konfiguration

#### `tsconfig.json`
- TypeScript compiler options
- Module resolution
- Strict type checking

### Backend Konfiguration

#### `.env`
```env
PORT=3001                    # Server port
NODE_ENV=production         # Environment
```

#### `tsconfig.json`
- Server-side TypeScript config
- Output directory: `dist/`
- Module: ESNext för modern Node.js

## Deployment Struktur

### Nginx Konfiguration
```nginx
# Statiska filer
location / {
    root /home/reda/development/mugharred/frontend/dist;
    try_files $uri $uri/ /index.html;
}

# API endpoints  
location /api {
    proxy_pass http://127.0.0.1:3001;
}

# WebSocket
location /ws {
    proxy_pass http://127.0.0.1:3001;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
}
```

### Process Management
```bash
# PM2 process
pm2 start ecosystem.config.js

# Systemd service (alternativ)
sudo systemctl start mugharred
```

## Dataflöde

### Frontend → Backend

1. **Login Request**
   ```
   POST /api/login
   Content-Type: application/json
   Body: { "name": "Användarnamn" }
   ```

2. **WebSocket Connection**
   ```
   WS /ws?sessionId=uuid-här
   ```

3. **Send Message**
   ```json
   {
     "type": "send_message", 
     "text": "Meddelande text"
   }
   ```

### Backend → Frontend

1. **Login Response**
   ```json
   { 
     "sessionId": "uuid-här", 
     "name": "Användarnamn" 
   }
   ```

2. **WebSocket Messages**
   ```json
   {
     "type": "message",
     "message": {
       "id": "msg-uuid",
       "user": "Användarnamn", 
       "text": "Meddelande",
       "timestamp": 1234567890
     }
   }
   ```

3. **Online Users Update**
   ```json
   {
     "type": "online_users",
     "users": ["Alice", "Bob", "Charlie"]
   }
   ```

## State Management

### Frontend State
```typescript
// Session state
const [sessionId, setSessionId] = useState<string | null>()
const [name, setName] = useState<string>()

// Feed state  
const [messages, setMessages] = useState<Message[]>([])
const [totalMessages, setTotalMessages] = useState(0)
const [onlineUsers, setOnlineUsers] = useState<string[]>([])

// UI state
const [input, setInput] = useState("")
const [expandedMessage, setExpandedMessage] = useState<Message | null>()
const [scrollTop, setScrollTop] = useState(0)
const [activeModal, setActiveModal] = useState<'privacy' | 'terms' | 'about' | null>(null)
```

### Backend State
```typescript
// In-memory storage (production ready for MVP)
const messages: Message[] = []
const onlineUsers = new Map<string, OnlineUser>()

// Rate limiting and auto-logout
const messageTimestamps = new Map<string, number[]>()
const INACTIVITY_TIMEOUT = 5 * 60 * 1000 // 5 minutes

// Auto-cleanup process
setInterval(cleanupInactiveUsers, 60_000) // Runs every minute
```

## Build Process

### Development
```bash
# Frontend hot reload
npm run dev              # → http://localhost:5173

# Backend hot reload  
cd backend && npm run dev # → http://localhost:3001
```

### Production
```bash
# Build frontend
npm run build            # TypeScript + Vite → dist/

# Build backend
cd backend && npm run build # TypeScript → dist/

# Deploy
cp -r dist/* frontend/dist/  # Frontend deploy
pm2 restart mugharred-backend # Backend deploy
```

## Enterprise Säkerhetslager

### Frontend Security
- **Input Validation**: Namn (2-50 tecken), meddelanden (max 500 tecken)
- **XSS Protection**: 
  - React JSX automatisk escaping
  - DOMPurify sanitization på all user input/output
  - CSP headers via Helmet.js
- **CSRF Protection**: 
  - SecureAPI class för alla requests
  - Double submit cookie pattern
  - Automatic token refresh
- **Session Security**: 
  - HttpOnly cookies endast
  - Auto-logout efter 5 min inaktivitet
  - Secure cookies i production (HTTPS)
- **Connection Security**:
  - HTTPS only enforcement
  - WebSocket over TLS (WSS)
  - Trusted origins endast

### Backend Security  
- **Authentication & Session**:
  - Redis session store med säkra cookies
  - Session expiry (30 minuter)
  - Automatic cleanup av inaktiva sessioner
- **Input Validation & Sanitization**:
  - Express-validator på alla endpoints
  - DOMPurify sanitization server-side
  - Strict input length limits
- **Rate Limiting**:
  - IP-baserad limiting (100 req/15min)
  - Authentication rate limiting (5 attempts/15min) 
  - Message rate limiting (5 msgs/10sec per user)
  - Max 5 concurrent users (hårdkodad säkerhet)
- **Security Headers**:
  - Helmet.js comprehensive headers
  - Content Security Policy
  - HSTS, X-Frame-Options, etc.
- **Logging & Monitoring**:
  - Winston säkerhetsloggning
  - Failed authentication tracking
  - Suspicious activity detection
  - Auto-alerting på säkerhetsincidenter

### Infrastructure Security
- **Reverse Proxy**: Nginx med säker konfiguration
- **SSL/TLS**: Let's Encrypt med auto-renewal
- **Network Security**: 
  - Trust proxy endast localhost (127.0.0.1)
  - CORS strict origin policy
  - Brandvägg (ufw) regler
- **Process Security**:
  - PM2 process isolation
  - Non-root user execution
  - Environment variable protection
- **Data Security**:
  - Redis password authentication
  - In-memory endast (ingen persistent data)
  - Auto-cleanup av känslig data

## Performance Optimering

### Frontend
- **Virtual scrolling**: Endast 10 meddelanden rendered
- **Code splitting**: Vite automatisk chunking
- **Asset caching**: Nginx lange cache headers
- **Bundle size**: Tree shaking via Vite

### Backend
- **In-memory storage**: Snabbare än databas för MVP
- **WebSocket keepalive**: Effektiv realtidskommunikation  
- **Rate limiting**: Förhindrar server överbelastning
- **Process clustering**: PM2 cluster mode (framtida)

### Infrastructure  
- **Nginx caching**: Statiska assets
- **Gzip compression**: Mindre transfer sizes
- **HTTP/2**: Modern protokoll support
- **CDN ready**: Enkelt att lägga till CDN senare