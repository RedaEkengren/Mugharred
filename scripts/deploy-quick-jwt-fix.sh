#!/bin/bash
# Deploy a quick fix to get JWT working on frontend
set -e

echo "🚀 QUICK JWT FIX DEPLOYMENT"

cd /home/reda/development/mugharred/frontend

# Remove the broken modifications
git checkout -- src/MugharredLandingPage.tsx 2>/dev/null || true

# Add a simple wrapper to handle JWT auth on existing component
cat > src/jwt-wrapper.ts << 'EOF'
// JWT wrapper for API calls
const TOKEN_KEY = 'mugharred_token';

export function getToken(): string | null {
  return localStorage.getItem(TOKEN_KEY);
}

export function setToken(token: string) {
  localStorage.setItem(TOKEN_KEY, token);
}

export function clearToken() {
  localStorage.removeItem(TOKEN_KEY);
}

// Override fetch to add JWT token
const originalFetch = window.fetch;
window.fetch = function(...args: any[]): Promise<Response> {
  let [url, options] = args;
  
  // Only intercept API calls
  if (typeof url === 'string' && url.startsWith('/api/')) {
    const token = getToken();
    
    options = options || {};
    options.headers = options.headers || {};
    
    if (token) {
      options.headers['Authorization'] = `Bearer ${token}`;
    }
    
    // Skip CSRF endpoint
    if (url === '/api/csrf-token') {
      return Promise.resolve(new Response(JSON.stringify({ csrfToken: 'jwt-no-csrf-needed' }), {
        status: 200,
        headers: { 'Content-Type': 'application/json' }
      }));
    }
  }
  
  return originalFetch.apply(this, args).then(async (response) => {
    // Save token from login response
    if (url === '/api/login' && response.ok) {
      const clonedResponse = response.clone();
      const data = await clonedResponse.json();
      if (data.token) {
        setToken(data.token);
        // Modify response to include sessionId for compatibility
        const modifiedData = { ...data, sessionId: data.token };
        return new Response(JSON.stringify(modifiedData), {
          status: response.status,
          statusText: response.statusText,
          headers: response.headers
        });
      }
    }
    
    // Handle room creation response
    if (url === '/api/create-room' && response.ok) {
      const clonedResponse = response.clone();
      const data = await clonedResponse.json();
      if (data.token) {
        setToken(data.token);
      }
    }
    
    return response;
  });
};

// Export for manual use
export const JWTWrapper = {
  getToken,
  setToken,
  clearToken
};
EOF

# Add import to main.tsx
sed -i '1i\import "./jwt-wrapper.js";' src/main.tsx

echo "Building frontend with JWT wrapper..."
npm run build

echo "Deploying to nginx..."
sudo cp -r dist/* /var/www/html/

echo "✅ JWT wrapper deployed! Frontend should now work with JWT backend."
echo ""
echo "The wrapper:"
echo "- Intercepts all /api/* calls and adds JWT token"
echo "- Saves token from login response"
echo "- Fakes CSRF token endpoint for compatibility"
echo "- Maps JWT responses to session format"