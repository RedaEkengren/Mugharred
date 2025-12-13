#!/bin/bash
set -e

# Färgkoder för output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Deploy Frontend Script${NC}"
echo "================================"

# Kontrollera att vi är i root-katalogen
if [ ! -f "package.json" ] || [ ! -d "frontend" ]; then
    echo -e "${RED}❌ FEL: Kör detta script från projektets root-katalog${NC}"
    exit 1
fi

# Bygg frontend
echo -e "${YELLOW}📦 Bygger frontend...${NC}"
cd frontend && npm install && npm run build && cd ..

# Kontrollera att index.html finns
if [ ! -f "frontend/dist/index.html" ]; then
    echo -e "${RED}❌ FEL: frontend/dist/index.html saknas efter bygge${NC}"
    exit 1
fi

# Verifiera att frontend/dist/index.html finns
if [ ! -f "frontend/dist/index.html" ]; then
    echo -e "${RED}❌ FEL: frontend/dist/index.html saknas efter kopiering${NC}"
    exit 1
fi

# Extrahera asset-filnamn från index.html
echo -e "${YELLOW}🔍 Verifierar asset-referenser i index.html...${NC}"
CSS_FILE=$(grep -o 'href="/assets/index-[^"]*\.css"' frontend/dist/index.html | sed 's/href="\/assets\///' | sed 's/"//')
JS_FILE=$(grep -o 'src="/assets/index-[^"]*\.js"' frontend/dist/index.html | sed 's/src="\/assets\///' | sed 's/"//')

echo "CSS: $CSS_FILE"
echo "JS: $JS_FILE"

# Verifiera att asset-filerna finns
if [ ! -f "frontend/dist/assets/$CSS_FILE" ]; then
    echo -e "${RED}❌ FEL: CSS-fil saknas: frontend/dist/assets/$CSS_FILE${NC}"
    exit 1
fi

if [ ! -f "frontend/dist/assets/$JS_FILE" ]; then
    echo -e "${RED}❌ FEL: JS-fil saknas: frontend/dist/assets/$JS_FILE${NC}"
    exit 1
fi

# Deploy till /var/www/html med rsync
echo -e "${YELLOW}🚀 Deployar till /var/www/html...${NC}"
sudo rsync -av --delete frontend/dist/ /var/www/html/

# Visa deployade filer
echo -e "${GREEN}✅ Deploy lyckades!${NC}"
echo ""
echo "Deployade filer:"
ls -la /var/www/html/
echo ""
echo "Assets:"
ls -la /var/www/html/assets/

# Ladda om nginx
echo -e "${YELLOW}🔄 Laddar om Nginx...${NC}"
sudo nginx -s reload

echo -e "${GREEN}✅ Deploy komplett!${NC}"
echo ""
echo "Verifiera med:"
echo "  curl -s https://mugharred.se | grep -o '/assets/index-[^\"]*'"
echo "  curl -I https://mugharred.se/assets/$JS_FILE"