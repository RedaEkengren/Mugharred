import React, { useMemo, useState, useEffect, useRef, useCallback } from "react";
import { 
  ArrowRight, Shield, Zap, Users, Globe2, Send, X, 
  CheckCircle2, AlertCircle, Loader2, LogOut, Eye, Share2, Copy
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

// Room Creation Form Component
const CreateRoomForm: React.FC<{
  onCreateRoom: (userName: string, roomName: string, maxParticipants: number, duration: number) => Promise<void>;
  onCancel: () => void;
}> = ({ onCreateRoom, onCancel }) => {
  const [roomName, setRoomName] = useState('');
  const [userName, setUserName] = useState('');
  const [maxParticipants, setMaxParticipants] = useState(4);
  const [duration, setDuration] = useState(30);
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (roomName.trim().length < 2 || userName.trim().length < 2) return;
    
    setLoading(true);
    try {
      await onCreateRoom(userName.trim(), roomName.trim(), maxParticipants, duration);
    } finally {
      setLoading(false);
    }
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-2">
          Your Name
        </label>
        <input
          type="text"
          value={userName}
          onChange={(e) => setUserName(e.target.value)}
          className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-emerald-500 focus:border-transparent"
          placeholder="Enter your name..."
          required
          minLength={2}
          maxLength={50}
        />
      </div>
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-2">
          Room Name
        </label>
        <input
          type="text"
          value={roomName}
          onChange={(e) => setRoomName(e.target.value)}
          className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-emerald-500 focus:border-transparent"
          placeholder="Trip planning, Team meeting..."
          required
          minLength={2}
          maxLength={50}
        />
      </div>

      <div>
        <label className="block text-sm font-medium text-gray-700 mb-2">
          Max Participants: {maxParticipants}
        </label>
        <input
          type="range"
          min={2}
          max={12}
          value={maxParticipants}
          onChange={(e) => setMaxParticipants(Number(e.target.value))}
          className="w-full"
        />
        <div className="flex justify-between text-sm text-gray-500 mt-1">
          <span>2</span>
          <span>12</span>
        </div>
      </div>

      <div>
        <label className="block text-sm font-medium text-gray-700 mb-2">
          Duration
        </label>
        <select
          value={duration}
          onChange={(e) => setDuration(Number(e.target.value))}
          className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-emerald-500"
        >
          <option value={15}>15 minutes</option>
          <option value={30}>30 minutes</option>
          <option value={60}>1 hour</option>
          <option value={120}>2 hours</option>
        </select>
      </div>

      <div className="flex gap-3 pt-4">
        <button
          type="button"
          onClick={onCancel}
          disabled={loading}
          className="flex-1 px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 disabled:opacity-50"
        >
          Cancel
        </button>
        <button
          type="submit"
          disabled={loading || userName.trim().length < 2 || roomName.trim().length < 2}
          className="flex-1 px-4 py-2 bg-gradient-to-r from-emerald-600 to-green-700 text-white rounded-lg hover:from-emerald-700 hover:to-green-800 disabled:opacity-50 font-medium"
        >
          {loading ? 'Creating...' : 'Create Room'}
        </button>
      </div>
    </form>
  );
};

