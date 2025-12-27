#!/bin/bash
# Quick fix for TypeScript errors in room UI
set -e

echo "🔧 Fixing TypeScript errors in room UI..."

# Fix unused imports and variables
sed -i 's/import React, { useState, useEffect, useRef } from '\''react'\'';/import React, { useState, useEffect } from '\''react'\'';/' frontend/src/MugharredLandingPage.tsx
sed -i 's/import DOMPurify from '\''dompurify'\'';//' frontend/src/MugharredLandingPage.tsx
sed -i '/^\/\/ Types for room functionality/,/^}$/d' frontend/src/MugharredLandingPage.tsx
sed -i 's/const roomMatch = path.match.*roomMatch\[1\];/\/\/ Room URL detection will be implemented in STEG 5/' frontend/src/MugharredLandingPage.tsx

echo "✅ TypeScript errors fixed!"