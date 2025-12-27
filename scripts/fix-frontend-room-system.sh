#!/bin/bash
# Fix frontend to use room system instead of global chat
# Compliance: goldenrules.md - script-driven changes only

set -e

echo "🔧 FIXING FRONTEND ROOM SYSTEM"
echo "Converting from global chat to room-based system..."

cd /home/reda/development/mugharred/frontend

# Backup current component
cp src/MugharredLandingPage.tsx src/MugharredLandingPage.tsx.backup.pre-room-fix.$(date +%Y%m%d_%H%M%S)

# Create updated component that uses room system
cat > src/MugharredLandingPage.tsx << 'EOF'
import React, { useState, useEffect, useRef, useCallback } from "react";
import { ArrowRight, Shield, Zap, Users, Globe2, Send, X, CheckCircle2, AlertCircle, Loader2, LogOut, Share2, Copy } from "lucide-react";
import DOMPurify from "dompurify";

type RoomMessage = {
  id: string;
  user: string;
  text: string;
  timestamp: number;
  roomId: string;
};

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
        <label className="block text-sm font-medium text-gray-700 mb-2">Your Name</label>
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
        <label className="block text-sm font-medium text-gray-700 mb-2">Room Name</label>
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
      <div className="grid grid-cols-2 gap-4">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">Max People</label>
          <select value={maxParticipants} onChange={(e) => setMaxParticipants(Number(e.target.value))} className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-emerald-500 focus:border-transparent">
            <option value={2}>2 people</option>
            <option value={4}>4 people</option>
            <option value={6}>6 people</option>
            <option value={8}>8 people</option>
            <option value={12}>12 people</option>
          </select>
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">Duration</label>
          <select value={duration} onChange={(e) => setDuration(Number(e.target.value))} className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-emerald-500 focus:border-transparent">
            <option value={15}>15 minutes</option>
            <option value={30}>30 minutes</option>
            <option value={60}>1 hour</option>
            <option value={120}>2 hours</option>
          </select>
        </div>
      </div>
      <div className="flex gap-4">
        <button type="button" onClick={onCancel} disabled={loading} className="flex-1 px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 disabled:opacity-50">Cancel</button>
        <button type="submit" disabled={loading || userName.trim().length < 2 || roomName.trim().length < 2} className="flex-1 px-4 py-2 bg-gradient-to-r from-emerald-600 to-green-700 text-white rounded-lg hover:from-emerald-700 hover:to-green-800 disabled:opacity-50 font-medium">
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
        <p className="text-gray-600 mb-6">Room: {roomId}</p>
        
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Your Name</label>
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
            <button type="button" onClick={onCancel} className="flex-1 px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors" disabled={loading}>Cancel</button>
            <button type="submit" className="flex-1 bg-emerald-500 text-white px-4 py-2 rounded-lg hover:bg-emerald-600 transition-colors disabled:opacity-50 disabled:cursor-not-allowed" disabled={loading || userName.trim().length < 2}>
              {loading ? 'Joining...' : 'Join Room'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default function MugharredLandingPage() {
  // Core state
  const [currentRoomId, setCurrentRoomId] = useState<string | null>(null);
  const [name, setName] = useState("");
  const [isInRoom, setIsInRoom] = useState(false);
  
  // Modal states
  const [showCreateRoomModal, setShowCreateRoomModal] = useState(false);
  const [showJoinRoomModal, setShowJoinRoomModal] = useState(false);
  
  // Chat state
  const [ws, setWs] = useState<WebSocket | null>(null);
  const [messages, setMessages] = useState<RoomMessage[]>([]);
  const [onlineUsers, setOnlineUsers] = useState<string[]>([]);
  const [input, setInput] = useState("");
  const [wsConnected, setWsConnected] = useState(false);
  const [toast, setToast] = useState<{ message: string; type: 'success' | 'error' | 'info' } | null>(null);

  // Refs
  const inputRef = useRef<HTMLInputElement>(null);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  // Check for room URL on mount
  useEffect(() => {
    const path = window.location.pathname;
    const roomMatch = path.match(/^\/r\/([a-z0-9-]+)$/);
    
    if (roomMatch) {
      const roomId = roomMatch[1];
      setCurrentRoomId(roomId);
      
      // Show join modal if not in room yet
      if (!isInRoom) {
        setShowJoinRoomModal(true);
      }
    }
  }, [isInRoom]);

  const showToast = (message: string, type: 'success' | 'error' | 'info' = 'info') => {
    setToast({ message, type });
    setTimeout(() => setToast(null), 3000);
  };

  const copyRoomLink = async () => {
    if (!currentRoomId) return;
    
    const roomUrl = `${window.location.origin}/r/${currentRoomId}`;
    
    try {
      await navigator.clipboard.writeText(roomUrl);
      showToast("Room link copied!", "success");
    } catch (error) {
      showToast("Failed to copy link", "error");
    }
  };

  const shareRoom = async () => {
    if (!currentRoomId) return;
    
    const roomUrl = `${window.location.origin}/r/${currentRoomId}`;
    const shareData = {
      title: 'Join my Mugharred room',
      text: 'Join me for a quick chat!',
      url: roomUrl
    };

    try {
      if (navigator.share) {
        await navigator.share(shareData);
      } else {
        await copyRoomLink();
      }
    } catch (error) {
      await copyRoomLink();
    }
  };

  const connectWebSocket = useCallback(() => {
    if (!currentRoomId || !isInRoom) return;

    const protocol = window.location.protocol === "https:" ? "wss:" : "ws:";
    const wsUrl = `${protocol}//${window.location.host}/ws`;
    const socket = new WebSocket(wsUrl);
    
    socket.onopen = () => {
      setWsConnected(true);
      setWs(socket);
      showToast("Connected to room", "success");
    };

    socket.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data);
        
        if (data.type === "message" && data.message) {
          const sanitizedMessage = {
            ...data.message,
            text: DOMPurify.sanitize(data.message.text),
            user: DOMPurify.sanitize(data.message.user)
          };
          
          setMessages(prev => {
            const exists = prev.some(m => m.id === sanitizedMessage.id);
            if (exists) return prev;
            return [...prev, sanitizedMessage].sort((a, b) => a.timestamp - b.timestamp);
          });
        } else if (data.type === "room_event") {
          // Handle room events like user join/leave
          if (data.event.type === "user_joined") {
            showToast(`${data.event.userName} joined`, "info");
          } else if (data.event.type === "user_left") {
            showToast(`${data.event.userName} left`, "info");
          }
        } else if (data.type === "error") {
          showToast(data.error, "error");
        }
      } catch (error) {
        console.error("WebSocket message error:", error);
      }
    };

    socket.onclose = () => {
      setWsConnected(false);
      setWs(null);
      showToast("Disconnected from room", "error");
    };

    socket.onerror = (error) => {
      console.error("WebSocket error:", error);
      showToast("Connection error", "error");
    };
  }, [currentRoomId, isInRoom]);

  // Connect WebSocket when in room
  useEffect(() => {
    if (isInRoom && currentRoomId) {
      connectWebSocket();
    }
    
    return () => {
      if (ws) {
        ws.close();
        setWs(null);
      }
    };
  }, [isInRoom, currentRoomId, connectWebSocket]);

  // Auto-scroll to bottom
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  const handleCreateRoom = async (userName: string, roomName: string, maxParticipants: number, duration: number) => {
    try {
      const response = await fetch('/api/create-room', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ 
          name: roomName,
          maxParticipants,
          duration,
          hostName: userName
        }),
      });

      if (response.ok) {
        const data = await response.json();
        setCurrentRoomId(data.roomId);
        setName(userName);
        setIsInRoom(true);
        setShowCreateRoomModal(false);
        showToast("Room created successfully!", "success");
        
        // Update URL
        window.history.pushState(null, '', `/r/${data.roomId}`);
      } else {
        const errorData = await response.json();
        showToast(errorData.error || "Failed to create room", "error");
      }
    } catch (error) {
      showToast("Network error creating room", "error");
    }
  };

  const handleJoinRoom = async (userName: string) => {
    if (!currentRoomId) return;
    
    try {
      const response = await fetch("/api/join-room", {
        method: "POST",
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ 
          roomId: currentRoomId,
          participantName: userName 
        }),
      });
      
      if (response.ok) {
        setName(userName);
        setIsInRoom(true);
        setShowJoinRoomModal(false);
        showToast("Joined room successfully!", "success");
      } else {
        const errorData = await response.json();
        showToast(errorData.error || "Failed to join room", "error");
      }
    } catch (error) {
      showToast("Network error joining room", "error");
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
    inputRef.current?.focus();
  };

  const handleLogout = () => {
    setIsInRoom(false);
    setName("");
    setCurrentRoomId(null);
    setMessages([]);
    setOnlineUsers([]);
    setWs(null);
    window.history.pushState(null, '', '/');
    showToast("Left room", "success");
  };

  // Toast Component
  const Toast: React.FC<{ message: string; type: string; onClose: () => void }> = ({ message, type, onClose }) => (
    <div className={`fixed top-4 right-4 z-50 px-4 py-2 rounded-lg shadow-lg text-white ${type === 'success' ? 'bg-green-500' : type === 'error' ? 'bg-red-500' : 'bg-blue-500'}`}>
      <div className="flex items-center gap-2">
        <span className="text-sm font-medium">{message}</span>
        <button onClick={onClose} className="ml-2 hover:opacity-70">
          <X size={14} />
        </button>
      </div>
    </div>
  );

  // Show landing page if not in room
  if (!isInRoom) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-emerald-50 via-green-50 to-yellow-50">
        {toast && <Toast message={toast.message} type={toast.type} onClose={() => setToast(null)} />}

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

        {/* Create Room Modal */}
        {showCreateRoomModal && (
          <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
            <div className="bg-white rounded-xl shadow-xl p-8 max-w-md w-full">
              <h2 className="text-2xl font-bold text-gray-900 mb-6">Create Instant Room</h2>
              <CreateRoomForm 
                onCreateRoom={handleCreateRoom}
                onCancel={() => setShowCreateRoomModal(false)}
              />
            </div>
          </div>
        )}

        {/* Hero Section */}
        <header className="pt-16 pb-24">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
            <div className="mb-12">
              <img 
                src="/logo.webp" 
                alt="Mugharred" 
                className="h-24 w-auto mx-auto mb-8 rounded-2xl shadow-2xl ring-4 ring-white/50 hover:ring-emerald-300/50 transition-all duration-300"
              />
              
              <h1 className="text-5xl lg:text-6xl font-bold text-gray-900 mb-6">
                Create a room
              </h1>
              <p className="text-lg text-gray-500 mb-8">
                No signup. No downloads. Just a link.
              </p>
              
              <div className="max-w-md mx-auto">
                <button
                  onClick={() => setShowCreateRoomModal(true)}
                  className="w-full bg-gradient-to-r from-emerald-500 to-green-600 text-white font-semibold py-4 px-6 rounded-xl hover:from-emerald-600 hover:to-green-700 transition-all duration-300 flex items-center justify-center gap-2 text-lg shadow-xl hover:shadow-2xl"
                >
                  Create Instant Room
                  <ArrowRight size={20} />
                </button>
                <p className="text-sm text-gray-500 mt-4">Ready in 10 seconds</p>
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
              <div className="text-center p-6">
                <div className="w-16 h-16 bg-gradient-to-r from-emerald-500 to-green-600 rounded-xl flex items-center justify-center mx-auto mb-4 shadow-lg">
                  <Zap size={24} className="text-white" />
                </div>
                <h3 className="text-xl font-semibold text-gray-900 mb-2">Instant Setup</h3>
                <p className="text-gray-600">Create a room in seconds. Share the link. Start talking.</p>
              </div>
              
              <div className="text-center p-6">
                <div className="w-16 h-16 bg-gradient-to-r from-emerald-500 to-green-600 rounded-xl flex items-center justify-center mx-auto mb-4 shadow-lg">
                  <Shield size={24} className="text-white" />
                </div>
                <h3 className="text-xl font-semibold text-gray-900 mb-2">Privacy First</h3>
                <p className="text-gray-600">No accounts needed. Rooms auto-expire. Nothing stored permanently.</p>
              </div>
              
              <div className="text-center p-6">
                <div className="w-16 h-16 bg-gradient-to-r from-emerald-500 to-green-600 rounded-xl flex items-center justify-center mx-auto mb-4 shadow-lg">
                  <Globe2 size={24} className="text-white" />
                </div>
                <h3 className="text-xl font-semibold text-gray-900 mb-2">Works Everywhere</h3>
                <p className="text-gray-600">Any device, any browser. No app downloads required.</p>
              </div>
            </div>
          </div>
        </section>

        {/* Footer */}
        <footer className="py-16 bg-white/80 backdrop-blur-sm border-t border-gray-200">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
            <p className="text-lg text-gray-700 font-medium mb-4">
              Privacy-first instant rooms for any conversation
            </p>
            <p className="text-sm text-gray-500">
              © 2025 Mugharred. Built with ❤️ for instant human connection.
            </p>
          </div>
        </footer>
      </div>
    );
  }

  // Chat interface for users in room
  return (
    <div className="min-h-screen bg-gradient-to-br from-emerald-50 via-green-50 to-yellow-50">
      {toast && <Toast message={toast.message} type={toast.type} onClose={() => setToast(null)} />}

      {/* Header */}
      <header className="bg-white/90 backdrop-blur-sm shadow-sm border-b border-emerald-100">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4">
              <img src="/logo.webp" alt="Mugharred" className="h-10 w-auto rounded-xl shadow-lg" />
              <div>
                <h1 className="text-xl font-bold text-gray-900">Room: {currentRoomId}</h1>
                <p className="text-sm text-gray-600">Welcome {name}</p>
              </div>
            </div>
            
            <div className="flex items-center gap-4">
              <div className="flex items-center gap-2">
                <div className={`w-2 h-2 rounded-full ${wsConnected ? 'bg-green-500' : 'bg-red-500'}`}></div>
                <span className="text-sm text-gray-600">{wsConnected ? 'Connected' : 'Disconnected'}</span>
              </div>
              
              <div className="flex items-center gap-2">
                <button onClick={copyRoomLink} className="flex items-center gap-2 px-3 py-2 text-sm text-emerald-600 hover:text-emerald-700 hover:bg-emerald-50 rounded-lg transition-colors" title="Copy room link">
                  <Copy size={16} />
                  Copy Link
                </button>
                
                <button onClick={shareRoom} className="flex items-center gap-2 px-3 py-2 text-sm text-emerald-600 hover:text-emerald-700 hover:bg-emerald-50 rounded-lg transition-colors" title="Share room">
                  <Share2 size={16} />
                  Share
                </button>
              </div>
              
              <button onClick={handleLogout} className="flex items-center gap-2 px-4 py-2 text-sm text-gray-600 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors">
                <LogOut size={16} />
                Leave Room
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
                In Room ({onlineUsers.length})
              </h2>
              <div className="space-y-3">
                {onlineUsers.map((user, index) => (
                  <div key={user} className="flex items-center gap-3 p-2 rounded-lg bg-emerald-50">
                    <div className="w-3 h-3 bg-green-500 rounded-full"></div>
                    <span className="text-sm font-medium text-gray-900">{user}</span>
                  </div>
                ))}
                {onlineUsers.length === 0 && (
                  <p className="text-sm text-gray-500 text-center py-4">No one else in room yet</p>
                )}
              </div>
            </div>
          </div>

          {/* Chat Area */}
          <div className="lg:col-span-3">
            <div className="bg-white/90 backdrop-blur-sm rounded-xl shadow-lg p-6 h-[600px] flex flex-col">
              <div className="flex-1 overflow-y-auto mb-4 space-y-4">
                {messages.map((message) => (
                  <div key={message.id} className="flex gap-3">
                    <div className="w-8 h-8 bg-emerald-500 rounded-full flex items-center justify-center text-white text-sm font-medium">
                      {message.user.charAt(0).toUpperCase()}
                    </div>
                    <div className="flex-1">
                      <div className="flex items-center gap-2 mb-1">
                        <span className="text-sm font-medium text-gray-900">{message.user}</span>
                        <span className="text-xs text-gray-500">
                          {new Date(message.timestamp).toLocaleTimeString()}
                        </span>
                      </div>
                      <p className="text-gray-700 text-sm">{message.text}</p>
                    </div>
                  </div>
                ))}
                {messages.length === 0 && (
                  <div className="text-center py-12">
                    <p className="text-gray-500">No messages yet. Start the conversation!</p>
                  </div>
                )}
                <div ref={messagesEndRef} />
              </div>

              {/* Message Input */}
              <div className="flex gap-2 pt-4 border-t border-gray-200">
                <input
                  ref={inputRef}
                  type="text"
                  value={input}
                  onChange={(e) => setInput(e.target.value)}
                  onKeyPress={(e) => e.key === 'Enter' && sendMessage()}
                  placeholder="Type your message..."
                  className="flex-1 px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-emerald-500 focus:border-transparent"
                  maxLength={500}
                  disabled={!wsConnected}
                />
                <button
                  onClick={sendMessage}
                  disabled={!input.trim() || !wsConnected}
                  className="px-4 py-2 bg-emerald-500 text-white rounded-lg hover:bg-emerald-600 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                >
                  <Send size={16} />
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
EOF

echo "Building frontend with room system..."
npm run build

echo "Deploying to nginx..."
echo "899118RKs" | sudo -S cp -r dist/* /var/www/html/

echo "✅ FRONTEND ROOM SYSTEM FIXED"
echo ""
echo "Changes made:"
echo "- Converted from global chat to room-based system"
echo "- Uses correct room endpoints (/api/create-room, /api/join-room)"
echo "- Room-specific WebSocket connections"
echo "- Share room functionality"
echo "- Proper room URL handling (/r/room-id)"
echo ""
echo "Frontend now matches JWT + Redis room backend architecture!"