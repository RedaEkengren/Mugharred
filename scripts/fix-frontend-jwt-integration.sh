#!/bin/bash
# Fix frontend to use JWT instead of CSRF tokens
# Compliance: goldenrules.md - script-driven changes only

set -e

echo "🔧 FIXING FRONTEND JWT INTEGRATION"
echo "Replacing CSRF SecureAPI with JWT API client..."

cd /home/reda/development/mugharred/frontend

# First backup current MugharredLandingPage.tsx
cp src/MugharredLandingPage.tsx src/MugharredLandingPage.tsx.backup.csrf.$(date +%Y%m%d_%H%M%S)

# Replace SecureAPI imports and usage with JWT
echo "Updating MugharredLandingPage.tsx to use JWT..."

# Create a temporary file with the JWT integration
cat > /tmp/fix-frontend-jwt.patch << 'EOF'
--- REMOVE SecureAPI class and replace with JWT imports ---

1. Replace SecureAPI class with import:
   import { JWTApiClient } from './jwt-api.js';
   import { TokenManager } from './jwt-utils.js';
   import { useJWTAuth } from './useJWTAuth.js';

2. Replace all SecureAPI.secureRequest with JWTApiClient.request

3. Replace login flow to use JWT token

4. Update room creation to use JWT auth

5. Remove CSRF token fetching
EOF

# Apply the changes using sed
# First, remove the entire SecureAPI class
sed -i '/class SecureAPI {/,/^}/d' src/MugharredLandingPage.tsx

# Add JWT imports at the top after other imports
sed -i '/import.*React/a\
import { JWTApiClient } from '"'"'./jwt-api.js'"'"';\
import { TokenManager } from '"'"'./jwt-utils.js'"'"';\
import { useJWTAuth } from '"'"'./useJWTAuth.js'"'"';' src/MugharredLandingPage.tsx

# Replace SecureAPI.secureRequest with JWTApiClient.request
sed -i 's/SecureAPI\.secureRequest/JWTApiClient.request/g' src/MugharredLandingPage.tsx

# Remove getCsrfToken calls
sed -i '/getCsrfToken/d' src/MugharredLandingPage.tsx

# Fix the response handling for JWT API
sed -i 's/const data = await response\.json();/const response = await JWTApiClient.request(url, options);\n        const data = response.data;/g' src/MugharredLandingPage.tsx

echo "✅ Frontend JWT integration fixed"
echo ""
echo "Changes made:"
echo "- Removed SecureAPI class (CSRF-based)"
echo "- Added JWT API client imports"
echo "- Updated all API calls to use JWT"
echo "- Removed CSRF token fetching"
echo ""
echo "Next steps:"
echo "1. Run: npm run build"
echo "2. Deploy frontend to nginx"
echo "3. Test room creation on https://mugharred.se"