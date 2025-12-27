# Mugharred - How To Guide

Practical guide for common tasks in the Mugharred project.

**Live System: https://mugharred.se** | **Status: ✅ Production Ready**

This is your guide for working with the live Mugharred installation.

## 🚨 KRITISK STATUS (2025-12-27) - KREDIT SLÖSERI STOPP

**PROBLEM**: Följde inte MVP.md korrekt - endast 10% av Phase 1 klart

**VAD SOM GJORTS (LITE):**
- ✅ Room creation modal på landing page
- ✅ Backend room foundation filer (men ej integrerade)

**VAD SOM SAKNAS (MEST AV PHASE 1):**
- ❌ Room API endpoints - backend kan ej skapa rum
- ❌ Join room flow - ingen kan gå med i rum  
- ❌ Room timer countdown - inget synligt slutdatum
- ❌ Host controls - ingen kan kicka/låsa rum
- ❌ Room-specific chat - bara global chat finns

**EFTER /COMPACT - STRIKT GOLDENRULES.MD WORKFLOW:**
1. INVENTORY (läs exakt vad som finns)
2. PLAN (enligt MVP.md Phase 1 krav) 
3. EXECUTE (script-driven bara)

## Utveckling

### Starta Utvecklingsmiljö

1. **First time:**
   ```bash
   # Clone and install
   git clone <repository>
   cd mugharred
   npm install
   cd backend && npm install && cd ..
   ```

2. **Daily usage:**
   ```bash
   # Start Redis for session storage
   sudo systemctl start redis-server
   
   # Terminal 1 - Frontend dev server
   npm run dev
   
   # Terminal 2 - Backend dev server
   cd backend
   npm run dev
   ```

3. **Open in browser:**
   ```
   http://localhost:5173
   ```

### Uppdatera Applikationen

#### Frontend Ändringar

1. **Ändra design/layout:**
   - Editera `src/MugharredLandingPage.tsx`
   - Tailwind klasser för styling
   - Komponenten reloads automatiskt

2. **Lägg till nya funktioner:**
   ```bash
   # Lägg till nya dependencies
   npm install <package-name>
   
   # Uppdatera TypeScript types om behövs
   npm install @types/<package-name> --save-dev
   ```

3. **Testing modal system:**
   ```bash
   # After making changes to modal content, verify:
   npm run dev
   # 1. Open http://localhost:5173
   # 2. Scroll to footer
   # 3. Click Privacy Policy, Terms, or About
   # 4. Modal should open with updated content
   ```

4. **Build for production:**
   ```bash
   npm run build
   cp -r dist/* frontend/dist/
   ```

#### Backend Ändringar

1. **Ändra API endpoints:**
   - Editera `backend/src/server.ts`
   - Servern restartar automatiskt med `npm run dev`

2. **Lägg till nya dependencies:**
   ```bash
   cd backend
   npm install <package-name>
   npm install @types/<package-name> --save-dev
   ```

3. **Bygg för produktion:**
   ```bash
   cd backend
   npm run build
   ```

### Databas Ändringar (Framtida)

När du övergår från in-memory till databas:

1. **Lägg till databas config:**
   ```bash
   cd backend
   npm install pg # för PostgreSQL
   # eller
   npm install mongodb # för MongoDB
   ```

2. **Uppdatera server.ts:**
   - Ersätt in-memory arrays med databas calls
   - Lägg till connection pooling
   - Hantera migrationer

### Testa Ändringar

#### Frontend Tester
```bash
# Lägg till Vitest för enhetstester
npm install vitest @testing-library/react --save-dev

# Kör tester
npm test
```

#### Backend Tester
```bash
cd backend
# Lägg till Jest
npm install jest @types/jest ts-jest --save-dev

# Kör tester  
npm test
```

#### End-to-End Tester
```bash
# Lägg till Playwright
npm install @playwright/test --save-dev

# Kör E2E tester
npx playwright test
```

## Produktion

### Deploiera Ändringar

1. **Snabb deploy (existerande setup):**
   ```bash
   ./deploy.sh
   ```

2. **Manuell deploy:**
   ```bash
   # Kontrollera att Redis körs
   redis-cli ping
   
   # Bygg frontend med säkerhetsuppdateringar
   npm run build
   cp -r dist/* frontend/dist/
   
   # Bygg säker backend
   cd backend && npm run build && cd ..
   
   # Starta om backend med nya säkerhetsfunktioner
   pm2 restart mugharred-backend
   # eller
   sudo systemctl restart mugharred
   
   # Testa säkerhetsendpoints
   curl https://mugharred.se/api/csrf-token
   curl https://mugharred.se/health
   ```

### Monitoring och Loggar

