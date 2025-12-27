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
    
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
      ...(options.headers as Record<string, string> || {}),
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
