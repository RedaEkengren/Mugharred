#!/bin/bash
# Update frontend to use JWT API instead of CSRF
# Compliance: goldenrules.md

set -e

echo "🔧 UPDATING FRONTEND API CALLS"

cd /home/reda/development/mugharred/frontend

# Backup current file
cp src/MugharredLandingPage.tsx src/MugharredLandingPage.tsx.backup.$(date +%Y%m%d_%H%M%S)

# Fix the main component to handle JWT responses properly
echo "Updating API calls in MugharredLandingPage.tsx..."

# Update the handleLogin function to use JWT
sed -i '/const handleLogin = async/,/} catch (error)/ {
    s/const response = await SecureAPI\.secureRequest/const apiResponse = await JWTApiClient.request/
    s/if (!response\.ok)/if (!apiResponse.ok)/
    s/const data = await response\.json();/const data = apiResponse.data;/
}' src/MugharredLandingPage.tsx

# Update the createRoom function to use JWT
sed -i '/const response = await SecureAPI\.secureRequest.*create-room/,/} catch/ {
    s/const response = await SecureAPI\.secureRequest/const apiResponse = await JWTApiClient.request/
    s/if (!response\.ok)/if (!apiResponse.ok)/
    s/const data = await response\.json();/const data = apiResponse.data;/
}' src/MugharredLandingPage.tsx

# Update the joinRoom function to use JWT
sed -i '/const response = await SecureAPI\.secureRequest.*join-room/,/} catch/ {
    s/const response = await SecureAPI\.secureRequest/const apiResponse = await JWTApiClient.request/
    s/if (!response\.ok)/if (!apiResponse.ok)/
    s/const data = await response\.json();/const data = apiResponse.data;/
}' src/MugharredLandingPage.tsx

# Update room info fetch to use JWT
sed -i '/const response = await fetch.*\/api\/room\//,/} catch/ {
    s/const response = await fetch/const apiResponse = await JWTApiClient.request/
    s/if (!response\.ok)/if (!apiResponse.ok)/
    s/const data = await response\.json();/const data = apiResponse.data;/
}' src/MugharredLandingPage.tsx

# Comment out the SecureAPI class entirely
sed -i '/^class SecureAPI {/,/^}$/ s/^/\/\/ /' src/MugharredLandingPage.tsx

echo "✅ Frontend API calls updated"
echo ""
echo "Building frontend..."
npm run build

echo "✅ Frontend built successfully"
echo ""
echo "Next: Deploy frontend dist to nginx"