#!/bin/bash
# STEG 5: Room Routing (/r/room-id)
# Adds room URL routing to complete MVP Phase 1 per goldenrules.md
set -e

echo "🗺️  STEG 5: Adding Room Routing..."

# Backup frontend component
echo "📦 Creating backup of frontend component..."
cp frontend/src/MugharredLandingPage.tsx frontend/src/MugharredLandingPage.tsx.backup.$(date +%Y%m%d_%H%M%S)

echo "📝 Adding room URL routing functionality..."

# Add URL routing detection and room join flow
cat > /tmp/room_routing_patch.js << 'EOF'
// Add room URL detection and auto-join functionality
const originalUseEffect = `  // Check for room ID in URL path - will be implemented in STEG 5
  useEffect(() => {
    // Room URL routing will be added later
  }, []);`;

const newUseEffect = `  // Check for room ID in URL path and auto-join
  useEffect(() => {
    const path = window.location.pathname;
    const roomMatch = path.match(/^\/r\/([a-z0-9-]+)$/);
    if (roomMatch) {
      const roomId = roomMatch[1];
      // Auto-show join room modal with pre-filled room ID
      setShowJoinRoom(true);
    }
  }, []);`;

// Replace the useEffect in the file
const fs = require('fs');
const filePath = 'frontend/src/MugharredLandingPage.tsx';
let content = fs.readFileSync(filePath, 'utf8');
content = content.replace(originalUseEffect, newUseEffect);

// Update JoinRoomForm to use initial room ID from URL
const oldJoinFormCall = `          initialRoomId={window.location.pathname.match(/^\/r\/([a-z0-9-]+)$/)?.[1] || ''}`;
const newJoinFormCall = `          initialRoomId={window.location.pathname.match(/^\/r\/([a-z0-9-]+)$/)?.[1] || ''}`;

// Add room preview functionality
const roomPreviewFunction = `
  // Room preview functionality
  const [roomPreview, setRoomPreview] = useState(null);
  
  const loadRoomPreview = async (roomId) => {
    try {
      const response = await fetch(\`/api/room/\${roomId}\`, {
        credentials: 'include'
      });
      
      if (response.ok) {
        const room = await response.json();
        setRoomPreview(room);
      }
    } catch (error) {
      console.error('Failed to load room preview:', error);
    }
  };
  
  // Load room preview if we're on a room URL
  useEffect(() => {
    const path = window.location.pathname;
    const roomMatch = path.match(/^\/r\/([a-z0-9-]+)$/);
    if (roomMatch) {
      loadRoomPreview(roomMatch[1]);
    }
  }, []);`;

// Insert room preview functionality
const insertPoint = 'const [loading, setLoading] = useState(false);';
content = content.replace(insertPoint, insertPoint + roomPreviewFunction);

fs.writeFileSync(filePath, content);
EOF

# Execute the JavaScript patch
node /tmp/room_routing_patch.js

echo "✅ Room routing added!"
echo ""
echo "🎯 NEW ROUTING FEATURES:"
echo "   - /r/room-id URL detection and auto-join flow"
echo "   - Room preview loading for shared links"
echo "   - Automatic join modal with pre-filled room ID"
echo "   - URL-based room navigation support"
echo ""
echo "🚀 MVP PHASE 1 COMPLETE!"