#### Visa Live Loggar
```bash
# Backend loggar (PM2 - AKTUELL SETUP)
pm2 logs mugharred-backend --lines 50

# PM2 status och stats
pm2 status
pm2 monit

# Nginx loggar
sudo tail -f /var/log/nginx/mugharred.access.log
sudo tail -f /var/log/nginx/mugharred.error.log
```

#### Kontrollera System Hälsa
```bash
# Backend hälsa
curl https://mugharred.se/health

# PM2 status
pm2 status

# System resurser
htop
df -h
```

### Backup och Återställning

#### Skapa Backup
```bash
# Manuell backup
./backup.sh

# Kontrollera backups
ls -la /home/reda/backups/
```

#### Återställa från Backup
```bash
# Stoppa tjänster
pm2 stop mugharred-backend

# Återställ filer
cd /home/reda/development/
tar -xzf /home/reda/backups/mugharred_YYYYMMDD_HHMMSS.tar.gz

# Installera dependencies och bygg
cd mugharred
npm install
cd backend && npm install && npm run build && cd ..
npm run build
cp -r dist/* frontend/dist/

# Starta tjänster
pm2 start mugharred-backend
```

## Konfiguration

### Ändra Port/Domän

1. **Backend port:**
   ```bash
   # Ändra i backend/.env
   PORT=3002
   
   # Uppdatera nginx upstream i /etc/nginx/sites-available/mugharred
   upstream mugharred_backend {
       server 127.0.0.1:3002;
   }
   
   # Ladda om nginx
   sudo systemctl reload nginx
   ```

2. **Ny domän:**
   ```bash
   # Uppdatera nginx server_name
   sudo nano /etc/nginx/sites-available/mugharred
   # Ändra server_name till ny domän
   
   # Skaffa nytt SSL certifikat
   sudo certbot --nginx -d nydomän.se
   ```

### Säkerhets Inställningar

#### Enterprise Security Features (Aktiv)

Mugharred använder nu enterprise-grad säkerhet:

1. **Redis Session Store:**
   ```bash
   # Kontrollera Redis status
   redis-cli ping
   systemctl status redis-server
   
   # Konfigurera Redis lösenord (rekommenderat)
   sudo nano /etc/redis/redis.conf
   # Lägg till: requirepass ditt_starka_lösenord
   sudo systemctl restart redis-server
   ```

2. **CSRF Protection:**
   ```bash
   # Testa CSRF endpoint
   curl https://mugharred.se/api/csrf-token
   # Svar: {"csrfToken":"..."}
   
   # Alla POST requests kräver X-CSRF-Token header
   ```

3. **Security Headers:**
   ```bash
   # Kontrollera säkerhetsheaders
   curl -I https://mugharred.se
   # Ska inkludera:
   # X-Content-Type-Options: nosniff
   # X-Frame-Options: DENY
   # X-XSS-Protection: 1; mode=block
   ```

4. **Rate Limiting:**
   ```typescript
   // API rate limiting (backend/src/server.ts)
   const apiLimiter = rateLimit({
     windowMs: 15 * 60 * 1000, // 15 minuter
     max: 100 // 100 requests per IP
   });
   
   // Auth rate limiting
   const authLimiter = rateLimit({
     windowMs: 15 * 60 * 1000,
     max: 5 // 5 inloggningsförsök per IP
   });
   ```

5. **Input Sanitization:**
   ```typescript
   // DOMPurify används automatiskt på alla inputs
   // Backend: sanitizeInput(userInput)
   // Frontend: DOMPurify.sanitize(message.text)
   ```

6. **Säkerhetsloggning:**
   ```bash
   # Visa säkerhetsloggar
   tail -f backend/logs/error.log
   tail -f backend/logs/combined.log
   
   # Övervaka misslyckade inloggningsförsök
   grep "Unauthorized access" backend/logs/combined.log
   ```

#### Konfigurera Säkerhetsinställningar

1. **Ändra session secrets (.env):**
   ```bash
   # Generera starka secrets
   openssl rand -base64 32
   
   # Uppdatera backend/.env
   SESSION_SECRET=din_starka_session_secret
   JWT_SECRET=din_starka_jwt_secret
   ```

2. **Ändra max användare:**
   ```typescript
   // I backend/src/server.ts
   const MAX_ONLINE_USERS = 10; // Ändra från 5 till 10
   ```

3. **Ändra rate limiting:**
   ```typescript
   // I backend/src/server.ts
   const MAX_MSG_PER_WINDOW = 10; // Ändra från 5
   const WINDOW_MS = 5_000;       // Ändra från 10 sekunder till 5
   ```

4. **Ändra session timeout:**
   ```typescript
   // I backend/src/server.ts session config
   cookie: {
     maxAge: 1000 * 60 * 60, // Ändra från 30 min till 1 timme
   }
   ```

