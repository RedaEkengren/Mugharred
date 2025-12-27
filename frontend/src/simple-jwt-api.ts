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
