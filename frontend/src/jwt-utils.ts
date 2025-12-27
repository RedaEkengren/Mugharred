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
