#!/bin/bash

# Färgkoder
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}🔍 Verifierar Deploy${NC}"
echo "===================="

# 1. Kontrollera att rätt index.html serveras
echo -e "\n${YELLOW}1. Kontrollerar index.html...${NC}"
ASSETS=$(curl -s https://mugharred.se | grep -o '/assets/index-[^"]*' | sort -u)
echo "Assets som refereras i index.html:"
echo "$ASSETS"

# 2. Lista faktiska asset-filer
echo -e "\n${YELLOW}2. Faktiska asset-filer på servern:${NC}"
ls -la /var/www/html/assets/ | grep index-

# 3. Verifiera att JS-filen är tillgänglig
echo -e "\n${YELLOW}3. Testar JS-fil...${NC}"
JS_FILE=$(echo "$ASSETS" | grep '\.js$' | head -1)
if [ ! -z "$JS_FILE" ]; then
    STATUS=$(curl -sI "https://mugharred.se$JS_FILE" | head -1)
    echo "JS-fil status: $STATUS"
fi

# 4. Verifiera att CSS-filen är tillgänglig
echo -e "\n${YELLOW}4. Testar CSS-fil...${NC}"
CSS_FILE=$(echo "$ASSETS" | grep '\.css$' | head -1)
if [ ! -z "$CSS_FILE" ]; then
    STATUS=$(curl -sI "https://mugharred.se$CSS_FILE" | head -1)
    echo "CSS-fil status: $STATUS"
fi

# 5. Kontrollera nginx error log
echo -e "\n${YELLOW}5. Senaste nginx-fel:${NC}"
sudo tail -5 /var/log/nginx/mugharred.error.log | grep -v "SSL_do_handshake" || echo "Inga fel!"

# 6. Verifiera att backend API fungerar
echo -e "\n${YELLOW}6. Backend API status:${NC}"
curl -s https://mugharred.se/health

echo -e "\n${GREEN}✅ Verifiering klar!${NC}"