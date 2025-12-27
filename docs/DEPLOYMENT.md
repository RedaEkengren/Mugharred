# Deployment Guide

**Current Status:** JWT + Redis stateless architecture deployed (December 27, 2024)

## Production Environment

**Live at:** https://mugharred.se  
**Architecture:** JWT + Redis + WebSocket  
**Port:** 3010  

### Server Requirements
- Ubuntu 20.04+ Linux distribution
- Node.js 18+ (LTS recommended)
- Redis server (room persistence)
- Nginx (reverse proxy + static files)
- SSL certificate (Let's Encrypt)
- 2GB RAM (recommended)
- 10GB disk space
- Firewall (ufw) configuration

## Current Deployment

### Backend (Port 3010)
```bash
cd /home/reda/development/mugharred/backend
npm run build
node dist/server.js &
```

### Frontend
```bash
cd /home/reda/development/mugharred/frontend  
npm run build
sudo cp -r dist/* /var/www/html/
```

### Services Running
- **Backend:** Node.js on port 3010
- **Redis:** Default port 6379
- **Nginx:** Port 80/443 (reverse proxy)

## Nginx Configuration

### Location: `/etc/nginx/sites-available/mugharred`

```nginx
server {
    server_name mugharred.se;
    
    # Static files
    location / {
        root /var/www/html;
        try_files $uri $uri/ /index.html;
        
        # Cache static assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|webp)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
    
    # API endpoints
    location /api/ {
        proxy_pass http://127.0.0.1:3010;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # WebSocket
    location /ws {
        proxy_pass http://127.0.0.1:3010;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
    
    # SSL (Let's Encrypt)
    listen 443 ssl;
    ssl_certificate /etc/letsencrypt/live/mugharred.se/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/mugharred.se/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
}

# HTTP redirect
server {
    if ($host = mugharred.se) {
        return 301 https://$host$request_uri;
    }
    server_name mugharred.se;
    listen 80;
    return 404;
}
```

## Redis Configuration

### Basic Setup
```bash
# Install Redis
sudo apt update
sudo apt install redis-server

# Start and enable
sudo systemctl start redis-server
sudo systemctl enable redis-server

# Verify
redis-cli ping
# Should return: PONG
```

### Security
```bash
# Edit /etc/redis/redis.conf
# Set password
requirepass your_redis_password

# Bind to localhost only
bind 127.0.0.1

# Restart
sudo systemctl restart redis-server
```

## SSL Certificate

### Let's Encrypt Setup
```bash
# Install Certbot
sudo apt install certbot python3-certbot-nginx

# Get certificate
sudo certbot --nginx -d mugharred.se

# Auto-renewal (already configured)
sudo crontab -l | grep certbot
```

## Process Management

### Manual Start
```bash
# Backend
cd /home/reda/development/mugharred/backend
nohup node dist/server.js > /dev/null 2>&1 &

# Check status
ps aux | grep "node.*server"
curl http://localhost:3010/health
```

### Systemd Service (Recommended)
```bash
# Create service file
sudo nano /etc/systemd/system/mugharred.service
```

```ini
[Unit]
Description=Mugharred Backend
After=network.target

[Service]
Type=simple
User=reda
WorkingDirectory=/home/reda/development/mugharred/backend
ExecStart=/usr/bin/node dist/server.js
Restart=always
RestartSec=10
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
```

```bash
# Enable and start
sudo systemctl daemon-reload
sudo systemctl enable mugharred
sudo systemctl start mugharred

# Check status
sudo systemctl status mugharred
```

## Deployment Script

### Create: `scripts/deploy-production.sh`
```bash
#!/bin/bash
set -e

echo "🚀 DEPLOYING TO PRODUCTION"

# Build backend
cd backend
npm run build

# Build frontend  
cd ../frontend
npm run build

# Deploy frontend
sudo cp -r dist/* /var/www/html/

# Restart backend service
sudo systemctl restart mugharred

# Verify deployment
sleep 5
curl -s http://localhost:3010/health | jq '.status'

echo "✅ DEPLOYMENT COMPLETE"
echo "Live at: https://mugharred.se"
```

## Monitoring

### Health Check
```bash
curl https://mugharred.se/api/health
```

Expected response:
```json
{
  "status": "ok",
  "timestamp": 1234567890,
  "auth": "jwt", 
  "storage": "redis",
  "rooms": 0,
  "participants": 0,
  "websockets": 0
}
```

### Logs
```bash
# Backend logs (if using systemd)
sudo journalctl -u mugharred -f

# Nginx logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# Redis logs
sudo tail -f /var/log/redis/redis-server.log
```

## Security

### Firewall (ufw)
```bash
# Basic rules
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 443
sudo ufw enable
```

### File Permissions
```bash
# Web files
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 644 /var/www/html
sudo find /var/www/html -type d -exec chmod 755 {} \;

# Backend files
sudo chown -R reda:reda /home/reda/development/mugharred
chmod +x scripts/*.sh
```

## Troubleshooting

### Common Issues

1. **Backend not starting**
   ```bash
   # Check port in use
   sudo lsof -i :3010
   
   # Check logs
   sudo journalctl -u mugharred --no-pager
   ```

2. **Redis connection failed**
   ```bash
   # Check Redis status
   sudo systemctl status redis-server
   
   # Test connection
   redis-cli ping
   ```

3. **SSL certificate issues**
   ```bash
   # Check certificate
   sudo certbot certificates
   
   # Renew if needed
   sudo certbot renew
   ```

4. **WebSocket not connecting**
   ```bash
   # Check nginx config
   sudo nginx -t
   
   # Reload nginx
   sudo systemctl reload nginx
   ```

## Backup Strategy

### Automated Backup (Optional)
```bash
# Create backup script
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/home/reda/backups/$DATE"

mkdir -p $BACKUP_DIR

# Backup application code
tar -czf $BACKUP_DIR/mugharred-app.tar.gz /home/reda/development/mugharred

# Backup nginx config
cp /etc/nginx/sites-available/mugharred $BACKUP_DIR/

# Redis data (if needed)
cp /var/lib/redis/dump.rdb $BACKUP_DIR/ 2>/dev/null || true

echo "Backup created: $BACKUP_DIR"
```

## Performance Optimization

### Nginx Optimizations
- Gzip compression enabled
- Static file caching (1 year)
- HTTP/2 support
- Keep-alive connections

### Backend Optimizations  
- JWT stateless (no session lookup)
- Redis connection pooling
- WebSocket connection limits
- Auto-cleanup inactive rooms

## Scaling Considerations

### Horizontal Scaling
- Load balancer (nginx upstream)
- Redis Cluster for multiple instances
- WebSocket sticky sessions
- CDN for static assets

### Monitoring
- Application metrics
- Redis performance monitoring
- nginx access/error logs
- System resource monitoring