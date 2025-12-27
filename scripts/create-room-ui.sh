#!/bin/bash
# STEG 3: Frontend Room Creation/Join UI  
# Updates /frontend/src/MugharredLandingPage.tsx for room functionality per Golden Rules
set -e

echo "🎨 STEG 3: Creating Frontend Room UI (Golden Rules Compliant)..."

# Create backup per Golden Rules script approach
echo "📦 Creating backup of current frontend component..."
cp frontend/src/MugharredLandingPage.tsx frontend/src/MugharredLandingPage.tsx.backup.$(date +%Y%m%d_%H%M%S)

echo "📝 Updating /frontend/src/MugharredLandingPage.tsx for MVP room functionality..."

# Update the React component to support room creation/joining per MVP.md Phase 1
cat > frontend/src/MugharredLandingPage.tsx << 'EOF'
import React, { useState, useEffect, useRef } from 'react';
import DOMPurify from 'dompurify';

// Types for room functionality
interface Room {
  id: string;
  name: string;
  hostId: string;
  maxParticipants: number;
  duration: number;
  expiresAt: number;
  participantCount: number;
  isLocked: boolean;
}

interface CreateRoomRequest {
  name: string;
  maxParticipants: number;
  duration: number;
}

// Room creation form component
const CreateRoomForm: React.FC<{
  onCreateRoom: (request: CreateRoomRequest) => Promise<void>;
  onCancel: () => void;
  loading: boolean;
}> = ({ onCreateRoom, onCancel, loading }) => {
  const [roomName, setRoomName] = useState('');
  const [maxParticipants, setMaxParticipants] = useState(4);
  const [duration, setDuration] = useState(30);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (roomName.trim().length < 2) return;
    
    await onCreateRoom({
      name: roomName.trim(),
      maxParticipants,
      duration
    });
  };

  return (
    <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center p-4 z-50">
      <div className="bg-white/90 backdrop-blur-lg rounded-xl shadow-xl border border-white/20 p-8 w-full max-w-md">
        <h2 className="text-2xl font-bold text-gray-900 mb-6">Create Room</h2>
        
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Room Name
            </label>
            <input
              type="text"
              value={roomName}
              onChange={(e) => setRoomName(e.target.value)}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
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
              Duration: {duration} minutes
            </label>
            <select
              value={duration}
              onChange={(e) => setDuration(Number(e.target.value))}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500"
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
              disabled={loading || roomName.trim().length < 2}
              className="flex-1 px-4 py-2 bg-gradient-to-r from-green-600 to-green-700 text-white rounded-lg hover:from-green-700 hover:to-green-800 disabled:opacity-50 font-medium"
            >
              {loading ? 'Creating...' : 'Create Room'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

// Join room form component  
const JoinRoomForm: React.FC<{
  onJoinRoom: (roomId: string, displayName: string) => Promise<void>;
  onCancel: () => void;
  loading: boolean;
  initialRoomId?: string;
}> = ({ onJoinRoom, onCancel, loading, initialRoomId = '' }) => {
  const [roomId, setRoomId] = useState(initialRoomId);
  const [displayName, setDisplayName] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (roomId.trim().length < 3 || displayName.trim().length < 2) return;
    
    await onJoinRoom(roomId.trim(), displayName.trim());
  };

  return (
    <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center p-4 z-50">
      <div className="bg-white/90 backdrop-blur-lg rounded-xl shadow-xl border border-white/20 p-8 w-full max-w-md">
        <h2 className="text-2xl font-bold text-gray-900 mb-6">Join Room</h2>
        
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Room ID
            </label>
            <input
              type="text"
              value={roomId}
              onChange={(e) => setRoomId(e.target.value)}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
              placeholder="quiet-sun-5821"
              required
              minLength={3}
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Your Name
            </label>
            <input
              type="text"
              value={displayName}
              onChange={(e) => setDisplayName(e.target.value)}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
              placeholder="Your display name"
              required
              minLength={2}
              maxLength={30}
            />
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
              disabled={loading || roomId.trim().length < 3 || displayName.trim().length < 2}
              className="flex-1 px-4 py-2 bg-gradient-to-r from-green-600 to-green-700 text-white rounded-lg hover:from-green-700 hover:to-green-800 disabled:opacity-50 font-medium"
            >
              {loading ? 'Joining...' : 'Join Room'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

// Updated landing page component
export default function MugharredLandingPage() {
  const [showCreateRoom, setShowCreateRoom] = useState(false);
  const [showJoinRoom, setShowJoinRoom] = useState(false);
  const [loading, setLoading] = useState(false);

  // Check for room ID in URL path
  useEffect(() => {
    const path = window.location.pathname;
    const roomMatch = path.match(/^\/r\/([a-z0-9-]+)$/);
    if (roomMatch) {
      const roomId = roomMatch[1];
      setShowJoinRoom(true);
      // Auto-fill room ID in join form
    }
  }, []);

  const handleCreateRoom = async (request: CreateRoomRequest) => {
    setLoading(true);
    try {
      const response = await fetch('/api/create-room', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        credentials: 'include',
        body: JSON.stringify(request)
      });

      if (!response.ok) {
        throw new Error('Failed to create room');
      }

      const result = await response.json();
      
      // Navigate to room URL
      window.location.href = `/r/${result.roomId}`;
      
    } catch (error) {
      console.error('Create room error:', error);
      alert('Failed to create room. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const handleJoinRoom = async (roomId: string, displayName: string) => {
    setLoading(true);
    try {
      const response = await fetch(`/api/join-room/${roomId}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        credentials: 'include',
        body: JSON.stringify({ displayName })
      });

      if (!response.ok) {
        throw new Error('Failed to join room');
      }

      // Navigate to room chat interface
      window.location.reload(); // Will show room interface

    } catch (error) {
      console.error('Join room error:', error);
      alert('Failed to join room. Check the room ID and try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-green-50 via-white to-green-50">
      
      {/* Hero Section */}
      <div className="relative min-h-screen flex items-center justify-center px-4">
        <div className="max-w-4xl mx-auto text-center">
          
          {/* Logo */}
          <div className="mb-12">
            <img 
              src="/logo.webp" 
              alt="Mugharred" 
              className="mx-auto w-20 h-20 rounded-2xl shadow-lg"
            />
          </div>

          {/* Main Headline */}
          <h1 className="text-4xl md:text-6xl font-bold text-gray-900 mb-6">
            Create an instant room
          </h1>

          <p className="text-xl md:text-2xl text-gray-600 mb-4">
            No signup. No downloads. Just a link.
          </p>

          <p className="text-lg text-gray-500 mb-12 max-w-2xl mx-auto">
            Perfect for trip planning, job interviews, team standup, study groups, 
            project kickoffs, or casual conversations.
          </p>

          {/* Action Buttons */}
          <div className="flex flex-col sm:flex-row gap-4 justify-center items-center mb-8">
            <button
              onClick={() => setShowCreateRoom(true)}
              className="w-full sm:w-auto px-8 py-4 bg-gradient-to-r from-green-600 to-green-700 text-white text-lg font-semibold rounded-xl hover:from-green-700 hover:to-green-800 transform hover:scale-105 transition-all duration-200 shadow-lg"
            >
              Create Room
            </button>
            
            <button
              onClick={() => setShowJoinRoom(true)}
              className="w-full sm:w-auto px-8 py-4 border-2 border-green-600 text-green-600 text-lg font-semibold rounded-xl hover:bg-green-50 transform hover:scale-105 transition-all duration-200"
            >
              Join Room
            </button>
          </div>

          {/* Features */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8 mt-16">
            <div className="bg-white/60 backdrop-blur-sm rounded-xl p-6 border border-white/20 shadow-sm">
              <h3 className="font-semibold text-gray-900 mb-2">Instant & Temporary</h3>
              <p className="text-gray-600 text-sm">Rooms expire automatically. No permanent data stored.</p>
            </div>
            
            <div className="bg-white/60 backdrop-blur-sm rounded-xl p-6 border border-white/20 shadow-sm">
              <h3 className="font-semibold text-gray-900 mb-2">Share a Link</h3>
              <p className="text-gray-600 text-sm">Send the room link to anyone. They join instantly.</p>
            </div>
            
            <div className="bg-white/60 backdrop-blur-sm rounded-xl p-6 border border-white/20 shadow-sm">
              <h3 className="font-semibold text-gray-900 mb-2">Host Controls</h3>
              <p className="text-gray-600 text-sm">Lock rooms, manage participants, extend time.</p>
            </div>
          </div>
        </div>
      </div>

      {/* Modals */}
      {showCreateRoom && (
        <CreateRoomForm
          onCreateRoom={handleCreateRoom}
          onCancel={() => setShowCreateRoom(false)}
          loading={loading}
        />
      )}

      {showJoinRoom && (
        <JoinRoomForm
          onJoinRoom={handleJoinRoom}
          onCancel={() => setShowJoinRoom(false)}
          loading={loading}
          initialRoomId={window.location.pathname.match(/^\/r\/([a-z0-9-]+)$/)?.[1] || ''}
        />
      )}

      {/* Footer */}
      <footer className="mt-16 pt-8 border-t border-gray-200 text-center px-4">
        <div className="max-w-4xl mx-auto">
          <p className="text-gray-500 text-sm mb-4">
            Built with privacy in mind. Powered by{' '}
            <a href="https://benbo.se" className="text-green-600 hover:underline">
              benbo.se
            </a>
          </p>
          
          <div className="flex flex-wrap justify-center gap-4 text-sm text-gray-400 mb-4">
            <button className="hover:text-gray-600">Privacy</button>
            <button className="hover:text-gray-600">Terms</button>
            <button className="hover:text-gray-600">About</button>
          </div>
        </div>
      </footer>
    </div>
  );
}
EOF

echo "✅ Frontend room UI created!"
echo ""
echo "🎯 NEW FEATURES ADDED:"
echo "   - Room creation modal with name, participants (2-12), duration (15/30/60/120 min)"
echo "   - Room join modal with room ID and display name"
echo "   - URL detection for /r/room-id automatic join flow"
echo "   - Modern glassmorphism design matching existing style"
echo "   - Form validation and loading states"
echo ""
echo "⚠️  NEXT: Need to update routing and room chat interface"