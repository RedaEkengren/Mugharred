import jwt from 'jsonwebtoken';
import { randomUUID } from 'crypto';

const JWT_SECRET = process.env.JWT_SECRET || 'your-jwt-secret-change-in-production';
const JWT_EXPIRY = '1h';

export interface JWTPayload {
  userId: string;
  name: string;
  roomId?: string;
  role?: 'host' | 'participant';
  iat?: number;
  exp?: number;
}

export class JWTAuth {
  static generateToken(payload: Omit<JWTPayload, 'iat' | 'exp'>): string {
    return jwt.sign(payload, JWT_SECRET, { 
      expiresIn: JWT_EXPIRY,
      jwtid: randomUUID()
    });
  }

  static verifyToken(token: string): JWTPayload {
    try {
      return jwt.verify(token, JWT_SECRET) as JWTPayload;
    } catch (error) {
      throw new Error('Invalid or expired token');
    }
  }

  static refreshToken(token: string): string {
    const payload = this.verifyToken(token);
    // Generate new token with fresh expiry
    const { iat, exp, ...refreshPayload } = payload;
    return this.generateToken(refreshPayload);
  }

  static extractTokenFromRequest(req: any): string | null {
    // Check Authorization header
    const authHeader = req.headers.authorization;
    if (authHeader?.startsWith('Bearer ')) {
      return authHeader.slice(7);
    }

    // Check query parameter (for WebSocket)
    if (req.query?.token) {
      return req.query.token;
    }

    // Check URL search params (for WebSocket)
    if (req.url) {
      const url = new URL(req.url, `http://${req.headers.host}`);
      return url.searchParams.get('token');
    }

    return null;
  }
}