### Nginx Optimering

1. **Ändra caching:**
   ```nginx
   # I /etc/nginx/sites-available/mugharred
   location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2)$ {
       expires 30d; # Ändra från 1y till 30d
   }
   ```

2. **Lägg till rate limiting:**
   ```nginx
   # I nginx.conf http block
   limit_req_zone $binary_remote_addr zone=api:10m rate=60r/m;
   
   # I server block
   location /api {
       limit_req zone=api burst=10 nodelay;
       # ... rest av config
   }
   ```

## Felsökning

### Vanliga Problem och Lösningar

1. **"EADDRINUSE: Port 3001 redan används"**
   ```bash
   # Hitta och döda process
   lsof -ti:3001 | xargs kill -9
   
   # Eller ändra port i .env
   ```

2. **"WebSocket anslutning misslyckades"** ⚠️ NYLIGEN FIXAD
   ```bash
   # VANLIGA ORSAKER OCH LÖSNINGAR:
   
   # A) SessionId mismatch (FIXAD 2025-12-12)
   # Problem: Användare blir borttagna från onlineUsers innan WebSocket ansluter
   # Lösning: Uppdaterad broadcast() funktion att inte ta bort users utan WebSocket
   
   # B) Kontrollera backend körs
   curl http://localhost:3001/health
   
   # C) Debug WebSocket connections
   # Sök efter dessa loggar i backend:
   pm2 logs mugharred-backend | grep "WebSocket"
   # Du ska se "✅ WebSocket connected" när det fungerar
   
   # D) Kontrollera nginx WebSocket config
   sudo nginx -t
   
   # E) Debug sessionId issues
   # Kontrollera att användaren finns i onlineUsers när WebSocket försöker ansluta
   curl -X POST http://localhost:3001/api/login -H "Content-Type: application/json" -d '{"name":"TestUser"}'
   # Ska returnera sessionId som används för WebSocket
   ```

3. **"Permission denied" när du deployar**
   ```bash
   # Kontrollera ägarskap
   sudo chown -R reda:reda /home/reda/development/mugharred/
   
   # Kontrollera rättigheter
   chmod +x deploy.sh
   ```

4. **Frontend visar gamla filer**
   ```bash
   # Rensa browser cache (Ctrl+Shift+R)
   
   # Kontrollera att nya filer deployats
   ls -la frontend/dist/
   
   # Kontrollera nginx caching headers
   curl -I https://mugharred.se/
   ```

### Debug Verktyg

1. **WebSocket debug:**
   ```bash
   # Installera websocat
   sudo apt install websocat
   
   # Testa WebSocket
   echo '{"type":"send_message","text":"test"}' | \
   websocat wss://mugharred.se/ws?sessionId=debug
   ```

2. **Network debug:**
   ```bash
   # Kontrollera portar
   sudo netstat -tlpn | grep :3001
   
   # Testa API endpoints
   curl -X POST https://mugharred.se/api/login \
     -H "Content-Type: application/json" \
     -d '{"name":"test"}'
   ```

3. **Performance debug:**
   ```bash
   # CPU användning
   top -p $(pgrep -f "node.*server.js")
   
   # Minne användning
   ps aux | grep node
   
   # Network trafik
   sudo iftop
   ```

## Utvecklar Tips

### Hot Tips för Snabbare Utveckling

1. **Auto-reload för både frontend och backend:**
   ```bash
   # Använd concurrently för att köra båda
   npm install concurrently --save-dev
   
   # Lägg till script i package.json
   "scripts": {
     "dev:all": "concurrently \"npm run dev\" \"cd backend && npm run dev\""
   }
   ```

2. **Browser dev tools:**
   - Network tab för att debugga API calls
   - WebSocket messages i Network > WS
   - React DevTools extension

3. **VS Code extensions:**
   - ES7+ React/Redux/React-Native snippets
   - Tailwind CSS IntelliSense
   - TypeScript Importer
   - Thunder Client (för API testing)

### Code Conventions

1. **Fil naming:**
   - React komponenter: PascalCase (`MugharredLandingPage.tsx`)
   - Vanliga filer: kebab-case (`deploy.sh`)
   - Konstanter: UPPER_SNAKE_CASE (`MAX_USERS`)

2. **Commit messages:**
   ```
   feat: lägg till message modal
   fix: åtgärda WebSocket återanslutning
   docs: uppdatera deployment guide
   refactor: förbättra virtual scroll prestanda
   ```

3. **TypeScript:**
   - Alltid definiera types
   - Använd interfaces för objekt
   - Undvik `any` typ

4. **CSS/Tailwind:**
   - Konsekvent spacing (4, 6, 10, etc.)
   - Använd design tokens för färger
   - Mobile-first responsive design