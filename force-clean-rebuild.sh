#!/bin/bash
set -e

# Färgkoder
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}🧹 Force Clean Rebuild Script${NC}"
echo "================================"

cd frontend

echo -e "${YELLOW}🗑️ Rensar alla cache och build-filer...${NC}"
rm -rf dist/
rm -rf node_modules/.vite/
rm -rf node_modules/.cache/
rm -rf .vite/

echo -e "${YELLOW}🔄 Reinstallerar node_modules...${NC}"
rm -rf node_modules/
npm install

echo -e "${YELLOW}🏗️ Bygger frontend från scratch...${NC}"
npm run build

echo -e "${YELLOW}🔍 Verifierar att mock-meddelandet är borta...${NC}"
if grep -q "Koppla detta" dist/assets/*.js; then
    echo -e "${RED}❌ Mock-meddelandet finns kvar!${NC}"
    echo "Hittade i:"
    grep -l "Koppla detta" dist/assets/*.js
    exit 1
else
    echo -e "${GREEN}✅ Mock-meddelandet är borttaget från byggd fil${NC}"
fi

cd ..
echo -e "${GREEN}✅ Clean rebuild klar${NC}"