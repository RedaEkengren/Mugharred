import React, { useMemo, useState, useEffect, useRef, useCallback } from "react";
import { 
  ArrowRight, Shield, Zap, Users, Globe2, Send, X, 
  CheckCircle2, AlertCircle, Loader2, LogOut, Eye
} from "lucide-react";
import DOMPurify from "dompurify";

type Message = {
  id: string;
  user: string;
  text: string;
  timestamp: number;
  sanitized?: boolean;
};


const ROW_HEIGHT = 88;
const ANIMATION_DELAY_UNIT = 0.1;

// Secure API utilities for CSRF protection
class SecureAPI {
  private static csrfToken: string = '';

  static async getCsrfToken(): Promise<string> {
    if (this.csrfToken) return this.csrfToken;
    
    try {
      const response = await fetch('/api/csrf-token', {
        method: 'GET',
        credentials: 'include',
      });
      
      if (response.ok) {
        const data = await response.json();
        this.csrfToken = data.csrfToken;
        return this.csrfToken;
      }
    } catch (error) {
      console.error('Failed to get CSRF token:', error);
    }
    
    return '';
  }

  static async secureRequest(url: string, options: RequestInit = {}): Promise<Response> {
    const token = await this.getCsrfToken();
    
    const headers = {
      'Content-Type': 'application/json',
      'X-CSRF-Token': token,
      ...options.headers,
    };

    return fetch(url, {
      ...options,
      credentials: 'include',
      headers,
    });
  }

  static clearToken() {
    this.csrfToken = '';
  }
}

