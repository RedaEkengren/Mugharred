# Mugharred

En enkel social feed som uppdateras live - minimalistisk Twitter-klon med WebSocket-support.

## Översikt

Mugharred är en enkelsidig applikation som låter användare chatta i realtid. Applikationen använder en minimalistisk inloggning (endast namn) och är begränsad till max 5 användare samtidigt.

### Funktioner

- ✅ **En sida** - Ingen navigation, allt händer på samma vy
- ✅ **Live feed** - Meddelanden uppdateras i realtid via WebSockets
- ✅ **Virtual scroll** - Renderar endast 10 meddelanden i taget med native scrollbar
- ✅ **Modal för fulltext** - Klicka på meddelanden för att se hela texten
- ✅ **Online-lista** - Se vilka som är online just nu
- ✅ **Rate limiting** - Begränsar spam och attacker
- ✅ **Vacker design** - Glassmorphism med gradienter i grön/guld

### Säkerhet (Medvetet enkel)

- Max 5 användare online samtidigt
- Rate limiting: 5 meddelanden per 10 sekunder
- Meddelanden begränsade till 500 tecken
- Enkel session-hantering (in-memory)

## Projektstruktur

```
mugharred/
├── backend/                 # Node.js + TypeScript backend
│   ├── src/
│   │   └── server.ts       # Express server med WebSocket
│   ├── package.json
│   └── tsconfig.json
├── frontend/               # Deployade frontend filer
│   └── dist/
├── src/                    # React frontend källkod
│   ├── MugharredLandingPage.tsx
│   ├── main.tsx
│   └── index.css
├── docs/                   # Dokumentation
├── package.json
├── vite.config.ts
└── README.md
```

## Teknik Stack

### Frontend
- **React 18** - UI bibliotek
- **TypeScript** - Typsäkerhet
- **Vite** - Build tool och dev server
- **Tailwind CSS** - Styling
- **Lucide React** - Ikoner

### Backend
- **Node.js** - Runtime
- **Express** - Web framework
- **WebSockets (ws)** - Realtidskommunikation
- **TypeScript** - Typsäkerhet
- **CORS** - Cross-origin support

### Infrastructure
- **Nginx** - Reverse proxy och static file server
- **Let's Encrypt** - SSL certificat
- **Ubuntu Server** - Production miljö

## Snabbstart

### Krav
- Node.js 18+
- npm eller yarn

### Installation

1. **Klona och installera**
   ```bash
   git clone <repository-url>
   cd mugharred
   npm install
   cd backend && npm install && cd ..
   ```

2. **Starta utveckling**
   ```bash
   # Terminal 1 - Frontend
   npm run dev
   
   # Terminal 2 - Backend
   cd backend && npm run dev
   ```

3. **Öppna i webbläsare**
   ```
   http://localhost:5173
   ```

### Produktion

Se [DEPLOYMENT.md](docs/DEPLOYMENT.md) för fullständig deploy guide.

## API Endpoints

### HTTP Endpoints
- `POST /api/login` - Logga in med namn
- `GET /api/messages?offset=0&limit=10` - Hämta meddelanden (paginerat)
- `GET /api/online-users` - Lista online användare
- `GET /health` - Hälsokontroll

### WebSocket
- `ws://host/ws?sessionId=xxx` - Realtidsanslutning

#### WebSocket Meddelanden

**Från klient:**
```json
{
  \"type\": \"send_message\",
  \"text\": \"Mitt meddelande\"
}
```

**Till klient:**
```json
{
  \"type\": \"message\",
  \"message\": {
    \"id\": \"uuid\",
    \"user\": \"Användarnamn\",
    \"text\": \"Meddelande text\",
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

## Nästa Steg

För att förbättra säkerheten i framtiden:

1. **Databas**: Flytta från in-memory till persistent storage
2. **Autentisering**: Lägg till e-post verifiering
3. **Sessions**: Redis-baserad session hantering  
4. **Rate Limiting**: Mer sofistikerad begränsning
5. **Moderering**: Automatisk innehållsfiltrering
6. **Backup**: Regelbunden säkerhetskopiering

## Support

För frågor eller problem, skapa en issue i projektet.

## Licens

MIT License - se [LICENSE](LICENSE) för detaljer.