import React, { useMemo, useState, useEffect, useRef, useCallback } from "react";
import { 
  ArrowRight, Shield, Zap, Users, MessageSquareText, Globe2, Send, X, 
  CheckCircle2, AlertCircle, Loader2, WifiOff, Menu, LogOut, Clock, Eye
} from "lucide-react";

type Message = {
  id: string;
  user: string;
  text: string;
  timestamp: number;
};

type LoadingState = 'idle' | 'loading' | 'success' | 'error';

const ROW_HEIGHT = 88; // Increased for better mobile touch targets
const PAGE_SIZE = 10;
const ANIMATION_DELAY_UNIT = 0.1;

// Toast notification component
function Toast({ message, type, onClose }: { 
  message: string; 
  type: 'success' | 'error' | 'info'; 
  onClose: () => void 
}) {
  useEffect(() => {
    const timer = setTimeout(onClose, 4000);
    return () => clearTimeout(timer);
  }, [onClose]);

  const icons = {
    success: <CheckCircle2 className="h-5 w-5" />,
    error: <AlertCircle className="h-5 w-5" />,
    info: <AlertCircle className="h-5 w-5" />
  };

  const colors = {
    success: 'from-green-50 to-green-100 border-green-200 text-green-800',
    error: 'from-red-50 to-red-100 border-red-200 text-red-800',
    info: 'from-blue-50 to-blue-100 border-blue-200 text-blue-800'
  };

  return (
    <div className={`
      fixed top-4 right-4 z-50 flex items-center gap-3 px-4 py-3 
      rounded-2xl border bg-gradient-to-r ${colors[type]}
      shadow-large animate-slide-down md:max-w-sm
    `}>
      {icons[type]}
      <p className="text-sm font-medium">{message}</p>
      <button
        onClick={onClose}
        className="ml-auto p-1 rounded-lg hover:bg-white/50 transition-colors"
      >
        <X className="h-4 w-4" />
      </button>
    </div>
  );
}

// Loading skeleton for messages
function MessageSkeleton() {
  return (
    <div className="p-4 animate-pulse">
      <div className="flex items-center justify-between mb-2">
        <div className="h-4 w-24 bg-gray-200 rounded-lg"></div>
        <div className="h-3 w-16 bg-gray-100 rounded-lg"></div>
      </div>
      <div className="space-y-2">
        <div className="h-4 w-full bg-gray-100 rounded-lg"></div>
        <div className="h-4 w-3/4 bg-gray-100 rounded-lg"></div>
      </div>
    </div>
  );
}

