#!/bin/bash
set -e

# Färgkoder
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}🧹 Clean Debug Script${NC}"
echo "=========================="

# Kontrollera att vi är i rätt katalog
if [ ! -f "frontend/src/MugharredLandingPage.tsx" ]; then
    echo -e "${RED}❌ FEL: frontend/src/MugharredLandingPage.tsx hittades inte${NC}"
    exit 1
fi

echo -e "${YELLOW}🔍 Letar efter debug-kod...${NC}"

# Kontrollera om debug-kod finns
DEBUG_COUNT=$(grep -c "console.log.*LOGIN" frontend/src/MugharredLandingPage.tsx || true)

if [ "$DEBUG_COUNT" -eq 0 ]; then
    echo -e "${GREEN}✅ Ingen debug-kod hittad${NC}"
    exit 0
fi

echo -e "${YELLOW}📋 Skapar backup innan rensning...${NC}"
cp frontend/src/MugharredLandingPage.tsx frontend/src/MugharredLandingPage.tsx.pre-debug-clean

echo -e "${YELLOW}🧹 Tar bort debug-kod...${NC}"

# Ta bort alla debug console.log rader
sed -i '/console.log.*LOGIN.*\/\/ Debug/d' frontend/src/MugharredLandingPage.tsx

# Verifiera att debug-kod är borttagen
REMAINING_DEBUG=$(grep -c "console.log.*LOGIN" frontend/src/MugharredLandingPage.tsx || true)

if [ "$REMAINING_DEBUG" -eq 0 ]; then
    echo -e "${GREEN}✅ Debug-kod borttagen${NC}"
    echo "Backup: frontend/src/MugharredLandingPage.tsx.pre-debug-clean"
else
    echo -e "${RED}❌ Debug-kod kvarvarande${NC}"
    exit 1
fi