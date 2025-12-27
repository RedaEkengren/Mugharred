#!/bin/bash
# PHASE 1 REWRITE: Frontend Token Management
# Replace session handling with JWT token management
# Compliance: goldenrules.md - script-driven changes only

set -e

echo "🎨 IMPLEMENTING FRONTEND TOKEN MANAGEMENT"
echo "Replacing session handling with JWT token management..."

# Navigate to frontend
cd /home/reda/development/mugharred/frontend

# Create JWT token utilities
echo "Creating JWT token utilities..."
cat > src/jwt-utils.ts << 'EOF'
export interface User {
  userId: string;
  name: string;
  roomId?: string;
  role?: 'host' | 'participant';
}

export interface JWTPayload extends User {
  iat?: number;
  exp?: number;
}

export class TokenManager {
  private static readonly TOKEN_KEY = 'mugharred_token';
  private static readonly REFRESH_THRESHOLD = 5 * 60 * 1000; // 5 minutes

  static getToken(): string | null {
    try {
      return localStorage.getItem(this.TOKEN_KEY);
    } catch {
      return null;
    }
  }

  static setToken(token: string): void {
    try {
      localStorage.setItem(this.TOKEN_KEY, token);
    } catch (error) {
      console.warn('Failed to store token:', error);
    }
  }

  static removeToken(): void {
    try {
      localStorage.removeItem(this.TOKEN_KEY);
    } catch (error) {
      console.warn('Failed to remove token:', error);
    }
  }

  static decodeToken(token: string): JWTPayload | null {
    try {
      const payload = JSON.parse(atob(token.split('.')[1]));
      return payload;
    } catch {
      return null;
    }
  }

  static isTokenExpired(token: string): boolean {
    const payload = this.decodeToken(token);
    if (!payload?.exp) return true;
    
    return Date.now() >= payload.exp * 1000;
  }

  static needsRefresh(token: string): boolean {
    const payload = this.decodeToken(token);
    if (!payload?.exp) return true;
    
    const timeUntilExpiry = (payload.exp * 1000) - Date.now();
    return timeUntilExpiry < this.REFRESH_THRESHOLD;
  }

  static getUser(): User | null {
    const token = this.getToken();
    if (!token || this.isTokenExpired(token)) {
      this.removeToken();
      return null;
    }
    
    const payload = this.decodeToken(token);
    if (!payload) return null;

    return {
      userId: payload.userId,
      name: payload.name,
      roomId: payload.roomId,
      role: payload.role
    };
  }

  static isAuthenticated(): boolean {
    const token = this.getToken();
    return token !== null && !this.isTokenExpired(token);
  }
}
EOF

# Create secure API client with JWT
echo "Creating JWT-based API client..."
cat > src/jwt-api.ts << 'EOF'
import { TokenManager } from './jwt-utils.js';

interface APIResponse<T = any> {
  ok: boolean;
  status: number;
  data: T;
  error?: string;
}

export class JWTApiClient {
  private static baseUrl = '';

  static async request<T = any>(endpoint: string, options: RequestInit = {}): Promise<APIResponse<T>> {
    const token = TokenManager.getToken();
    
    const headers: HeadersInit = {
      'Content-Type': 'application/json',
      ...options.headers,
    };

    // Add authorization header if we have a token
    if (token) {
      headers.Authorization = `Bearer ${token}`;
    }

    try {
      const response = await fetch(`${this.baseUrl}${endpoint}`, {
        ...options,
        headers,
        credentials: 'include'
      });

      let data: T;
      try {
        data = await response.json();
      } catch {
        data = {} as T;
      }

      if (!response.ok) {
        // Handle token expiry
        if (response.status === 401) {
          TokenManager.removeToken();
          window.dispatchEvent(new CustomEvent('token-expired'));
        }
        
        return {
          ok: false,
          status: response.status,
          data,
          error: (data as any)?.error || `HTTP ${response.status}`
        };
      }

      return {
        ok: true,
        status: response.status,
        data
      };

    } catch (error) {
      console.error('API request failed:', error);
      return {
        ok: false,
        status: 0,
        data: {} as T,
        error: 'Network error'
      };
    }
  }

  static async login(name: string): Promise<APIResponse<{ token: string; user: any }>> {
    const response = await this.request<{ token: string; user: any }>('/api/login', {
      method: 'POST',
      body: JSON.stringify({ name })
    });

    if (response.ok && response.data.token) {
      TokenManager.setToken(response.data.token);
    }

    return response;
  }

  static async createRoom(name: string, maxParticipants: number, duration: number, hostName: string): Promise<APIResponse<{ roomId: string; token: string; room: any }>> {
    const response = await this.request<{ roomId: string; token: string; room: any }>('/api/create-room', {
      method: 'POST',
      body: JSON.stringify({
        name,
        maxParticipants,
        duration,
        hostName
      })
    });

    if (response.ok && response.data.token) {
      TokenManager.setToken(response.data.token);
    }

    return response;
  }

