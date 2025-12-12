# Mugharred

En enkel social feed som uppdateras live - minimalistisk Twitter-klon med WebSocket-support och automatisk inaktivitetshantering.

## Översikt

Mugharred är en enkelsidig applikation som låter användare chatta i realtid. Applikationen använder en minimalistisk inloggning (endast namn), är begränsad till max 5 användare samtidigt, och loggar automatiskt ut inaktiva användare efter 5 minuter.

### Funktioner

- ✅ **En sida** - Ingen navigation, allt händer på samma vy
- ✅ **Live feed** - Meddelanden uppdateras i realtid via WebSockets
- ✅ **Virtual scroll** - Renderar endast 10 meddelanden i taget med native scrollbar
- ✅ **Modal för fulltext** - Klicka på meddelanden för att se hela texten
- ✅ **Online-lista** - Se vilka som är online just nu (max 5 samtidigt)
- ✅ **Rate limiting** - Begränsar spam och attacker (5 meddelanden/10 sek)
- ✅ **Auto-logout** - Automatisk utloggning efter 5 minuters inaktivitet
- ✅ **Vacker design** - Glassmorphism med gradienter i grön/guld
- ✅ **Clean state** - Ingen testdata, redo för riktiga användare

### Säkerhet (Medvetet enkel)

- Max 5 användare online samtidigt
- Rate limiting: 5 meddelanden per 10 sekunder
- Meddelanden begränsade till 500 tecken
- Auto-logout efter 5 minuters inaktivitet
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

## Aktuell Status (December 2025)

Mugharred MVP är **100% funktionell** och live på https://mugharred.se

### Vad som fungerar ✅
- [x] Komplett social feed med realtidschat
- [x] Landing page med vacker design
- [x] Max 5 användare säkerhetsbegränsning
- [x] Rate limiting (5 meddelanden/10 sek)
- [x] Auto-logout efter 5 min inaktivitet
- [x] Virtual scroll med native scrollbar
- [x] Modal för fulltext meddelanden
- [x] WebSocket realtidsuppdateringar
- [x] PM2 production deployment
- [x] SSL/HTTPS via Let's Encrypt
- [x] Nginx reverse proxy
- [x] Komplett dokumentation

## Nästa Steg (Post-MVP)

För att skala upp från MVP till produktionssystem:

1. **Databas**: PostgreSQL för persistent storage
2. **Autentisering**: E-post verifiering och riktiga användarkonton
3. **Sessions**: Redis-baserad session store  
4. **Skalning**: Öka användargräns från 5 till 50-100
5. **Moderering**: Automatisk innehållsfiltrering och admin tools
6. **Analytics**: Användningsstatistik och monitoring
7. **Mobile app**: React Native companion app
8. **Backup**: Automatisk databas backup

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