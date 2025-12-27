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