  static async joinRoom(roomId: string, participantName: string): Promise<APIResponse<{ success: boolean; token: string; room: any }>> {
    const response = await this.request<{ success: boolean; token: string; room: any }>('/api/join-room', {
      method: 'POST',
      body: JSON.stringify({
        roomId,
        participantName
      })
    });

    if (response.ok && response.data.token) {
      TokenManager.setToken(response.data.token);
    }

    return response;
  }

  static async getRoomInfo(roomId: string): Promise<APIResponse<any>> {
    return this.request(`/api/room/${roomId}`);
  }

  static async refreshToken(): Promise<APIResponse<{ token: string }>> {
    const response = await this.request<{ token: string }>('/api/refresh-token', {
      method: 'POST'
    });

    if (response.ok && response.data.token) {
      TokenManager.setToken(response.data.token);
    }

    return response;
  }

  static logout(): void {
    TokenManager.removeToken();
    window.dispatchEvent(new CustomEvent('token-expired'));
  }
}
EOF

# Create JWT WebSocket client
echo "Creating JWT WebSocket client..."
cat > src/jwt-websocket.ts << 'EOF'
import { TokenManager } from './jwt-utils.js';

export interface WebSocketMessage {
  type: string;
  [key: string]: any;
}

export type MessageHandler = (message: WebSocketMessage) => void;

export class JWTWebSocket {
  private ws: WebSocket | null = null;
  private reconnectAttempts = 0;
  private maxReconnectAttempts = 5;
  private reconnectDelay = 1000;
  private handlers = new Map<string, MessageHandler[]>();
  private isConnecting = false;
  private isManualClose = false;

  async connect(): Promise<boolean> {
    if (this.isConnecting || (this.ws && this.ws.readyState === WebSocket.OPEN)) {
      return true;
    }

    this.isConnecting = true;
    this.isManualClose = false;

    try {
      const token = TokenManager.getToken();
      if (!token) {
        throw new Error('No authentication token available');
      }

      // Check if token needs refresh
      if (TokenManager.needsRefresh(token)) {
        console.log('Token needs refresh before WebSocket connection');
        // Token refresh would be handled by the main app
        window.dispatchEvent(new CustomEvent('token-refresh-needed'));
        this.isConnecting = false;
        return false;
      }

      const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
      const wsUrl = `${protocol}//${window.location.host}/ws?token=${encodeURIComponent(token)}`;

      this.ws = new WebSocket(wsUrl);

      return new Promise((resolve, reject) => {
        if (!this.ws) {
          reject(new Error('Failed to create WebSocket'));
          return;
        }

        const connectTimeout = setTimeout(() => {
          this.ws?.close();
          reject(new Error('WebSocket connection timeout'));
        }, 10000);

        this.ws.onopen = () => {
          clearTimeout(connectTimeout);
          this.isConnecting = false;
          this.reconnectAttempts = 0;
          console.log('✅ WebSocket connected');
          
          // Send ping to test connection
          this.send({ type: 'ping' });
          
          resolve(true);
        };

        this.ws.onclose = (event) => {
          clearTimeout(connectTimeout);
          this.isConnecting = false;
          console.log('WebSocket closed:', { code: event.code, reason: event.reason });
          
          // Handle different close codes
          if (event.code === 1008) {
            // Invalid token
            TokenManager.removeToken();
            window.dispatchEvent(new CustomEvent('token-expired'));
            resolve(false);
            return;
          }

          // Auto-reconnect unless manually closed
          if (!this.isManualClose && this.reconnectAttempts < this.maxReconnectAttempts) {
            setTimeout(() => this.attemptReconnect(), this.reconnectDelay);
          }
          
          if (this.reconnectAttempts === 0) {
            resolve(false);
          }
        };

        this.ws.onerror = (error) => {
          clearTimeout(connectTimeout);
          console.error('WebSocket error:', error);
          reject(error);
        };

        this.ws.onmessage = (event) => {
          try {
            const message = JSON.parse(event.data) as WebSocketMessage;
            this.handleMessage(message);
          } catch (error) {
            console.error('Failed to parse WebSocket message:', error);
          }
        };
      });

    } catch (error) {
      this.isConnecting = false;
      console.error('WebSocket connection failed:', error);
      return false;
    }
  }

  private async attemptReconnect() {
    this.reconnectAttempts++;
    console.log(`Attempting WebSocket reconnection ${this.reconnectAttempts}/${this.maxReconnectAttempts}`);
    
    // Exponential backoff
    this.reconnectDelay = Math.min(this.reconnectDelay * 2, 30000);
    
    const connected = await this.connect();
    if (connected) {
      console.log('WebSocket reconnection successful');
      this.reconnectDelay = 1000; // Reset delay
    }
  }

  disconnect() {
    this.isManualClose = true;
    this.reconnectAttempts = this.maxReconnectAttempts; // Prevent auto-reconnect
    
    if (this.ws) {
      this.ws.close(1000, 'Manual disconnect');
      this.ws = null;
    }
  }

  send(message: WebSocketMessage): boolean {
    if (!this.ws || this.ws.readyState !== WebSocket.OPEN) {
      console.warn('WebSocket not connected, message not sent:', message);
      return false;
    }

    try {
      this.ws.send(JSON.stringify(message));
      return true;
    } catch (error) {
      console.error('Failed to send WebSocket message:', error);
      return false;
    }
  }

