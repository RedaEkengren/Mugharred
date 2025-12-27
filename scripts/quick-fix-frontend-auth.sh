#!/bin/bash
# Quick fix to make frontend work with JWT backend
set -e

echo "🔧 QUICK FIX: Frontend JWT Auth"

cd /home/reda/development/mugharred/frontend

# First, let's just comment out the CSRF class and add a simple JWT helper
cat > src/simple-jwt-api.ts << 'EOF'
// Simple JWT API client until we can properly integrate the full JWT system

export class SimpleJWTAPI {
  private static token: string | null = null;

  static setToken(token: string) {
    this.token = token;
    localStorage.setItem('mugharred_token', token);
  }

  static getToken(): string | null {
    if (!this.token) {
      this.token = localStorage.getItem('mugharred_token');
    }
    return this.token;
  }

  static clearToken() {
    this.token = null;
    localStorage.removeItem('mugharred_token');
  }

  static async request(url: string, options: RequestInit = {}): Promise<any> {
    const token = this.getToken();
    const headers: any = {
      'Content-Type': 'application/json',
      ...options.headers,
    };
    
    if (token) {
      headers.Authorization = `Bearer ${token}`;
    }

    const response = await fetch(url, {
      ...options,
      headers,
      credentials: 'include',
    });

    const data = await response.json();

    // If login endpoint, save the token
    if (url.includes('/api/login') && response.ok && data.token) {
      this.setToken(data.token);
    }

    return { ok: response.ok, data, response };
  }
}
EOF

# Add import to MugharredLandingPage.tsx
sed -i '1i\import { SimpleJWTAPI } from "./simple-jwt-api.js";' src/MugharredLandingPage.tsx

# Replace SecureAPI.secureRequest with SimpleJWTAPI.request
sed -i 's/SecureAPI\.secureRequest/SimpleJWTAPI.request/g' src/MugharredLandingPage.tsx
sed -i 's/SecureAPI\.clearToken/SimpleJWTAPI.clearToken/g' src/MugharredLandingPage.tsx

# Fix response handling
sed -i 's/const data = await response\.json();/const { data } = await response;/g' src/MugharredLandingPage.tsx
sed -i 's/if (response\.ok)/if (response.ok)/g' src/MugharredLandingPage.tsx

# Comment out the CSRF methods in SecureAPI class
sed -i '/static async getCsrfToken/,/^  }$/s/^/\/\/ /' src/MugharredLandingPage.tsx

echo "Building frontend..."
npm run build

echo "✅ Quick fix applied! Frontend should now work with JWT backend."