# Mugharred - How To Guide

Praktisk guide för vanliga uppgifter i Mugharred projektet.

## Utveckling

### Starta Utvecklingsmiljö

1. **Första gången:**
   ```bash
   # Klona och installera
   git clone <repository>
   cd mugharred
   npm install
   cd backend && npm install && cd ..
   ```

2. **Daglig användning:**
   ```bash
   # Terminal 1 - Frontend dev server
   npm run dev
   
   # Terminal 2 - Backend dev server
   cd backend
   npm run dev
   ```

3. **Öppna i webbläsare:**
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

3. **Bygg för produktion:**
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
   # Bygg frontend
   npm run build
   cp -r dist/* frontend/dist/
   
   # Bygg backend
   cd backend && npm run build && cd ..
   
   # Starta om backend
   pm2 restart mugharred-backend
   # eller
   sudo systemctl restart mugharred
   ```

### Monitoring och Loggar

#### Visa Live Loggar
```bash
# Backend loggar
pm2 logs mugharred-backend --lines 50
# eller
sudo journalctl -u mugharred -f

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

1. **Ändra max användare:**
   ```typescript
   // I backend/src/server.ts
   const MAX_ONLINE_USERS = 10; // Ändra från 5 till 10
   ```

2. **Ändra rate limiting:**
   ```typescript
   // I backend/src/server.ts
   const MAX_MSG_PER_WINDOW = 10; // Ändra från 5
   const WINDOW_MS = 5_000;       // Ändra från 10 sekunder till 5
   ```

3. **Meddelande längd:**
   ```typescript
   // I backend/src/server.ts
   if (!text || text.length > 1000) return; // Ändra från 500 till 1000
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

2. **"WebSocket anslutning misslyckades"**
   ```bash
   # Kontrollera backend körs
   curl http://localhost:3001/health
   
   # Kontrollera nginx WebSocket config
   sudo nginx -t
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