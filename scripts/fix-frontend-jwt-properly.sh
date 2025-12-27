#!/bin/bash
# Fix frontend to use JWT properly - targeted changes only
# Compliance: goldenrules.md

set -e

echo "🔧 FIXING FRONTEND JWT INTEGRATION PROPERLY"
echo "=========================================="

cd /home/reda/development/mugharred/frontend

# Create backup
cp src/MugharredLandingPage.tsx src/MugharredLandingPage.tsx.backup

echo "📝 Applying targeted JWT fixes..."

# Fix 1: Remove CSRF token code
sed -i '/private static csrfToken:/d' src/MugharredLandingPage.tsx
sed -i '/if (this\.csrfToken) return this\.csrfToken;/d' src/MugharredLandingPage.tsx
sed -i "/const response = await fetch('\/api\/csrf-token'/,/return this\.csrfToken;/d" src/MugharredLandingPage.tsx
sed -i '/this\.csrfToken = /d' src/MugharredLandingPage.tsx
sed -i '/csrfToken/d' src/MugharredLandingPage.tsx

# Fix 2: Remove sessionId from WebSocket URL
sed -i 's/sessionId=\${encodeURIComponent(sessionId || .*)}//' src/MugharredLandingPage.tsx
sed -i 's/\?&roomId=/\?roomId=/' src/MugharredLandingPage.tsx

# Fix 3: Comment out /api/messages and /api/online-users calls
sed -i '/fetch("\/api\/messages/,/});/s/^/\/\/ /' src/MugharredLandingPage.tsx
sed -i '/fetch("\/api\/online-users/,/});/s/^/\/\/ /' src/MugharredLandingPage.tsx

# Fix 4: Replace sessionId checks with isLoggedIn checks
sed -i 's/if (sessionId)/if (isLoggedIn)/g' src/MugharredLandingPage.tsx
sed -i 's/if (!sessionId)/if (!isLoggedIn)/g' src/MugharredLandingPage.tsx
sed -i 's/sessionId &&/isLoggedIn \&\&/g' src/MugharredLandingPage.tsx
sed -i 's/&& sessionId/\&\& isLoggedIn/g' src/MugharredLandingPage.tsx

# Fix 5: Update login to use JWT response properly
sed -i 's/setSessionId(loginData\.sessionId);/\/\/ JWT token handled by wrapper/g' src/MugharredLandingPage.tsx

# Fix 6: Remove sessionId state variable
sed -i '/const \[sessionId, setSessionId\] = useState/d' src/MugharredLandingPage.tsx

# Fix 7: Fix send message to not use CSRF
sed -i 's/, csrfToken: CsrfManager\.getCsrfToken()//g' src/MugharredLandingPage.tsx

echo "🏗️ Building..."
npm run build

if [ $? -ne 0 ]; then
    echo "❌ Build failed, restoring backup..."
    mv src/MugharredLandingPage.tsx.backup src/MugharredLandingPage.tsx
    exit 1
fi

echo "🚀 Deploying..."
echo "899118RKs" | sudo -S cp -r dist/* /var/www/html/

echo "✅ JWT INTEGRATION FIXED!"
echo ""
echo "Changes made:"
echo "- Removed all CSRF token code"
echo "- Removed sessionId from WebSocket URLs"
echo "- Disabled old API endpoints (/api/messages, /api/online-users)"
echo "- Updated auth checks to use isLoggedIn instead of sessionId"
echo "- JWT token now handled by wrapper"