#!/bin/bash
set -e

# Färgkoder
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}🧹 Clear Nginx Cache Script${NC}"
echo "============================="

echo -e "${YELLOW}🔄 Restartar nginx för att rensa cache...${NC}"
echo "899118RKs" | sudo -S systemctl reload nginx

echo -e "${YELLOW}🗑️ Rensar eventuella nginx cache-filer...${NC}"
echo "899118RKs" | sudo -S find /var/cache/nginx -type f -delete 2>/dev/null || true

echo -e "${YELLOW}📱 Ändrar asset-filnamn för att tvinga browser-uppdatering...${NC}"
# Lägg till timestamp för att garantera ny asset-fil
cd frontend
npm run build

echo -e "${YELLOW}🚀 Deployar med nya asset-namn...${NC}"
echo "899118RKs" | sudo -S rsync -av --delete dist/ /var/www/html/

echo -e "${GREEN}✅ Nginx cache rensad och nya assets deployade${NC}"
echo "Browser cache rensas automatiskt pga nya filnamn"