export default function MugharredLandingPage() {
  // State management
  const [sessionId, setSessionId] = useState<string | null>(
    () => localStorage.getItem("mugharred_session") || null,
  );
  const [name, setName] = useState(
    () => localStorage.getItem("mugharred_name") || ""
  );
  const [loginState, setLoginState] = useState<LoadingState>('idle');
  const [loginError, setLoginError] = useState<string | null>(null);
  
  // Feed state
  const [ws, setWs] = useState<WebSocket | null>(null);
  const [wsConnected, setWsConnected] = useState(false);
  const [messages, setMessages] = useState<Message[]>([]);
  const [totalMessages, setTotalMessages] = useState(0);
  const [onlineUsers, setOnlineUsers] = useState<string[]>([]);
  const [input, setInput] = useState("");
  const [expandedMessage, setExpandedMessage] = useState<Message | null>(null);
  const [sendingMessage, setSendingMessage] = useState(false);
  const [toast, setToast] = useState<{ message: string; type: 'success' | 'error' | 'info' } | null>(null);
  const [loadingMessages, setLoadingMessages] = useState(false);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  
  // Virtual scroll state
  const containerRef = useRef<HTMLDivElement | null>(null);
  const [scrollTop, setScrollTop] = useState(0);
  const lastActivityRef = useRef<number>(Date.now());

  const canJoin = useMemo(() => name.trim().length >= 2, [name]);

  // Track user activity
  const trackActivity = useCallback(() => {
    lastActivityRef.current = Date.now();
  }, []);

  // Debounced scroll handler
  const handleScroll = useCallback(
    (e: React.UIEvent<HTMLDivElement>) => {
      const el = e.currentTarget;
      setScrollTop(el.scrollTop);
      trackActivity();

      if (
        el.scrollTop + el.clientHeight >= el.scrollHeight - ROW_HEIGHT * 2 &&
        messages.length < totalMessages &&
        !loadingMessages
      ) {
        loadPage(messages.length);
      }
    },
    [messages.length, totalMessages, loadingMessages, trackActivity]
  );

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    const trimmed = name.trim();
    if (trimmed.length < 2) {
      setLoginError("Namnet måste vara minst 2 tecken.");
      return;
    }
    setLoginError(null);
    setLoginState('loading');

    try {
      const res = await fetch("/api/login", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ name: trimmed }),
      });
      
      if (!res.ok) {
        const body = await res.json().catch(() => ({}));
        setLoginError(body.error || "Inloggning misslyckades");
        setLoginState('error');
        return;
      }
      
      const data = await res.json();
      setLoginState('success');
      
      // Small delay for success animation
      setTimeout(() => {
        setSessionId(data.sessionId);
        localStorage.setItem("mugharred_session", data.sessionId);
        localStorage.setItem("mugharred_name", data.name);
      }, 500);
      
    } catch (err) {
      setLoginError("Kunde inte ansluta till servern");
      setLoginState('error');
    }
  }

  async function loadPage(offset: number) {
    setLoadingMessages(true);
    try {
      const res = await fetch(
        `/api/messages?offset=${offset}&limit=${PAGE_SIZE}`,
      );
      const data = await res.json();
      setTotalMessages(data.total);
      setMessages((prev) => {
        const existingIds = new Set(prev.map((m) => m.id));
        const merged = [...prev];
        for (const m of data.items) {
          if (!existingIds.has(m.id)) merged.push(m);
        }
        return merged;
      });
    } catch (err) {
      console.error("Failed to load messages:", err);
      setToast({ message: "Kunde inte ladda meddelanden", type: 'error' });
    } finally {
      setLoadingMessages(false);
    }
  }

  async function sendMessage() {
    if (!ws || !input.trim() || sendingMessage) return;
    
    setSendingMessage(true);
    const messageText = input.trim();
    setInput(""); // Clear immediately for better UX
    
    try {
      ws.send(JSON.stringify({ type: "send_message", text: messageText }));
      trackActivity();
    } catch (err) {
      setInput(messageText); // Restore on error
      setToast({ message: "Kunde inte skicka meddelandet", type: 'error' });
    } finally {
      setSendingMessage(false);
    }
  }

  function handleLogout() {
    localStorage.removeItem("mugharred_session");
    localStorage.removeItem("mugharred_name");
    setSessionId(null);
    ws?.close();
    setWs(null);
    setMessages([]);
    setOnlineUsers([]);
    setInput("");
  }

  // WebSocket connection with reconnection logic
  useEffect(() => {
    if (!sessionId) return;

    loadPage(0);

    let reconnectTimeout: ReturnType<typeof setTimeout>;
    let activityInterval: ReturnType<typeof setInterval>;

    function connect() {
      const protocol = window.location.protocol === "https:" ? "wss:" : "ws:";
      const wsUrl = `${protocol}//${window.location.host}/ws?sessionId=${encodeURIComponent(sessionId || '')}`;
      const socket = new WebSocket(wsUrl);
      
      socket.onopen = () => {
        setWsConnected(true);
        setToast({ message: "Ansluten till chatten", type: 'success' });
      };
      
      socket.onmessage = (event) => {
        const data = JSON.parse(event.data);
        
        if (data.type === "message") {
          setMessages((prev) => [data.message, ...prev]);
          setTotalMessages((prev) => prev + 1);
          
          // Show notification for messages from others
          if (data.message.user !== localStorage.getItem("mugharred_name")) {
            setToast({ 
              message: `${data.message.user}: ${data.message.text.substring(0, 50)}...`, 
              type: 'info' 
            });
          }
        } else if (data.type === "online_users") {
          setOnlineUsers(data.users);
        } else if (data.type === "error") {
          if (data.error.includes("inaktivitet")) {
            setToast({ message: data.error, type: 'error' });
            handleLogout();
          } else {
            setToast({ message: data.error, type: 'error' });
          }
        }
      };
      
      socket.onclose = () => {
        setWsConnected(false);
        // Attempt reconnect after 3 seconds
        reconnectTimeout = setTimeout(connect, 3000);
      };
      
      socket.onerror = () => {
        setWsConnected(false);
      };
      
      setWs(socket);
    }

    connect();

    // Send activity heartbeat
    activityInterval = setInterval(() => {
      if (ws && ws.readyState === WebSocket.OPEN) {
        ws.send(JSON.stringify({ type: "heartbeat" }));
      }
    }, 30000); // Every 30 seconds

    return () => {
      clearTimeout(reconnectTimeout);
      clearInterval(activityInterval);
      ws?.close();
    };
  }, [sessionId]);

  // If logged in, show feed interface
  if (sessionId) {
    const totalHeight = totalMessages * ROW_HEIGHT;
    const visibleStartIndex = Math.floor(scrollTop / ROW_HEIGHT);
    const visibleCount = Math.ceil(600 / ROW_HEIGHT) + 2; // Add buffer
    const visibleEndIndex = Math.min(
      visibleStartIndex + visibleCount,
      totalMessages,
    );
    const visibleMessages = messages.slice(
      visibleStartIndex,
      visibleEndIndex,
    );
    const topSpacerHeight = visibleStartIndex * ROW_HEIGHT;

    return (
      <div className="min-h-screen bg-gradient-to-br from-gray-50 to-gray-100">
        {/* Toast notifications */}
        {toast && (
          <Toast 
            message={toast.message} 
            type={toast.type} 
            onClose={() => setToast(null)} 
          />
        )}

        {/* Header */}
        <header className="sticky top-0 z-40 glass border-b safe-top">
          <div className="mx-auto max-w-6xl px-4 sm:px-6 py-4">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div className="group relative">
                  <div className="absolute inset-0 bg-gradient-to-r from-brand-green to-brand-green-light rounded-2xl blur-md opacity-50 group-hover:opacity-75 transition-opacity"></div>
                  <div className="relative h-12 w-12 rounded-2xl overflow-hidden shadow-medium">
                    <img 
                      src="/logo.png" 
                      alt="Mugharred Logo" 
                      className="h-full w-full object-cover"
                    />
                  </div>
                </div>
                <div>
                  <h1 className="text-lg font-semibold">Mugharred</h1>
                  <p className="text-sm text-gray-600">Välkommen, {name}!</p>
                </div>
              </div>

              <div className="flex items-center gap-4">
                {/* Connection status */}
                <div className="hidden sm:flex items-center gap-2 text-sm">
                  {wsConnected ? (
                    <>
                      <div className="h-2 w-2 rounded-full bg-green-500 animate-pulse"></div>
                      <span className="text-gray-700">Online</span>
                    </>
                  ) : (
                    <>
                      <WifiOff className="h-4 w-4 text-gray-500" />
                      <span className="text-gray-500">Offline</span>
                    </>
                  )}
                </div>

                {/* Online users count */}
                <div className="flex items-center gap-2 px-3 py-1.5 rounded-xl bg-brand-green/10 text-brand-green">
                  <Users className="h-4 w-4" />
                  <span className="text-sm font-medium">{onlineUsers.length}/5</span>
                </div>

                {/* Mobile menu button */}
                <button
                  onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
                  className="sm:hidden p-2 rounded-xl hover:bg-gray-100 transition-colors"
                >
                  <Menu className="h-5 w-5" />
                </button>

                {/* Desktop logout */}
                <button
                  onClick={handleLogout}
                  className="hidden sm:flex items-center gap-2 px-4 py-2 rounded-xl text-gray-700 hover:bg-gray-100 transition-colors"
                >
                  <LogOut className="h-4 w-4" />
                  <span className="text-sm">Logga ut</span>
                </button>
              </div>
            </div>

            {/* Mobile menu dropdown */}
            {mobileMenuOpen && (
              <div className="absolute top-full left-0 right-0 bg-white border-t shadow-xl animate-slide-down">
                <div className="p-4 space-y-2">
                  <div className="flex items-center gap-2 text-sm p-2">
                    {wsConnected ? (
                      <>
                        <div className="h-2 w-2 rounded-full bg-green-500 animate-pulse"></div>
                        <span className="text-gray-700">Ansluten</span>
                      </>
                    ) : (
                      <>
                        <WifiOff className="h-4 w-4 text-gray-500" />
                        <span className="text-gray-500">Ej ansluten</span>
                      </>
                    )}
                  </div>
                  <button
                    onClick={() => {
                      handleLogout();
                      setMobileMenuOpen(false);
                    }}
                    className="w-full flex items-center gap-2 p-3 rounded-xl text-red-600 hover:bg-red-50 transition-colors"
                  >
                    <LogOut className="h-4 w-4" />
                    <span>Logga ut</span>
                  </button>
                </div>
              </div>
            )}
          </div>
        </header>

        <main className="mx-auto max-w-4xl px-4 sm:px-6 py-6 space-y-6">
          {/* Online users */}
          <div className="glass rounded-3xl p-6 animate-fade-in">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg font-semibold">Online nu</h2>
              <span className="text-sm text-gray-500">{onlineUsers.length} av 5 platser</span>
            </div>
            <div className="flex flex-wrap gap-2">
              {onlineUsers.map((user, index) => (
                <span
                  key={user}
                  className="inline-flex items-center gap-2 px-4 py-2 rounded-2xl bg-white border border-gray-200 shadow-soft animate-scale-in"
                  style={{ animationDelay: `${index * ANIMATION_DELAY_UNIT}s` }}
                >
                  <div className="relative">
                    <div className="h-2 w-2 rounded-full bg-green-500"></div>
                    <div className="absolute inset-0 h-2 w-2 rounded-full bg-green-500 animate-ping"></div>
                  </div>
                  <span className="text-sm font-medium">{user}</span>
                </span>
              ))}
              {[...Array(Math.max(0, 5 - onlineUsers.length))].map((_, i) => (
                <span
                  key={`empty-${i}`}
                  className="inline-flex items-center gap-2 px-4 py-2 rounded-2xl border border-dashed border-gray-300 text-gray-400"
                >
                  <div className="h-2 w-2 rounded-full bg-gray-300"></div>
                  <span className="text-sm">Ledig plats</span>
                </span>
              ))}
            </div>
          </div>

          {/* Message input */}
          <div className="glass rounded-3xl p-6 animate-fade-in" style={{ animationDelay: '0.1s' }}>
            <div className="flex gap-3">
              <div className="flex-1">
                <textarea
                  value={input}
                  onChange={(e) => {
                    setInput(e.target.value);
                    trackActivity();
                  }}
                  onKeyDown={(e) => {
                    if (e.key === "Enter" && !e.shiftKey) {
                      e.preventDefault();
                      sendMessage();
                    }
                  }}
                  placeholder="Skriv ditt meddelande här..."
                  className="w-full resize-none rounded-2xl border border-gray-200 bg-white px-4 py-3 text-sm outline-none transition-all focus:border-brand-green focus:ring-4 focus:ring-brand-green/10"
                  rows={3}
                  maxLength={500}
                />
                <div className="mt-2 flex items-center justify-between text-xs text-gray-500">
                  <span>{input.length}/500 tecken</span>
                  <span>Tryck Enter för att skicka</span>
                </div>
              </div>
              <button
                onClick={sendMessage}
                disabled={!input.trim() || !ws || sendingMessage}
                className="btn self-start px-6 py-3 rounded-2xl bg-gradient-to-r from-brand-green to-brand-green-light text-white shadow-medium hover-lift disabled:hover:translate-y-0 disabled:hover:shadow-medium"
              >
                {sendingMessage ? (
                  <Loader2 className="h-5 w-5 animate-spin" />
                ) : (
                  <Send className="h-5 w-5" />
                )}
              </button>
            </div>
          </div>

          {/* Virtual scrolled feed */}
          <div className="glass rounded-3xl overflow-hidden animate-fade-in" style={{ animationDelay: '0.2s' }}>
            <div className="px-6 py-4 border-b border-gray-100">
              <div className="flex items-center justify-between">
                <h2 className="text-lg font-semibold">Live feed</h2>
                <div className="flex items-center gap-3 text-sm text-gray-500">
                  <span className="flex items-center gap-1">
                    <MessageSquareText className="h-4 w-4" />
                    {totalMessages} meddelanden
                  </span>
                  <span className="flex items-center gap-1">
                    <Clock className="h-4 w-4" />
                    Realtid
                  </span>
                </div>
              </div>
            </div>
            
            <div
              ref={containerRef}
              style={{ height: 600 }}
              onScroll={handleScroll}
              className="overflow-y-auto overscroll-contain"
              onMouseMove={trackActivity}
              onClick={trackActivity}
            >
              <div style={{ height: totalHeight, position: "relative" }}>
                <div style={{ transform: `translateY(${topSpacerHeight}px)` }}>
                  {messages.length === 0 && !loadingMessages ? (
                    <div className="flex flex-col items-center justify-center h-96 text-gray-400">
                      <MessageSquareText className="h-12 w-12 mb-3" />
                      <p className="text-sm">Inga meddelanden än</p>
                      <p className="text-xs mt-1">Var den första att skriva något!</p>
                    </div>
                  ) : (
                    visibleMessages.map((message) => (
                      <div
                        key={message.id}
                        style={{ height: ROW_HEIGHT }}
                        className="group relative px-6 py-4 border-b border-gray-100 hover:bg-gray-50 transition-colors cursor-pointer animate-fade-in"
                        onClick={() => setExpandedMessage(message)}
                      >
                        <div className="flex items-start justify-between">
                          <div className="flex-1 min-w-0">
                            <div className="flex items-center gap-3 mb-1">
                              <span className="font-medium text-gray-900">{message.user}</span>
                              <span className="text-xs text-gray-500">
                                {new Date(message.timestamp).toLocaleTimeString('sv-SE', {
                                  hour: '2-digit',
                                  minute: '2-digit'
                                })}
                              </span>
                            </div>
                            <p className="text-sm text-gray-700 line-clamp-2">{message.text}</p>
                          </div>
                          <button className="ml-4 p-2 rounded-lg opacity-0 group-hover:opacity-100 hover:bg-gray-100 transition-all">
                            <Eye className="h-4 w-4 text-gray-500" />
                          </button>
                        </div>
                        <div className="absolute inset-x-0 bottom-0 h-px bg-gradient-to-r from-transparent via-gray-200 to-transparent opacity-0 group-hover:opacity-100 transition-opacity"></div>
                      </div>
                    ))
                  )}
                  
                  {loadingMessages && (
                    <div className="px-6">
                      {[...Array(3)].map((_, i) => (
                        <MessageSkeleton key={i} />
                      ))}
                    </div>
                  )}
                </div>
              </div>
            </div>
          </div>
        </main>

        {/* Message modal */}
        {expandedMessage && (
          <div 
            className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm animate-fade-in"
            onClick={() => setExpandedMessage(null)}
          >
            <div 
              className="max-w-2xl w-full glass rounded-3xl p-6 shadow-xl animate-scale-in"
              onClick={(e) => e.stopPropagation()}
            >
              <div className="flex items-start justify-between mb-4">
                <div>
                  <h3 className="text-xl font-semibold">{expandedMessage.user}</h3>
                  <p className="text-sm text-gray-500 mt-1">
                    {new Date(expandedMessage.timestamp).toLocaleString('sv-SE')}
                  </p>
                </div>
                <button
                  onClick={() => setExpandedMessage(null)}
                  className="p-2 rounded-xl hover:bg-gray-100 transition-colors"
                >
                  <X className="h-5 w-5" />
                </button>
              </div>
              <div className="text-gray-700 whitespace-pre-wrap leading-relaxed">
                {expandedMessage.text}
              </div>
            </div>
          </div>
        )}
      </div>
    );
  }

  // Landing page for non-logged in users
  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-50 via-white to-brand-green/5">
      {/* Hero background decoration */}
      <div className="absolute inset-0 overflow-hidden pointer-events-none">
        <div className="absolute top-20 left-20 w-96 h-96 bg-brand-green/10 rounded-full blur-3xl animate-float"></div>
        <div className="absolute bottom-20 right-20 w-96 h-96 bg-brand-gold/10 rounded-full blur-3xl animate-float" style={{ animationDelay: '1.5s' }}></div>
      </div>

      {/* Header */}
      <header className="relative z-10 safe-top">
        <div className="mx-auto max-w-6xl px-4 sm:px-6 py-6">
          <nav className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="group relative">
                <div className="absolute inset-0 bg-gradient-to-r from-brand-green to-brand-green-light rounded-2xl blur-md opacity-50 group-hover:opacity-75 transition-opacity"></div>
                <div className="relative h-12 w-12 rounded-2xl overflow-hidden shadow-medium">
                  <img 
                    src="/logo.png" 
                    alt="Mugharred Logo" 
                    className="h-full w-full object-cover"
                  />
                </div>
              </div>
              <div>
                <h1 className="text-xl font-semibold">Mugharred</h1>
                <p className="text-sm text-gray-600">Live social feed</p>
              </div>
            </div>

            <div className="hidden md:flex items-center gap-8">
              <a href="#features" className="text-sm text-gray-700 hover:text-gray-900 transition-colors">
                Funktioner
              </a>
              <a href="#how" className="text-sm text-gray-700 hover:text-gray-900 transition-colors">
                Hur det funkar
              </a>
              <a href="#security" className="text-sm text-gray-700 hover:text-gray-900 transition-colors">
                Säkerhet
              </a>
              <a
                href="#join"
                className="btn px-6 py-2.5 rounded-2xl bg-gradient-to-r from-brand-green to-brand-green-light text-white text-sm shadow-medium hover-lift"
              >
                <span>Gå med nu</span>
                <ArrowRight className="ml-2 h-4 w-4" />
              </a>
            </div>

            <a
              href="#join"
              className="md:hidden btn px-4 py-2.5 rounded-2xl bg-gradient-to-r from-brand-green to-brand-green-light text-white text-sm shadow-medium"
            >
              <span>Gå med</span>
              <ArrowRight className="ml-1 h-4 w-4" />
            </a>
          </nav>
        </div>
      </header>

      {/* Hero section */}
      <main className="relative z-10">
        <section className="mx-auto max-w-6xl px-4 sm:px-6 py-12 md:py-24">
          <div className="grid gap-12 lg:grid-cols-2 lg:gap-16 items-center">
            <div className="space-y-8 animate-fade-in">
              <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full glass text-sm text-gray-700 animate-slide-up">
                <Zap className="h-4 w-4 text-brand-green" />
                <span>Ett flöde för alla – i realtid</span>
              </div>

              <div className="space-y-4">
                <h1 className="text-4xl md:text-5xl lg:text-6xl font-bold leading-tight animate-slide-up" style={{ animationDelay: '0.1s' }}>
                  <span className="text-gradient">Mugharred</span>
                  <span className="block text-gray-800">en social feed som lever.</span>
                </h1>
                <p className="text-lg text-gray-600 max-w-xl animate-slide-up" style={{ animationDelay: '0.2s' }}>
                  Hoppa in med bara ditt namn. Dela tankar i realtid. 
                  Upplev äkta samtal utan krångel – max 5 personer åt gången för bästa upplevelse.
                </p>
              </div>

              <div className="flex flex-wrap gap-4 animate-slide-up" style={{ animationDelay: '0.3s' }}>
                <a
                  href="#join"
                  className="btn px-8 py-3.5 rounded-2xl bg-gradient-to-r from-brand-green to-brand-green-light text-white shadow-large hover-lift text-lg font-medium"
                >
                  <span>Starta direkt</span>
                  <ArrowRight className="ml-2 h-5 w-5" />
                </a>
                <a
                  href="#features"
                  className="btn px-8 py-3.5 rounded-2xl glass border border-gray-200 text-gray-900 hover:bg-white hover-lift text-lg"
                >
                  <span>Utforska funktioner</span>
                </a>
              </div>

              <div className="flex flex-wrap gap-6 text-sm text-gray-600 animate-slide-up" style={{ animationDelay: '0.4s' }}>
                <span className="flex items-center gap-2">
                  <Users className="h-5 w-5 text-brand-green" />
                  Max 5 deltagare
                </span>
                <span className="flex items-center gap-2">
                  <Shield className="h-5 w-5 text-brand-green" />
                  Säker & trygg
                </span>
                <span className="flex items-center gap-2">
                  <MessageSquareText className="h-5 w-5 text-brand-green" />
                  Realtidsuppdateringar
                </span>
              </div>
            </div>

            {/* Preview mockup */}
            <div className="relative animate-fade-in" style={{ animationDelay: '0.5s' }}>
              <div className="absolute inset-0 bg-gradient-to-r from-brand-green/20 to-brand-gold/20 blur-3xl"></div>
              <div className="relative glass rounded-3xl p-8 shadow-xl">
                <div className="mb-6">
                  <h3 className="text-lg font-semibold mb-1">Live feed</h3>
                  <p className="text-sm text-gray-600">Automatisk scroll • Virtual rendering</p>
                </div>

                <div className="space-y-4">
                  {[
                    { user: "Emma", time: "Just nu", text: "Älskar hur snabbt allt går! Känns som en riktig konversation 💬" },
                    { user: "Viktor", time: "2 min", text: "Smart med max 5 personer, det blir lagom intimt och personligt" },
                    { user: "Sara", time: "5 min", text: "Designen är så clean! Och virtual scroll gör att allt flyter på smidigt" },
                  ].map((msg, i) => (
                    <div 
                      key={i}
                      className="group p-4 rounded-2xl bg-white border border-gray-100 shadow-soft hover:shadow-medium transition-all cursor-pointer hover:-translate-y-0.5 animate-slide-up"
                      style={{ animationDelay: `${0.6 + i * 0.1}s` }}
                    >
                      <div className="flex items-center justify-between mb-2">
                        <span className="font-medium text-gray-900">{msg.user}</span>
                        <span className="text-xs text-gray-500">{msg.time}</span>
                      </div>
                      <p className="text-sm text-gray-700 line-clamp-2">{msg.text}</p>
                      <div className="mt-2 flex items-center gap-1 text-xs text-brand-green opacity-0 group-hover:opacity-100 transition-opacity">
                        <Eye className="h-3.5 w-3.5" />
                        <span>Visa mer</span>
                      </div>
                    </div>
                  ))}
                </div>

                {/* Input preview */}
                <div className="mt-6 p-4 rounded-2xl bg-gray-50 border border-gray-200 animate-slide-up" style={{ animationDelay: '0.9s' }}>
                  <div className="flex items-center gap-3">
                    <div className="h-10 w-10 rounded-xl bg-gradient-to-r from-brand-green/20 to-brand-green-light/20 shimmer"></div>
                    <div className="flex-1 h-10 rounded-xl bg-gray-100"></div>
                    <div className="h-10 w-10 rounded-xl bg-gradient-to-r from-brand-green to-brand-green-light grid place-items-center text-white">
                      <Send className="h-5 w-5" />
                    </div>
                  </div>
                  <p className="text-xs text-gray-500 mt-3 text-center">Skriv → Enter → Alla ser direkt</p>
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* Features section */}
        <section id="features" className="py-16 md:py-24 bg-gray-50">
          <div className="mx-auto max-w-6xl px-4 sm:px-6">
            <div className="text-center mb-12 space-y-4">
              <h2 className="text-3xl md:text-4xl font-bold animate-fade-in">
                Allt du behöver, <span className="text-gradient">inget mer</span>
              </h2>
              <p className="text-lg text-gray-600 max-w-2xl mx-auto animate-fade-in" style={{ animationDelay: '0.1s' }}>
                Mugharred är designad för enkelhet och effektivitet. 
                En sida, ett flöde, och en fantastisk upplevelse.
              </p>
            </div>

            <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
              {[
                {
                  icon: <MessageSquareText className="h-6 w-6" />,
                  title: "Live feed i realtid",
                  desc: "WebSockets säkerställer att nya meddelanden dyker upp direkt för alla.",
                  color: "from-blue-500 to-cyan-500"
                },
                {
                  icon: <Users className="h-6 w-6" />,
                  title: "Intimt och personligt",
                  desc: "Max 5 deltagare samtidigt skapar en trygg och hanterbar miljö.",
                  color: "from-brand-green to-brand-green-light"
                },
                {
                  icon: <Zap className="h-6 w-6" />,
                  title: "Blixtsnabb rendering",
                  desc: "Virtual scroll hanterar tusentals meddelanden utan prestandaproblem.",
                  color: "from-amber-500 to-orange-500"
                },
                {
                  icon: <Shield className="h-6 w-6" />,
                  title: "Inbyggd säkerhet",
                  desc: "Rate limiting och automatisk utloggning skyddar mot missbruk.",
                  color: "from-purple-500 to-pink-500"
                },
                {
                  icon: <Globe2 className="h-6 w-6" />,
                  title: "En sida, allt du behöver",
                  desc: "Ingen komplicerad navigation. Allt händer på samma ställe.",
                  color: "from-teal-500 to-emerald-500"
                },
                {
                  icon: <Clock className="h-6 w-6" />,
                  title: "Auto-logout vid inaktivitet",
                  desc: "Efter 5 minuters inaktivitet loggas du ut automatiskt för säkerhet.",
                  color: "from-red-500 to-rose-500"
                },
              ].map((feature, i) => (
                <div
                  key={i}
                  className="group glass rounded-3xl p-6 hover:bg-white hover:shadow-large transition-all duration-300 animate-fade-in hover:-translate-y-1"
                  style={{ animationDelay: `${i * 0.1}s` }}
                >
                  <div className={`inline-flex p-3 rounded-2xl bg-gradient-to-r ${feature.color} text-white shadow-medium mb-4 group-hover:scale-110 transition-transform`}>
                    {feature.icon}
                  </div>
                  <h3 className="text-xl font-semibold mb-2">{feature.title}</h3>
                  <p className="text-gray-600">{feature.desc}</p>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* How it works section */}
        <section id="how" className="py-16 md:py-24">
          <div className="mx-auto max-w-6xl px-4 sm:px-6">
            <div className="grid gap-8 lg:grid-cols-2">
              <div className="glass rounded-3xl p-8 animate-fade-in">
                <h3 className="text-2xl font-bold mb-6 text-gradient">Hur det funkar</h3>
                <ol className="space-y-4">
                  {[
                    "Skriv ditt namn och klicka på 'Anslut'",
                    "Se vilka som är online i realtid",
                    "Skriv meddelanden som syns direkt för alla",
                    "Klicka på meddelanden för att läsa hela texten",
                    "Scrolla bakåt för att se tidigare konversationer"
                  ].map((step, i) => (
                    <li key={i} className="flex gap-4 animate-slide-up" style={{ animationDelay: `${i * 0.1}s` }}>
                      <span className="flex-shrink-0 grid h-8 w-8 place-items-center rounded-full bg-gradient-to-r from-brand-green to-brand-green-light text-white text-sm font-semibold shadow-medium">
                        {i + 1}
                      </span>
                      <span className="text-gray-700 pt-1">{step}</span>
                    </li>
                  ))}
                </ol>
              </div>

              <div id="security" className="glass rounded-3xl p-8 animate-fade-in" style={{ animationDelay: '0.1s' }}>
                <h3 className="text-2xl font-bold mb-6">Säkerhet först</h3>
                <p className="text-gray-700 mb-6">
                  Mugharred använder en enkel men effektiv säkerhetsmodell designad för trygghet och integritet.
                </p>
                <ul className="space-y-3">
                  {[
                    { icon: "🔒", text: "Max 5 användare för kontrollerad miljö" },
                    { icon: "⏱️", text: "Rate limiting förhindrar spam" },
                    { icon: "🚪", text: "Auto-logout efter 5 min inaktivitet" },
                    { icon: "📏", text: "Meddelanden max 500 tecken" },
                    { icon: "🔐", text: "HTTPS-kryptering som standard" },
                  ].map((item, i) => (
                    <li key={i} className="flex items-center gap-3 animate-slide-up" style={{ animationDelay: `${0.2 + i * 0.1}s` }}>
                      <span className="text-2xl">{item.icon}</span>
                      <span className="text-gray-700">{item.text}</span>
                    </li>
                  ))}
                </ul>
                <div className="mt-6 p-4 rounded-2xl bg-amber-50 border border-amber-200 animate-slide-up" style={{ animationDelay: '0.7s' }}>
                  <p className="text-sm text-amber-800">
                    <strong>Tips:</strong> För ökad säkerhet kan e-postverifiering och starkare autentisering läggas till i framtiden.
                  </p>
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* Join section */}
        <section id="join" className="py-16 md:py-24 bg-gradient-to-br from-brand-green/5 to-brand-gold/5">
          <div className="mx-auto max-w-6xl px-4 sm:px-6">
            <div className="glass rounded-4xl p-8 md:p-12 shadow-xl">
              <div className="grid gap-12 lg:grid-cols-2 items-center">
                <div className="space-y-6 animate-fade-in">
                  <h2 className="text-3xl md:text-4xl font-bold">
                    Redo att hoppa in?
                  </h2>
                  <p className="text-lg text-gray-700">
                    Det tar bara några sekunder att komma igång. 
                    Skriv ditt namn nedan och upplev Mugharred direkt.
                  </p>
                  
                  <div className="space-y-4 text-sm">
                    <div className="flex items-center gap-3 text-gray-700">
                      <CheckCircle2 className="h-5 w-5 text-brand-green flex-shrink-0" />
                      <span>Ingen registrering eller e-post krävs</span>
                    </div>
                    <div className="flex items-center gap-3 text-gray-700">
                      <CheckCircle2 className="h-5 w-5 text-brand-green flex-shrink-0" />
                      <span>Anslut direkt och börja chatta</span>
                    </div>
                    <div className="flex items-center gap-3 text-gray-700">
                      <CheckCircle2 className="h-5 w-5 text-brand-green flex-shrink-0" />
                      <span>100% gratis och öppen för alla</span>
                    </div>
                  </div>
                </div>

                <div className="animate-fade-in" style={{ animationDelay: '0.2s' }}>
                  <form onSubmit={handleSubmit} className="bg-white rounded-3xl p-8 shadow-large">
                    <h3 className="text-xl font-semibold mb-6">Välj ditt namn</h3>
                    
                    <div className="space-y-4">
                      <div>
                        <label htmlFor="name" className="block text-sm font-medium text-gray-700 mb-2">
                          Vad ska vi kalla dig?
                        </label>
                        <input
                          id="name"
                          type="text"
                          value={name}
                          onChange={(e) => setName(e.target.value)}
                          placeholder="Ditt namn..."
                          className="w-full px-4 py-3 rounded-2xl border border-gray-200 outline-none transition-all focus:border-brand-green focus:ring-4 focus:ring-brand-green/10"
                          autoComplete="off"
                          autoFocus
                        />
                        {loginError && (
                          <p className="mt-2 text-sm text-red-600 flex items-center gap-2 animate-slide-down">
                            <AlertCircle className="h-4 w-4" />
                            {loginError}
                          </p>
                        )}
                      </div>

                      <button
                        type="submit"
                        disabled={!canJoin || loginState === 'loading'}
                        className="btn w-full py-3.5 rounded-2xl bg-gradient-to-r from-brand-green to-brand-green-light text-white shadow-large hover-lift disabled:hover:translate-y-0 disabled:hover:shadow-large text-lg font-medium"
                      >
                        {loginState === 'loading' ? (
                          <>
                            <Loader2 className="mr-2 h-5 w-5 animate-spin" />
                            Ansluter...
                          </>
                        ) : loginState === 'success' ? (
                          <>
                            <CheckCircle2 className="mr-2 h-5 w-5" />
                            Välkommen!
                          </>
                        ) : (
                          <>
                            Anslut
                            <ArrowRight className="ml-2 h-5 w-5" />
                          </>
                        )}
                      </button>

                      <p className="text-xs text-gray-500 text-center">
                        Genom att ansluta godkänner du att detta är en öppen demo-tjänst 
                        med enkel säkerhet. Max 5 användare åt gången.
                      </p>
                    </div>
                  </form>
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* Footer */}
        <footer className="py-12 border-t border-gray-200 safe-bottom">
          <div className="mx-auto max-w-6xl px-4 sm:px-6">
            <div className="flex flex-col md:flex-row items-center justify-between gap-6">
              <div className="flex items-center gap-3">
                <div className="h-10 w-10 rounded-2xl overflow-hidden shadow-medium">
                  <img 
                    src="/logo.png" 
                    alt="Mugharred Logo" 
                    className="h-full w-full object-cover"
                  />
                </div>
                <div>
                  <p className="font-semibold">Mugharred</p>
                  <p className="text-sm text-gray-600">© {new Date().getFullYear()} • Skapad med kärlek i Sverige</p>
                </div>
              </div>

              <nav className="flex flex-wrap items-center justify-center gap-6 text-sm">
                <a href="#features" className="text-gray-600 hover:text-gray-900 transition-colors">
                  Funktioner
                </a>
                <a href="#how" className="text-gray-600 hover:text-gray-900 transition-colors">
                  Hur det funkar
                </a>
                <a href="#security" className="text-gray-600 hover:text-gray-900 transition-colors">
                  Säkerhet
                </a>
                <a href="#join" className="text-brand-green hover:text-brand-green-dark transition-colors font-medium">
                  Gå med nu
                </a>
              </nav>
            </div>
          </div>
        </footer>
      </main>
    </div>
  );
}