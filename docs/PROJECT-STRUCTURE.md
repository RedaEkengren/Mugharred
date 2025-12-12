# Mugharred Project Structure

Översikt över projektets filstruktur och organisation.

**Live Production System på https://mugharred.se**

Detta dokument beskriver hur den nuvarande live installationen är organiserad.

## Rot Nivå

```
mugharred/
├── 📁 backend/              # Node.js backend server
├── 📁 docs/                 # Projektdokumentation
├── 📁 frontend/             # Production frontend build
├── 📁 src/                  # Frontend källkod (React)
├── 📄 .gitignore           # Git ignore patterns
├── 📄 README.md            # Huvuddokumentation
├── 📄 package.json         # Frontend dependencies och scripts
├── 📄 tsconfig.json        # TypeScript konfiguration (frontend)
├── 📄 tailwind.config.js   # Tailwind CSS konfiguration
├── 📄 postcss.config.js    # PostCSS konfiguration
├── 📄 vite.config.ts       # Vite build tool konfiguration
└── 📄 index.html           # HTML mall för SPA
```

## Backend (`/backend/`)

```
backend/
├── 📁 src/                  # TypeScript källkod
│   └── 📄 server.ts         # Huvud server fil (Express + WebSocket)
├── 📁 dist/                 # Kompilerad JavaScript (genererad)
├── 📁 logs/                 # Server loggar (PM2)
├── 📄 package.json          # Backend dependencies
├── 📄 tsconfig.json         # TypeScript config för backend
└── 📄 .env                  # Environment variabler
```

### Backend Filer

#### `src/server.ts`
- Express server setup
- WebSocket hantering
- API endpoints (/api/login, /api/messages, etc.)
- In-memory storage för meddelanden och användare
- Rate limiting logik
- CORS konfiguration

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

#### `MugharredLandingPage.tsx`
- **Landing Page State**: Icke-inloggade användare
  - Hero sektion med beskrivning
  - Features showcase
  - Login formulär
- **Live Feed State**: Inloggade användare  
  - Header med logout
  - Online users lista
  - Message input
  - Virtual scrolled feed
  - Message modal
- **Shared Logic**:
  - WebSocket hantering
  - State management
  - Virtual scroll implementation

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
```

### Backend State
```typescript
// In-memory storage (production ready för MVP)
const messages: Message[] = []
const onlineUsers = new Map<string, OnlineUser>()

// Rate limiting och auto-logout
const messageTimestamps = new Map<string, number[]>()
const INACTIVITY_TIMEOUT = 5 * 60 * 1000 // 5 minuter

// Auto-cleanup process
setInterval(cleanupInactiveUsers, 60_000) // Körs varje minut
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

## Säkerhet Lager

### Frontend
- Input validering (namn längd, meddelande längd)
- XSS skydd via React's JSX escaping
- HTTPS only i production

### Backend  
- Rate limiting per session
- CORS konfiguration
- Input sanitization
- Session validering

### Infrastructure
- Nginx reverse proxy
- SSL termination
- Security headers
- Brandvägg (ufw)

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