  on(type: string, handler: MessageHandler) {
    if (!this.handlers.has(type)) {
      this.handlers.set(type, []);
    }
    this.handlers.get(type)!.push(handler);
  }

  off(type: string, handler: MessageHandler) {
    const handlers = this.handlers.get(type);
    if (handlers) {
      const index = handlers.indexOf(handler);
      if (index > -1) {
        handlers.splice(index, 1);
      }
    }
  }

  private handleMessage(message: WebSocketMessage) {
    const handlers = this.handlers.get(message.type) || [];
    handlers.forEach(handler => {
      try {
        handler(message);
      } catch (error) {
        console.error('WebSocket message handler error:', error);
      }
    });

    // Handle built-in message types
    switch (message.type) {
      case 'pong':
        // Connection is healthy
        break;
        
      case 'connected':
        console.log('WebSocket connection confirmed:', message.user);
        break;
        
      case 'error':
        console.error('WebSocket server error:', message.error);
        break;
    }
  }

  isConnected(): boolean {
    return this.ws !== null && this.ws.readyState === WebSocket.OPEN;
  }

  getReadyState(): number {
    return this.ws?.readyState ?? WebSocket.CLOSED;
  }
}

// Export singleton instance
export const webSocket = new JWTWebSocket();
EOF

# Create React hook for JWT auth
echo "Creating React JWT auth hook..."
cat > src/useJWTAuth.ts << 'EOF'
import { useState, useEffect, useCallback } from 'react';
import { TokenManager, User } from './jwt-utils.js';
import { JWTApiClient } from './jwt-api.js';

export interface AuthState {
  user: User | null;
  isAuthenticated: boolean;
  isLoading: boolean;
}

export function useJWTAuth() {
  const [authState, setAuthState] = useState<AuthState>({
    user: null,
    isAuthenticated: false,
    isLoading: true
  });

  // Initialize auth state
  useEffect(() => {
    const user = TokenManager.getUser();
    setAuthState({
      user,
      isAuthenticated: user !== null,
      isLoading: false
    });
  }, []);

  // Listen for token expiry events
  useEffect(() => {
    const handleTokenExpired = () => {
      setAuthState({
        user: null,
        isAuthenticated: false,
        isLoading: false
      });
    };

    const handleTokenRefreshNeeded = async () => {
      try {
        const response = await JWTApiClient.refreshToken();
        if (response.ok) {
          const user = TokenManager.getUser();
          setAuthState(prev => ({
            ...prev,
            user,
            isAuthenticated: user !== null
          }));
        } else {
          handleTokenExpired();
        }
      } catch (error) {
        console.error('Token refresh failed:', error);
        handleTokenExpired();
      }
    };

    window.addEventListener('token-expired', handleTokenExpired);
    window.addEventListener('token-refresh-needed', handleTokenRefreshNeeded);

    return () => {
      window.removeEventListener('token-expired', handleTokenExpired);
      window.removeEventListener('token-refresh-needed', handleTokenRefreshNeeded);
    };
  }, []);

  // Auto-refresh token when needed
  useEffect(() => {
    if (!authState.isAuthenticated) return;

    const checkTokenRefresh = () => {
      const token = TokenManager.getToken();
      if (token && TokenManager.needsRefresh(token)) {
        window.dispatchEvent(new CustomEvent('token-refresh-needed'));
      }
    };

    // Check every minute
    const interval = setInterval(checkTokenRefresh, 60000);
    
    return () => clearInterval(interval);
  }, [authState.isAuthenticated]);

  const login = useCallback(async (name: string) => {
    setAuthState(prev => ({ ...prev, isLoading: true }));
    
    try {
      const response = await JWTApiClient.login(name);
      
      if (response.ok) {
        const user = TokenManager.getUser();
        setAuthState({
          user,
          isAuthenticated: user !== null,
          isLoading: false
        });
        return { success: true };
      } else {
        setAuthState(prev => ({ ...prev, isLoading: false }));
        return { success: false, error: response.error };
      }
    } catch (error) {
      setAuthState(prev => ({ ...prev, isLoading: false }));
      return { success: false, error: 'Network error' };
    }
  }, []);

  const logout = useCallback(() => {
    JWTApiClient.logout();
    setAuthState({
      user: null,
      isAuthenticated: false,
      isLoading: false
    });
  }, []);

  const updateUser = useCallback((updates: Partial<User>) => {
    setAuthState(prev => ({
      ...prev,
      user: prev.user ? { ...prev.user, ...updates } : null
    }));
  }, []);

  return {
    ...authState,
    login,
    logout,
    updateUser
  };
}
EOF

echo "✅ Frontend Token Management implemented"
echo "Next: Run scripts/implement-integration-testing.sh"
echo ""
echo "Frontend JWT Features implemented:"
echo "- Token storage and management utilities"
echo "- JWT-based API client with auto-refresh"
echo "- WebSocket client with JWT authentication"
echo "- React hooks for auth state management"
echo "- Automatic token refresh handling"
echo "- Token expiry event handling"
echo ""
echo "Ready for integration testing and main component updates."