export default function MugharredLandingPage() {
  // Login state
  const [sessionId, setSessionId] = useState<string | null>(null);
  const [name, setName] = useState("");
  const [loginError, setLoginError] = useState<string | null>(null);
  const [loginLoading, setLoginLoading] = useState(false);
  
  // Feed state
  const [ws, setWs] = useState<WebSocket | null>(null);
  const [messages, setMessages] = useState<Message[]>([]);
  const [onlineUsers, setOnlineUsers] = useState<string[]>([]);
  const [input, setInput] = useState("");
  const [expandedMessage, setExpandedMessage] = useState<Message | null>(null);
  const [wsConnected, setWsConnected] = useState(false);
  const [toast, setToast] = useState<{ message: string; type: 'success' | 'error' | 'info' } | null>(null);

  // Refs
  const containerRef = useRef<HTMLDivElement | null>(null);
  const inputRef = useRef<HTMLInputElement>(null);
  const heartbeatInterval = useRef<ReturnType<typeof setInterval> | null>(null);

  // Virtual scroll state
  const [scrollTop, setScrollTop] = useState(0);
  const [containerHeight, setContainerHeight] = useState(0);

  // Calculate visible range
  const { visibleStartIndex, visibleEndIndex, totalHeight, offsetY } = useMemo(() => {
    const startIndex = Math.floor(scrollTop / ROW_HEIGHT);
    const visibleCount = Math.ceil(containerHeight / ROW_HEIGHT);
    const endIndex = Math.min(startIndex + visibleCount + 1, messages.length);
    
    return {
      visibleStartIndex: Math.max(0, startIndex),
      visibleEndIndex: endIndex,
      totalHeight: messages.length * ROW_HEIGHT,
      offsetY: startIndex * ROW_HEIGHT
    };
  }, [scrollTop, containerHeight, messages.length]);

  const visibleMessages = messages.slice(visibleStartIndex, visibleEndIndex);

  // Handle scroll
  const handleScroll = useCallback((e: React.UIEvent<HTMLDivElement>) => {
    setScrollTop(e.currentTarget.scrollTop);
  }, []);

  // Update container height on resize
  useEffect(() => {
    const updateHeight = () => {
      if (containerRef.current) {
        setContainerHeight(containerRef.current.clientHeight);
      }
    };

    updateHeight();
    window.addEventListener('resize', updateHeight);
    return () => window.removeEventListener('resize', updateHeight);
  }, []);

  // Auto-scroll to bottom when new messages arrive
  useEffect(() => {
    if (containerRef.current && messages.length > 0) {
      const container = containerRef.current;
      const isNearBottom = container.scrollTop + container.clientHeight >= container.scrollHeight - 200;
      
      if (isNearBottom) {
        container.scrollTo({
          top: container.scrollHeight,
          behavior: 'smooth'
        });
      }
    }
  }, [messages]);

  const showToast = (message: string, type: 'success' | 'error' | 'info' = 'info') => {
    setToast({ message, type });
    setTimeout(() => setToast(null), 3000);
  };

  const handleLogout = async () => {
    try {
      await SecureAPI.secureRequest('/api/logout', { method: 'POST' });
      
      // Clear local state
      setSessionId(null);
      setName("");
      setMessages([]);
      setOnlineUsers([]);
      setWs(null);
      SecureAPI.clearToken();
      
      if (heartbeatInterval.current) {
        clearInterval(heartbeatInterval.current);
        heartbeatInterval.current = null;
      }
      
      showToast("Du har loggats ut", "success");
    } catch (error) {
      console.error('Logout error:', error);
      showToast("Fel vid utloggning", "error");
    }
  };

  const connectWebSocket = useCallback(() => {
    if (!sessionId) return;

    const maxReconnectAttempts = 5;
    let reconnectAttempts = 0;

    function connect() {
      const protocol = window.location.protocol === "https:" ? "wss:" : "ws:";
      const wsUrl = `${protocol}//${window.location.host}/ws?sessionId=${encodeURIComponent(sessionId || '')}&timestamp=${Date.now()}`;
      const socket = new WebSocket(wsUrl);
      
      socket.onopen = () => {
        setWsConnected(true);
        reconnectAttempts = 0;
        showToast("Ansluten till realtid", "success");
      };

      socket.onmessage = (event) => {
        try {
          const data = JSON.parse(event.data);
          
          if (data.type === "message") {
            const sanitizedMessage = {
              ...data.message,
              text: DOMPurify.sanitize(data.message.text),
              user: DOMPurify.sanitize(data.message.user),
              sanitized: true
            };
            
            setMessages(prev => {
              const exists = prev.find(m => m.id === sanitizedMessage.id);
              if (exists) return prev;
              return [...prev, sanitizedMessage].sort((a, b) => a.timestamp - b.timestamp);
            });
          } else if (data.type === "online_users") {
            const sanitizedUsers = data.users.map((user: string) => DOMPurify.sanitize(user));
            setOnlineUsers(sanitizedUsers);
          } else if (data.type === "error") {
            showToast(data.error, "error");
          } else if (data.type === "pong") {
            // Heartbeat response
          }
        } catch (error) {
          console.error("WebSocket message error:", error);
        }
      };

      socket.onclose = () => {
        setWsConnected(false);
        
        if (reconnectAttempts < maxReconnectAttempts && sessionId) {
          reconnectAttempts++;
          showToast(`Återansluter... (${reconnectAttempts}/${maxReconnectAttempts})`, "info");
          setTimeout(connect, Math.min(1000 * Math.pow(2, reconnectAttempts), 10000));
        } else if (reconnectAttempts >= maxReconnectAttempts) {
          showToast("Anslutning misslyckades. Ladda om sidan.", "error");
        }
        
        if (heartbeatInterval.current) {
          clearInterval(heartbeatInterval.current);
          heartbeatInterval.current = null;
        }
      };

      socket.onerror = (error) => {
        console.error("WebSocket error:", error);
        setWsConnected(false);
      };

      setWs(socket);

      // Setup heartbeat
      heartbeatInterval.current = setInterval(() => {
        if (socket.readyState === WebSocket.OPEN) {
          socket.send(JSON.stringify({ type: "heartbeat" }));
        }
      }, 30000);
    }

    connect();
  }, [sessionId]);

  // Connect WebSocket when sessionId changes
  useEffect(() => {
    if (sessionId) {
      connectWebSocket();
    }
    
    return () => {
      if (ws) {
        ws.close();
      }
      if (heartbeatInterval.current) {
        clearInterval(heartbeatInterval.current);
      }
    };
  }, [sessionId, connectWebSocket]);

  // Load initial messages
  useEffect(() => {
    if (sessionId) {
      fetch("/api/messages?offset=0&limit=50", {
        credentials: 'include'
      })
        .then((res) => res.json())
        .then((data) => {
          if (data.items) {
            const sanitizedMessages = data.items.map((msg: Message) => ({
              ...msg,
              text: DOMPurify.sanitize(msg.text),
              user: DOMPurify.sanitize(msg.user),
              sanitized: true
            }));
            setMessages(sanitizedMessages.reverse());
          }
        })
        .catch((error) => {
          console.error("Failed to load messages:", error);
          showToast("Kunde inte ladda meddelanden", "error");
        });

      fetch("/api/online-users", {
        credentials: 'include'
      })
        .then((res) => res.json())
        .then((data) => {
          if (data.users) {
            const sanitizedUsers = data.users.map((user: string) => DOMPurify.sanitize(user));
            setOnlineUsers(sanitizedUsers);
          }
        })
        .catch((error) => {
          console.error("Failed to load online users:", error);
        });
    }
  }, [sessionId]);

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim()) return;

    setLoginLoading(true);
    setLoginError(null);

    try {
      const sanitizedName = DOMPurify.sanitize(name.trim());
      const response = await SecureAPI.secureRequest('/api/login', {
        method: 'POST',
        body: JSON.stringify({ name: sanitizedName }),
      });

      if (response.ok) {
        const data = await response.json();
        setSessionId(data.sessionId);
        setName(sanitizedName);
        showToast(`Välkommen ${sanitizedName}!`, "success");
      } else {
        const data = await response.json();
        setLoginError(data.error || "Inloggning misslyckades");
        showToast(data.error || "Inloggning misslyckades", "error");
      }
    } catch (error) {
      console.error("Login error:", error);
      setLoginError("Nätverksfel. Försök igen.");
      showToast("Nätverksfel. Försök igen.", "error");
    } finally {
      setLoginLoading(false);
    }
  };

  const sendMessage = () => {
    if (!input.trim() || !ws || ws.readyState !== WebSocket.OPEN) return;

    const sanitizedInput = DOMPurify.sanitize(input.trim());
    
    ws.send(JSON.stringify({
      type: "send_message",
      text: sanitizedInput
    }));
    
    setInput("");
    if (inputRef.current) {
      inputRef.current.focus();
    }
  };

  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      sendMessage();
    }
  };

  // Toast component
  const Toast = ({ message, type, onClose }: { message: string; type: string; onClose: () => void }) => (
    <div className={`
      fixed top-4 right-4 z-50 px-4 py-2 rounded-lg shadow-lg
      ${type === 'error' ? 'bg-red-500 text-white' : 
        type === 'success' ? 'bg-green-500 text-white' : 
        'bg-blue-500 text-white'}
      transition-all duration-300 animate-slide-in-right
    `}>
      <div className="flex items-center gap-2">
        {type === 'error' && <AlertCircle size={16} />}
        {type === 'success' && <CheckCircle2 size={16} />}
        {type === 'info' && <Loader2 size={16} className="animate-spin" />}
        <span className="text-sm font-medium">{message}</span>
        <button onClick={onClose} className="ml-2 hover:opacity-70">
          <X size={14} />
        </button>
      </div>
    </div>
  );

  if (!sessionId) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-emerald-50 via-green-50 to-yellow-50">
        {toast && (
          <Toast 
            message={toast.message} 
            type={toast.type} 
            onClose={() => setToast(null)} 
          />
        )}
        
        {/* Header */}
        <header className="relative overflow-hidden">
          <div className="absolute inset-0 bg-gradient-to-br from-emerald-600/20 via-green-500/10 to-yellow-400/20"></div>
          <div className="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
            <div className="text-center">
              <div className="flex items-center justify-center mb-6">
                <img 
                  src="/logo.png" 
                  alt="Mugharred logotype" 
                  className="h-16 w-auto rounded-lg shadow-lg"
                />
              </div>
              <h1 className="text-5xl md:text-6xl font-bold text-gray-900 mb-6">
                <span className="bg-gradient-to-r from-emerald-600 to-green-800 bg-clip-text text-transparent">
                  Mugharred
                </span>
              </h1>
              <p className="text-xl md:text-2xl text-gray-600 mb-8 max-w-3xl mx-auto leading-relaxed">
                En social feed som uppdateras live. Hoppa in med bara ditt namn och upplev äkta samtal utan krångel.
              </p>
            </div>
          </div>
        </header>

        {/* Features */}
        <section className="py-16 bg-white/50 backdrop-blur-sm">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div className="text-center mb-16">
              <h2 className="text-3xl font-bold text-gray-900 mb-4">Varför Mugharred?</h2>
              <p className="text-lg text-gray-600">Enkelt, snabbt och säkert</p>
            </div>
            
            <div className="grid md:grid-cols-3 gap-8">
              <div className="group p-8 rounded-xl bg-white/80 backdrop-blur-sm shadow-lg hover:shadow-xl transition-all duration-300 hover:-translate-y-2">
                <div className="w-12 h-12 bg-gradient-to-br from-emerald-500 to-green-600 rounded-lg flex items-center justify-center mb-6 group-hover:scale-110 transition-transform duration-300">
                  <Zap className="text-white" size={24} />
                </div>
                <h3 className="text-xl font-semibold text-gray-900 mb-3">Realtid</h3>
                <p className="text-gray-600">Meddelanden visas omedelbart för alla användare. Ingen fördröjning, bara äkta konversation.</p>
              </div>
              
              <div className="group p-8 rounded-xl bg-white/80 backdrop-blur-sm shadow-lg hover:shadow-xl transition-all duration-300 hover:-translate-y-2">
                <div className="w-12 h-12 bg-gradient-to-br from-emerald-500 to-green-600 rounded-lg flex items-center justify-center mb-6 group-hover:scale-110 transition-transform duration-300">
                  <Shield className="text-white" size={24} />
                </div>
                <h3 className="text-xl font-semibold text-gray-900 mb-3">Säkerhet först</h3>
                <p className="text-gray-600">Enterprise-grad säkerhet med CSRF-skydd, input sanitization och säkra sessioner.</p>
              </div>
              
              <div className="group p-8 rounded-xl bg-white/80 backdrop-blur-sm shadow-lg hover:shadow-xl transition-all duration-300 hover:-translate-y-2">
                <div className="w-12 h-12 bg-gradient-to-br from-emerald-500 to-green-600 rounded-lg flex items-center justify-center mb-6 group-hover:scale-110 transition-transform duration-300">
                  <Users className="text-white" size={24} />
                </div>
                <h3 className="text-xl font-semibold text-gray-900 mb-3">Begränsad till 5</h3>
                <p className="text-gray-600">Max 5 användare online samtidigt för kvalitetssamtal och optimal prestanda.</p>
              </div>
            </div>
          </div>
        </section>

        {/* Join Section */}
        <section className="py-16 bg-gradient-to-br from-emerald-500/10 to-green-600/10">
          <div className="max-w-2xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
            <h2 className="text-3xl font-bold text-gray-900 mb-6">Gå med i Mugharred</h2>
            <p className="text-lg text-gray-600 mb-8">
              Skriv bara ditt namn så är du igång. Inga lösenord, inga komplicerade formulär.
            </p>
            
            <div className="max-w-md mx-auto">
              <form onSubmit={handleLogin} className="space-y-4">
                <div className="relative">
                  <input
                    type="text"
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    placeholder="Ditt namn..."
                    className="w-full px-6 py-4 text-lg rounded-xl border-2 border-gray-200 focus:border-emerald-500 focus:outline-none transition-colors bg-white/90 backdrop-blur-sm"
                    required
                    minLength={2}
                    maxLength={50}
                    disabled={loginLoading}
                  />
                </div>
                
                {loginError && (
                  <div className="text-red-600 text-sm bg-red-50 px-4 py-2 rounded-lg border border-red-200">
                    {loginError}
                  </div>
                )}
                
                <button
                  type="submit"
                  disabled={loginLoading || !name.trim()}
                  className="w-full bg-gradient-to-r from-emerald-500 to-green-600 text-white font-semibold py-4 px-6 rounded-xl hover:from-emerald-600 hover:to-green-700 transition-all duration-300 disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2 text-lg"
                >
                  {loginLoading ? (
                    <>
                      <Loader2 className="animate-spin" size={20} />
                      Ansluter...
                    </>
                  ) : (
                    <>
                      Anslut
                      <ArrowRight size={20} />
                    </>
                  )}
                </button>
              </form>
            </div>
          </div>
        </section>

        {/* Footer */}
        <footer className="py-12 text-center text-gray-600 bg-white/30 backdrop-blur-sm">
          <div className="max-w-4xl mx-auto px-4">
            <div className="flex items-center justify-center gap-2 mb-4">
              <Globe2 size={20} className="text-emerald-600" />
              <span className="font-medium">Live på mugharred.se</span>
            </div>
            <p className="text-sm">
              Mugharred - En enkel social feed som uppdateras live © 2025
            </p>
          </div>
        </footer>
      </div>
    );
  }

  // Chat interface for logged in users
  return (
    <div className="min-h-screen bg-gradient-to-br from-emerald-50 via-green-50 to-yellow-50">
      {toast && (
        <Toast 
          message={toast.message} 
          type={toast.type} 
          onClose={() => setToast(null)} 
        />
      )}

      {/* Header */}
      <header className="bg-white/90 backdrop-blur-sm shadow-sm border-b border-emerald-100">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4">
              <img 
                src="/logo.png" 
                alt="Mugharred" 
                className="h-10 w-auto rounded-lg"
              />
              <div>
                <h1 className="text-xl font-bold text-gray-900">Mugharred</h1>
                <p className="text-sm text-gray-600">Välkommen {name}</p>
              </div>
            </div>
            
            <div className="flex items-center gap-4">
              <div className="flex items-center gap-2">
                <div className={`w-2 h-2 rounded-full ${wsConnected ? 'bg-green-500' : 'bg-red-500'}`}></div>
                <span className="text-sm text-gray-600">
                  {wsConnected ? 'Ansluten' : 'Inte ansluten'}
                </span>
              </div>
              
              <button
                onClick={handleLogout}
                className="flex items-center gap-2 px-4 py-2 text-sm text-gray-600 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors"
              >
                <LogOut size={16} />
                Logga ut
              </button>
            </div>
          </div>
        </div>
      </header>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
        <div className="grid lg:grid-cols-4 gap-6">
          {/* Online Users */}
          <div className="lg:col-span-1">
            <div className="bg-white/90 backdrop-blur-sm rounded-xl shadow-lg p-6">
              <h2 className="text-lg font-semibold text-gray-900 mb-4 flex items-center gap-2">
                <Users size={20} className="text-emerald-600" />
                Online ({onlineUsers.length}/5)
              </h2>
              <div className="space-y-3">
                {onlineUsers.map((user, index) => (
                  <div 
                    key={user} 
                    className="flex items-center gap-3 p-2 rounded-lg bg-emerald-50"
                    style={{ animationDelay: `${index * ANIMATION_DELAY_UNIT}s` }}
                  >
                    <div className="w-3 h-3 bg-green-500 rounded-full animate-pulse"></div>
                    <span className="text-sm font-medium text-gray-900">{user}</span>
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* Chat */}
          <div className="lg:col-span-3">
            <div className="bg-white/90 backdrop-blur-sm rounded-xl shadow-lg overflow-hidden">
              {/* Messages */}
              <div 
                ref={containerRef}
                className="h-96 overflow-auto border-b border-gray-200"
                onScroll={handleScroll}
                style={{ height: '400px' }}
              >
                <div style={{ height: totalHeight, position: 'relative' }}>
                  <div style={{ transform: `translateY(${offsetY}px)` }}>
                    {visibleMessages.map((message) => (
                      <div
                        key={message.id}
                        className="p-4 border-b border-gray-100 hover:bg-gray-50 cursor-pointer transition-colors"
                        style={{ height: ROW_HEIGHT }}
                        onClick={() => setExpandedMessage(message)}
                      >
                        <div className="flex items-start gap-3">
                          <div className="flex-shrink-0">
                            <div className="w-8 h-8 bg-gradient-to-br from-emerald-400 to-green-600 rounded-full flex items-center justify-center">
                              <span className="text-white text-sm font-semibold">
                                {message.user[0].toUpperCase()}
                              </span>
                            </div>
                          </div>
                          <div className="flex-1 min-w-0">
                            <div className="flex items-center gap-2 mb-1">
                              <span className="font-medium text-gray-900 text-sm">{message.user}</span>
                              <span className="text-xs text-gray-500">
                                {new Date(message.timestamp).toLocaleTimeString('sv-SE', { 
                                  hour: '2-digit', 
                                  minute: '2-digit' 
                                })}
                              </span>
                            </div>
                            <p className="text-gray-800 text-sm line-clamp-2">{message.text}</p>
                          </div>
                          <div className="flex-shrink-0">
                            <Eye size={16} className="text-gray-400" />
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              </div>

              {/* Input */}
              <div className="p-4">
                <div className="flex items-center gap-3">
                  <input
                    ref={inputRef}
                    type="text"
                    value={input}
                    onChange={(e) => setInput(e.target.value)}
                    onKeyPress={handleKeyPress}
                    placeholder="Skriv ditt meddelande..."
                    className="flex-1 px-4 py-3 border border-gray-200 rounded-lg focus:border-emerald-500 focus:outline-none transition-colors"
                    maxLength={500}
                    disabled={!wsConnected}
                  />
                  <button
                    onClick={sendMessage}
                    disabled={!input.trim() || !wsConnected}
                    className="px-6 py-3 bg-gradient-to-r from-emerald-500 to-green-600 text-white rounded-lg hover:from-emerald-600 hover:to-green-700 disabled:opacity-50 disabled:cursor-not-allowed transition-all duration-300 flex items-center gap-2"
                  >
                    <Send size={16} />
                    Skicka
                  </button>
                </div>
                <div className="mt-2 text-xs text-gray-500">
                  {input.length}/500 tecken
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Message Modal */}
      {expandedMessage && (
        <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-xl shadow-xl max-w-2xl w-full max-h-96 overflow-hidden">
            <div className="p-6 border-b border-gray-200">
              <div className="flex items-start justify-between">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-gradient-to-br from-emerald-400 to-green-600 rounded-full flex items-center justify-center">
                    <span className="text-white font-semibold">
                      {expandedMessage.user[0].toUpperCase()}
                    </span>
                  </div>
                  <div>
                    <h3 className="font-semibold text-gray-900">{expandedMessage.user}</h3>
                    <p className="text-sm text-gray-500">
                      {new Date(expandedMessage.timestamp).toLocaleString('sv-SE')}
                    </p>
                  </div>
                </div>
                <button
                  onClick={() => setExpandedMessage(null)}
                  className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
                >
                  <X size={20} />
                </button>
              </div>
            </div>
            <div className="p-6 max-h-64 overflow-auto">
              <p className="text-gray-800 whitespace-pre-wrap">{expandedMessage.text}</p>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}