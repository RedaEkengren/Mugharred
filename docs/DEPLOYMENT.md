# Deployment Guide

Guide för att deploiera Mugharred till produktion.

**Status: ✅ REDAN DEPLOYAD på https://mugharred.se**

Detta dokument beskriver hur den nuvarande installationen är uppsatt och hur du kan uppdatera eller replikera den.

## Produktionsmiljö

### Server Krav
- Ubuntu 20.04+ eller liknande Linux distribution
- Node.js 18+ (latest LTS recommended)
- Redis server (för säkra sessioner - REQUIRED för säkerhet)
- Nginx (reverse proxy + säkra headers)
- SSL certifikat (Let's Encrypt auto-renewal)
- Minst 1GB RAM (rekommenderat 2GB för säkerhet)
- 10GB diskutrymme (inkl. säkerhetsloggar)
- Firewall (ufw) för nätverkssäkerhet

### Nuvarande Setup (Live Production)
- **Server**: Ubuntu 20.04 LTS med Nginx reverse proxy
- **Domain**: mugharred.se (SSL aktiv)
- **SSL**: Let's Encrypt automatiska certifikat (förnyade automatiskt)
- **Frontend**: Statiska React build med XSS-skydd
- **Backend**: Node.js TypeScript process på port 3001
- **Database**: Redis för sessionslagring
- **Security**: Enterprise-grade säkerhetsimplementering
- **Process Manager**: PM2 med auto-restart
- **Status**: ✅ Stabil och live sedan December 12, 2025
- **Latest**: ✅ WebSocket sessionId mismatch buggfix deployed (2025-12-12)

## Deployment Process

### 1. Förbered Backend

```bash
# Gå till backend mappen
cd backend

# Installera dependencies (inkluderar säkerhetspaket)
npm install

# Konfigurera miljövariabler
cp .env.example .env
# Redigera .env med produktionsvärden:
# NODE_ENV=production
# SESSION_SECRET=<stark-slumpmässig-sträng>
# JWT_SECRET=<stark-slumpmässig-sträng>
# REDIS_URL=redis://localhost:6379

# Starta Redis server
sudo systemctl start redis-server
sudo systemctl enable redis-server

# Bygg TypeScript
npm run build

# Testa att det funkar
npm start
```

### 2. Bygg Frontend

```bash
# Gå till project root
cd ..

# Bygg frontend
npm run build

# Kopiera till deployment mapp
cp -r dist/* frontend/dist/
```

### 3. Starta Backend Process

#### Option 1: PM2 (Rekommenderat)

```bash
# Installera PM2 globalt
npm install -g pm2

# Skapa PM2 config
cat > ecosystem.config.js << EOF
module.exports = {
  apps: [{
    name: 'mugharred-backend',
    script: './backend/dist/server.js',
    instances: 1,
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'production',
      PORT: 3001
    },
    error_file: './backend/logs/err.log',
    out_file: './backend/logs/out.log',
    log_file: './backend/logs/combined.log',
    time: true
  }]
}
EOF

# Skapa logs mapp
mkdir -p backend/logs

# Starta med PM2
pm2 start ecosystem.config.js

# Spara PM2 config
pm2 save
pm2 startup
```

#### Option 2: Systemd Service

```bash
# Skapa service fil
sudo tee /etc/systemd/system/mugharred.service > /dev/null <<EOF
[Unit]
Description=Mugharred Backend
After=network.target

[Service]
Type=simple
User=reda
WorkingDirectory=/home/reda/development/mugharred
Environment=NODE_ENV=production
Environment=PORT=3001
ExecStart=/usr/bin/node backend/dist/server.js
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Ladda och starta service
sudo systemctl daemon-reload
sudo systemctl enable mugharred
sudo systemctl start mugharred

# Kontrollera status
sudo systemctl status mugharred
```

### 4. Nginx Konfiguration

Nginx är redan konfigurerat för mugharred.se. Kontrollera att konfigurationen är aktiv:

```bash
# Kontrollera att config är länkad
sudo ls -la /etc/nginx/sites-enabled/mugharred

# Om inte, länka den
sudo ln -s /etc/nginx/sites-available/mugharred /etc/nginx/sites-enabled/

# Testa nginx config
sudo nginx -t

# Ladda om nginx
sudo systemctl reload nginx
```

### 5. SSL Certifikat

SSL certifikaten hanteras automatiskt av Let's Encrypt:

```bash
# Förnya certifikat (körs automatiskt)
sudo certbot renew --dry-run

# Kontrollera certifikat status
sudo certbot certificates
```

## Automatisk Deployment

### Deploy Script

Skapa ett deploy script för framtida uppdateringar:

```bash
cat > deploy.sh << 'EOF'
#!/bin/bash
set -e

echo "🚀 Deploying Mugharred..."

# Pull latest changes (if using git)
# git pull origin main

# Install/update dependencies
echo "📦 Installing dependencies..."
npm install
cd backend && npm install && cd ..

# Build frontend
echo "🔨 Building frontend..."
npm run build
cp -r dist/* frontend/dist/

# Build backend
echo "🔨 Building backend..."
cd backend && npm run build && cd ..

# Restart backend process
echo "🔄 Restarting backend..."
if command -v pm2 > /dev/null; then
    pm2 restart mugharred-backend
else
    sudo systemctl restart mugharred
fi

# Reload nginx
echo "🌐 Reloading nginx..."
sudo systemctl reload nginx

echo "✅ Deployment complete!"
echo "🌍 Site available at: https://mugharred.se"
EOF

chmod +x deploy.sh
```

### Användning av Deploy Script

```bash
./deploy.sh
```

## Monitoring

### Loggar

#### PM2 Loggar
```bash
# Visa live loggar
pm2 logs mugharred-backend

# Visa specifika loggar
pm2 logs mugharred-backend --lines 100
```

#### Systemd Loggar
```bash
# Visa live loggar
sudo journalctl -u mugharred -f

# Visa senaste loggar
sudo journalctl -u mugharred --lines=100
```

#### Nginx Loggar
```bash
# Access loggar
sudo tail -f /var/log/nginx/mugharred.access.log

# Error loggar  
sudo tail -f /var/log/nginx/mugharred.error.log
```

### Hälsokontroll

```bash
# Kontrollera backend hälsa
curl https://mugharred.se/health

# Kontrollera frontend
curl -I https://mugharred.se

# Kontrollera WebSocket (med websocat)
echo '{"type":"ping"}' | websocat wss://mugharred.se/ws?sessionId=test
```

### Performance Monitoring

#### Basic System Monitoring
```bash
# CPU och minne
htop

# Disk användning
df -h

# Network connections
sudo netstat -tlpn | grep :3001
```

#### Application Monitoring
```bash
# PM2 monitoring
pm2 monit

# Real-time stats
pm2 status
```

## Backup

### Automatisk Backup (För framtida databas)

```bash
# Skapa backup script
cat > backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/home/reda/backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Backup application code
tar -czf "$BACKUP_DIR/mugharred_$DATE.tar.gz" \
    /home/reda/development/mugharred \
    --exclude=node_modules \
    --exclude=dist \
    --exclude=logs

# Keep only last 7 days of backups
find $BACKUP_DIR -name "mugharred_*.tar.gz" -mtime +7 -delete

echo "Backup created: mugharred_$DATE.tar.gz"
EOF

chmod +x backup.sh

# Schemalägg med crontab
(crontab -l 2>/dev/null; echo "0 2 * * * /home/reda/development/mugharred/backup.sh") | crontab -
```

## Säkerhet

### Brandvägg
```bash
# Tillåt endast nödvändiga portar
sudo ufw allow 22    # SSH
sudo ufw allow 80    # HTTP (omdirigering till HTTPS)
sudo ufw allow 443   # HTTPS
sudo ufw enable
```

### Updates
```bash
# Håll systemet uppdaterat
sudo apt update && sudo apt upgrade -y

# Update Node.js packages regelbundet
npm audit && npm audit fix
cd backend && npm audit && npm audit fix
```

## Felsökning

### Vanliga Problem

1. **Backend startar inte**
   ```bash
   # Kontrollera loggar
   pm2 logs mugharred-backend
   # eller
   sudo journalctl -u mugharred -n 50
   ```

2. **WebSocket anslutningar misslyckas** ⚠️ SENAST FIXAD 2025-12-12
   ```bash
   # KRITISK FIX IMPLEMENTERAD:
   # Problem: Users togs premature bort från onlineUsers Map av broadcast()
   # Lösning: Uppdaterad broadcast logic för korrekt hantering
   
   # DEBUG STEPS:
   # Kontrollera att backend lyssnar på rätt port
   sudo netstat -tlpn | grep :3001
   
   # Kontrollera att users finns kvar i onlineUsers efter login
   pm2 logs mugharred-backend | grep "Setting user in onlineUsers"
   
   # Verifiera WebSocket connections
   pm2 logs mugharred-backend | grep "WebSocket connected"
   
   # Kontrollera nginx WebSocket config
   sudo nginx -t
   ```

3. **Frontend visar inte uppdateringar**
   ```bash
   # Kontrollera att nya filer är deployade
   ls -la frontend/dist/
   
   # Rensa browser cache
   # Kontrollera nginx caching headers
   ```

4. **SSL certifikat problem**
   ```bash
   # Kontrollera certifikat
   sudo certbot certificates
   
   # Förnya manuellt
   sudo certbot renew
   ```

### Prestanda Tuning

1. **Nginx Optimering**
   - Justera worker processes
   - Optimera buffer sizes
   - Konfigurera caching

2. **Node.js Optimering**
   - Använd PM2 cluster mode
   - Övervaka minne användning
   - Optimera garbage collection

3. **Database (för framtiden)**
   - Index viktiga fält
   - Connection pooling
   - Query optimering

## Skalning

### Horisontell Skalning

För framtida tillväxt:

1. **Load Balancer**: Nginx upstream med flera backend servrar
2. **Database**: PostgreSQL/MongoDB cluster
3. **Redis**: Session store och caching
4. **CDN**: Statiska resurser

### Vertikal Skalning

1. **RAM**: Öka för fler samtidiga användare
2. **CPU**: Öka för bättre WebSocket prestanda
3. **Storage**: SSD för bättre I/O prestanda