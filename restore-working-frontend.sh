#!/bin/bash
set -e

# Färgkoder
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}🔄 Restore Working Frontend Script${NC}"
echo "===================================="

# Kontrollera att backup finns
if [ ! -f "frontend/src/MugharredLandingPage.tsx.backup" ]; then
    echo -e "${RED}❌ FEL: Backup fil hittades inte${NC}"
    exit 1
fi

echo -e "${YELLOW}📋 Skapar backup av nuvarande version...${NC}"
cp frontend/src/MugharredLandingPage.tsx frontend/src/MugharredLandingPage.tsx.broken-version

echo -e "${YELLOW}🔄 Återställer från backup med fungerande backend-koppling...${NC}"
cp frontend/src/MugharredLandingPage.tsx.backup frontend/src/MugharredLandingPage.tsx

echo -e "${YELLOW}🔍 Verifierar att SecureAPI finns...${NC}"
if grep -q "SecureAPI.secureRequest" frontend/src/MugharredLandingPage.tsx; then
    echo -e "${GREEN}✅ Backend-koppling återställd${NC}"
else
    echo -e "${RED}❌ Backend-koppling saknas fortfarande${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Frontend återställd till fungerande version${NC}"
echo "Broken version sparad som: frontend/src/MugharredLandingPage.tsx.broken-version"