// Join Room Modal Component
const JoinRoomModal: React.FC<{
  roomId: string;
  onJoin: (userName: string) => Promise<void>;
  onCancel: () => void;
}> = ({ roomId, onJoin, onCancel }) => {
  const [userName, setUserName] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (userName.trim().length < 2) return;
    
    setLoading(true);
    try {
      await onJoin(userName.trim());
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
      <div className="bg-white rounded-xl shadow-xl p-8 max-w-md w-full">
        <h2 className="text-2xl font-bold text-gray-900 mb-2">Join Room</h2>
        <p className="text-gray-600 mb-6">Room ID: {roomId}</p>
        
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Your Name
            </label>
            <input
              type="text"
              value={userName}
              onChange={(e) => setUserName(e.target.value)}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-emerald-500 focus:border-transparent"
              placeholder="Enter your name..."
              required
              minLength={2}
              maxLength={50}
              autoFocus
            />
          </div>
          
          <div className="flex gap-4">
            <button
              type="button"
              onClick={onCancel}
              className="flex-1 px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors"
              disabled={loading}
            >
              Cancel
            </button>
            <button
              type="submit"
              className="flex-1 bg-emerald-500 text-white px-4 py-2 rounded-lg hover:bg-emerald-600 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
              disabled={loading || userName.trim().length < 2}
            >
              {loading ? 'Joining...' : 'Join Room'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

// Secure API utilities - now uses JWT from wrapper
class SecureAPI {
  static async secureRequest(url: string, options: RequestInit = {}): Promise<Response> {
    // JWT token is added automatically by jwt-wrapper.ts
    const headers = {
      'Content-Type': 'application/json',
      ...options.headers,
    };

    return fetch(url, {
      ...options,
      headers,
    });
  }

  static clearToken() {
    // JWT handled by wrapper
  }
}

export default function MugharredLandingPage() {
  // Core state
  const [sessionId, setSessionId] = useState<string | null>(null);
  const [currentRoomId, setCurrentRoomId] = useState<string | null>(null);
  const [name, setName] = useState("");
  
  // Modal states
  const [showCreateRoomModal, setShowCreateRoomModal] = useState(false);
  const [showJoinRoomModal, setShowJoinRoomModal] = useState(false);
  
  // Rotating text for hero section
  const rotatingTexts = [
    "Trip planning",
    "Job interviews", 
    "Study sessions",
    "Team meetings",
    "Friend chats",
    "Quick calls",
    "Customer support",
    "Book clubs",
    "Gaming sessions",
    "Brainstorming"
  ];
  
  const [currentTextIndex, setCurrentTextIndex] = useState(0);
  
  // Legal modal state
  const [activeModal, setActiveModal] = useState<'privacy' | 'terms' | 'about' | null>(null);
  
  // Chat state
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

  // Check for room URL on mount
  useEffect(() => {
    const path = window.location.pathname;
    const roomMatch = path.match(/^\/r\/([a-z0-9-]+)$/);
    
    if (roomMatch) {
      const roomId = roomMatch[1];
      console.log("Detected room URL:", roomId);
      setCurrentRoomId(roomId);
      
      // If not logged in, show join modal
      if (!sessionId) {
        setShowJoinRoomModal(true);
      }
    }
  }, [sessionId]);
  
  // Update URL when room changes (for sharing)
  useEffect(() => {
    if (currentRoomId && sessionId) {
      const newUrl = `/r/${currentRoomId}`;
      if (window.location.pathname !== newUrl) {
        window.history.pushState(null, '', newUrl);
      }
    }
  }, [currentRoomId, sessionId]);

  // Rotating text animation
  useEffect(() => {
    const interval = setInterval(() => {
      setCurrentTextIndex((prev) => (prev + 1) % rotatingTexts.length);
    }, 2500);
    
    return () => clearInterval(interval);
  }, [rotatingTexts.length]);

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

  const copyRoomLink = async () => {
    if (!currentRoomId) return;
    
    const roomUrl = `${window.location.origin}/r/${currentRoomId}`;
    
    try {
      await navigator.clipboard.writeText(roomUrl);
      showToast("Room link copied to clipboard!", "success");
    } catch (error) {
      console.error("Failed to copy:", error);
      showToast("Failed to copy link", "error");
    }
  };

  const shareRoom = async () => {
    if (!currentRoomId) return;
    
    const roomUrl = `${window.location.origin}/r/${currentRoomId}`;
    const shareData = {
      title: 'Join my Mugharred room',
      text: `Join me in this instant room for a quick chat!`,
      url: roomUrl
    };

    try {
      if (navigator.share) {
        await navigator.share(shareData);
      } else {
        // Fallback to copy
        await copyRoomLink();
      }
    } catch (error) {
      console.error("Share failed:", error);
      // Fallback to copy
      await copyRoomLink();
    }
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
      
      showToast("Logged out successfully", "success");
    } catch (error) {
      console.error('Logout error:', error);
      showToast("Logout error", "error");
    }
  };

  const connectWebSocket = useCallback(() => {
    if (!sessionId) return;

    const maxReconnectAttempts = 5;
    let reconnectAttempts = 0;

    function connect() {
      // Get JWT token from localStorage
      const token = localStorage.getItem('mugharred_token');
      if (!token) {
        console.error('No JWT token found');
        return;
      }

      const protocol = window.location.protocol === "https:" ? "wss:" : "ws:";
      const wsUrl = `${protocol}//${window.location.host}/ws?token=${encodeURIComponent(token)}`;
      const socket = new WebSocket(wsUrl);
      
      socket.onopen = () => {
        setWsConnected(true);
        reconnectAttempts = 0;
        
        // If we have a room, join it
        if (currentRoomId && name) {
          socket.send(JSON.stringify({
            type: 'join_room',
            roomId: currentRoomId,
            name: name
          }));
        }
        
        showToast("Connected to real-time", "success");
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
          } else if (data.type === "participants_update") {
            const sanitizedUsers = data.users.map((user: string) => DOMPurify.sanitize(user));
            setOnlineUsers(sanitizedUsers);
          } else if (data.type === "room_event") {
            if (data.event.type === "participants_update") {
              const participants = data.event.participants || [];
              setOnlineUsers(participants.map((p: any) => p.name || p));
            }
          } else if (data.type === "joined_room" && data.token) {
            // Update token when successfully joining room via WebSocket
            localStorage.setItem('mugharred_token', data.token);
            showToast("Successfully joined room!", "success");
          } else if (data.type === "error") {
            showToast(data.error, "error");
          }
        } catch (error) {
          console.error("WebSocket message error:", error);
        }
      };

      socket.onclose = () => {
        setWsConnected(false);
        
        if (reconnectAttempts < maxReconnectAttempts && sessionId) {
          reconnectAttempts++;
          showToast(`Reconnecting... (${reconnectAttempts}/${maxReconnectAttempts})`, "info");
          setTimeout(connect, Math.min(1000 * Math.pow(2, reconnectAttempts), 10000));
        } else if (reconnectAttempts >= maxReconnectAttempts) {
          showToast("Connection failed. Please reload.", "error");
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
  }, [sessionId, currentRoomId, name]);

  // Connect WebSocket when logged in
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
      // Room messages come through WebSocket, no need to fetch
      setMessages([]);
      setOnlineUsers([]);
    }
  }, [sessionId]);

  const handleCreateRoom = async (userName: string, roomName: string, maxParticipants: number, duration: number) => {
    try {
      // First login the user
      const loginResponse = await SecureAPI.secureRequest("/api/login", {
        method: "POST",
        body: JSON.stringify({ name: userName }),
      });
      
      if (!loginResponse.ok) {
        const errorData = await loginResponse.json();
        showToast(errorData.error || "Failed to login", "error");
        return;
      }
      
      const loginData = await loginResponse.json();
      // JWT token is saved by wrapper, just set logged in state
      setSessionId(loginData.token || 'logged-in');
      setName(userName);
      
      // JWT token managed by wrapper, no need to clear
      
      // Now create the room with the new session
      const response = await SecureAPI.secureRequest('/api/create-room', {
        method: 'POST',
        body: JSON.stringify({ 
          name: roomName,
          maxParticipants,
          duration,
          hostName: userName
        }),
      });

      if (response.ok) {
        const data = await response.json();
        setShowCreateRoomModal(false);
        setCurrentRoomId(data.roomId);
        showToast("Room created successfully!", "success");
        // Don't redirect - user is already logged in and should see chat
      } else {
        const errorData = await response.json();
        showToast(errorData.error || "Failed to create room", "error");
      }
    } catch (error) {
      console.error("Room creation error:", error);
      showToast("Network error creating room", "error");
    }
  };

  const handleJoinRoom = async (userName: string) => {
    try {
      // First login the user
      const loginResponse = await SecureAPI.secureRequest("/api/login", {
        method: "POST",
        body: JSON.stringify({ name: userName }),
      });
      
      if (!loginResponse.ok) {
        const errorData = await loginResponse.json();
        showToast(errorData.error || "Failed to login", "error");
        return;
      }
      
      const loginData = await loginResponse.json();
      // JWT token is saved by wrapper, just set logged in state
      setSessionId(loginData.token || 'logged-in');
      setName(userName);
      
      // JWT token managed by wrapper, no need to clear
      
      // Now join the room
      const response = await SecureAPI.secureRequest("/api/join-room", {
        method: "POST",
        body: JSON.stringify({ 
          roomId: currentRoomId,
          participantName: userName 
        }),
      });
      
      if (response.ok) {
        setShowJoinRoomModal(false);
        showToast("Joined room successfully!", "success");
      } else {
        const errorData = await response.json();
        showToast(errorData.error || "Failed to join room", "error");
      }
    } catch (error) {
      console.error("Join room error:", error);
      showToast("Network error joining room", "error");
    }
  };

  const sendMessage = () => {
    if (!input.trim() || !ws || ws.readyState !== WebSocket.OPEN) return;

    const sanitizedInput = DOMPurify.sanitize(input.trim());
    
    ws.send(JSON.stringify({
      type: "send_message",
      roomId: currentRoomId,
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

  // Show landing page if not logged in and not on room URL
  if (!sessionId && !currentRoomId) {
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
        <header className="relative overflow-hidden bg-gradient-to-br from-emerald-500/10 to-green-600/10">
          <div className="absolute inset-0 bg-gradient-to-br from-emerald-600/20 via-green-500/10 to-yellow-400/20"></div>
          <div className="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
            <div className="text-center">
              <div className="flex items-center justify-center mb-6">
                <img 
                  src="/logo.webp" 
                  alt="Mugharred" 
                  className="h-16 w-auto rounded-2xl shadow-2xl ring-4 ring-white/50 hover:ring-emerald-300/70 transition-all duration-300"
                />
              </div>
              <h1 className="text-5xl md:text-6xl font-bold text-gray-900 mb-6">
                <span className="bg-gradient-to-r from-emerald-600 to-green-800 bg-clip-text text-transparent">
                  Mugharred
                </span>
              </h1>
              <div className="text-xl md:text-2xl text-gray-600 mb-12 max-w-3xl mx-auto leading-relaxed">
                <p className="mb-4">
                  Create a room for{" "}
                  <span className="inline-block min-w-[200px] text-left">
                    <span 
                      key={currentTextIndex}
                      className="bg-gradient-to-r from-emerald-600 to-green-600 bg-clip-text text-transparent font-semibold animate-fade-in"
                    >
                      {rotatingTexts[currentTextIndex]}
                    </span>
                  </span>
                </p>
                <p className="text-lg text-gray-500">
                  No signup. No downloads. Just a link.
                </p>
              </div>
              
              {/* CTA Form directly in hero */}
              <div className="max-w-md mx-auto">
                <button
                  onClick={() => setShowCreateRoomModal(true)}
                  className="w-full bg-gradient-to-r from-emerald-500 to-green-600 text-white font-semibold py-4 px-6 rounded-xl hover:from-emerald-600 hover:to-green-700 transition-all duration-300 flex items-center justify-center gap-2 text-lg shadow-xl hover:shadow-2xl"
                >
                  Create Instant Room
                  <ArrowRight size={20} />
                </button>
                <p className="text-sm text-gray-500 mt-4">
                  Ready in 10 seconds
                </p>
              </div>
            </div>
          </div>
        </header>

        {/* Features */}
        <section className="py-16 bg-white/50 backdrop-blur-sm">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div className="text-center mb-16">
              <h2 className="text-3xl font-bold text-gray-900 mb-4">Why instant rooms?</h2>
              <p className="text-lg text-gray-600">Simple, fast and private</p>
            </div>
            
            <div className="grid md:grid-cols-3 gap-8">
              <div className="group p-8 rounded-xl bg-white/80 backdrop-blur-sm shadow-lg hover:shadow-xl transition-all duration-300 hover:-translate-y-2">
                <div className="w-12 h-12 bg-gradient-to-br from-emerald-500 to-green-600 rounded-lg flex items-center justify-center mb-6 group-hover:scale-110 transition-transform duration-300">
                  <Zap className="text-white" size={24} />
                </div>
                <h3 className="text-xl font-semibold text-gray-900 mb-3">Real-time</h3>
                <p className="text-gray-600">Messages appear instantly. No delays, just genuine conversation.</p>
              </div>
              
              <div className="group p-8 rounded-xl bg-white/80 backdrop-blur-sm shadow-lg hover:shadow-xl transition-all duration-300 hover:-translate-y-2">
                <div className="w-12 h-12 bg-gradient-to-br from-emerald-500 to-green-600 rounded-lg flex items-center justify-center mb-6 group-hover:scale-110 transition-transform duration-300">
                  <Shield className="text-white" size={24} />
                </div>
                <h3 className="text-xl font-semibold text-gray-900 mb-3">Privacy first</h3>
                <p className="text-gray-600">No ads, no tracking, minimal logging. Your conversations stay private.</p>
              </div>
              
              <div className="group p-8 rounded-xl bg-white/80 backdrop-blur-sm shadow-lg hover:shadow-xl transition-all duration-300 hover:-translate-y-2">
                <div className="w-12 h-12 bg-gradient-to-br from-emerald-500 to-green-600 rounded-lg flex items-center justify-center mb-6 group-hover:scale-110 transition-transform duration-300">
                  <Users className="text-white" size={24} />
                </div>
                <h3 className="text-xl font-semibold text-gray-900 mb-3">Room expires</h3>
                <p className="text-gray-600">Set a timer. Room auto-deletes when time runs out. No permanent history.</p>
              </div>
            </div>
          </div>
        </section>

        {/* Footer */}
        <footer className="py-16 bg-white/80 backdrop-blur-sm border-t border-gray-200">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div className="text-center">
              <div className="mb-8">
                <p className="text-lg text-gray-700 font-medium mb-2">
                  Privacy-first instant rooms for any conversation
                </p>
                <div className="flex items-center justify-center gap-2 text-emerald-600">
                  <Globe2 size={18} />
                  <span className="text-sm font-medium">Live at mugharred.se</span>
                </div>
              </div>
              
              <div className="flex flex-wrap items-center justify-center gap-6 mb-8 text-sm">
                <button 
                  onClick={() => setActiveModal('privacy')}
                  className="text-gray-600 hover:text-emerald-600 transition-colors duration-200 font-medium"
                >
                  Privacy Policy
                </button>
                <span className="text-gray-300">•</span>
                <button 
                  onClick={() => setActiveModal('terms')}
                  className="text-gray-600 hover:text-emerald-600 transition-colors duration-200 font-medium"
                >
                  Terms of Service
                </button>
                <span className="text-gray-300">•</span>
                <button 
                  onClick={() => setActiveModal('about')}
                  className="text-gray-600 hover:text-emerald-600 transition-colors duration-200 font-medium"
                >
                  About
                </button>
              </div>
              
              <div className="border-t border-gray-200 pt-8">
                <p className="text-sm text-gray-500">
                  © 2025 Mugharred. Built with ❤️ for instant human connection.
                </p>
              </div>
            </div>
          </div>
        </footer>

        {/* Room Creation Modal */}
        {showCreateRoomModal && (
          <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center p-4 z-50">
            <div className="bg-white/90 backdrop-blur-lg rounded-xl shadow-xl border border-white/20 p-8 w-full max-w-md">
              <h2 className="text-2xl font-bold text-gray-900 mb-6">Create Room</h2>
              
              <CreateRoomForm 
                onCreateRoom={handleCreateRoom}
                onCancel={() => setShowCreateRoomModal(false)}
              />
            </div>
          </div>
        )}

        {/* Legal Modals - Shortened for space */}
        {activeModal && (
          <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center p-4 z-50">
            <div className="bg-white rounded-xl shadow-xl max-w-4xl w-full max-h-[80vh] overflow-hidden">
              <div className="p-6 border-b border-gray-200 flex items-center justify-between">
                <h2 className="text-2xl font-bold text-gray-900">
                  {activeModal === 'privacy' && 'Privacy Policy'}
                  {activeModal === 'terms' && 'Terms of Service'}
                  {activeModal === 'about' && 'About Mugharred'}
                </h2>
                <button
                  onClick={() => setActiveModal(null)}
                  className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
                >
                  <X size={20} />
                </button>
              </div>
              <div className="p-6 overflow-auto max-h-[60vh]">
                <div className="prose prose-emerald max-w-none">
                  <p>Content for {activeModal} modal...</p>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>
    );
  }

  // Chat interface for logged in users OR room URLs
  return (
    <div className="min-h-screen bg-gradient-to-br from-emerald-50 via-green-50 to-yellow-50">
      {toast && (
        <Toast 
          message={toast.message} 
          type={toast.type} 
          onClose={() => setToast(null)} 
        />
      )}

      {/* Join Room Modal */}
      {showJoinRoomModal && currentRoomId && (
        <JoinRoomModal
          roomId={currentRoomId}
          onJoin={handleJoinRoom}
          onCancel={() => {
            setShowJoinRoomModal(false);
            window.location.href = "/";
          }}
        />
      )}

      {/* Header */}
      <header className="bg-white/90 backdrop-blur-sm shadow-sm border-b border-emerald-100">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4">
              <img 
                src="/logo.webp" 
                alt="Mugharred" 
                className="h-10 w-auto rounded-xl shadow-lg ring-2 ring-white/50 hover:ring-emerald-300/50 transition-all duration-300"
              />
              <div>
                <h1 className="text-xl font-bold text-gray-900">
                  {currentRoomId ? `Room: ${currentRoomId}` : "Mugharred"}
                </h1>
                <p className="text-sm text-gray-600">Welcome {name}</p>
              </div>
            </div>
            
            <div className="flex items-center gap-4">
              <div className="flex items-center gap-2">
                <div className={`w-2 h-2 rounded-full ${wsConnected ? 'bg-green-500' : 'bg-red-500'}`}></div>
                <span className="text-sm text-gray-600">
                  {wsConnected ? 'Connected' : 'Disconnected'}
                </span>
              </div>
              
              {/* Share buttons - only show if in room */}
              {currentRoomId && (
                <div className="flex items-center gap-2">
                  <button
                    onClick={copyRoomLink}
                    className="flex items-center gap-2 px-3 py-2 text-sm text-emerald-600 hover:text-emerald-700 hover:bg-emerald-50 rounded-lg transition-colors"
                    title="Copy room link"
                  >
                    <Copy size={16} />
                    Copy Link
                  </button>
                  
                  <button
                    onClick={shareRoom}
                    className="flex items-center gap-2 px-3 py-2 text-sm text-emerald-600 hover:text-emerald-700 hover:bg-emerald-50 rounded-lg transition-colors"
                    title="Share room"
                  >
                    <Share2 size={16} />
                    Share
                  </button>
                </div>
              )}
              
              <button
                onClick={handleLogout}
                className="flex items-center gap-2 px-4 py-2 text-sm text-gray-600 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors"
              >
                <LogOut size={16} />
                Log out
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
                Online ({onlineUsers.length})
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
                    placeholder="Type your message..."
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
                    Send
                  </button>
                </div>
                <div className="mt-2 text-xs text-gray-500">
                  {input.length}/500 characters
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
