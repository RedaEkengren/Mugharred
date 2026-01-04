#!/bin/bash
# Script to remove old P2P WebRTC files
# Following goldenrules.md principles

set -e

echo "🧹 Removing old P2P WebRTC files"

# List files to be removed
echo "📋 Files to be removed:"
echo "  - frontend/src/useWebRTC.ts (OLD P2P hook)"
echo "  - backend/src/webrtc-signaling.ts (OLD P2P signaling)"

# Confirm removal
read -p "❓ Remove these files? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Remove old files
    echo "🗑️  Removing old P2P files..."
    rm -f /home/reda/development/mugharred/frontend/src/useWebRTC.ts
    rm -f /home/reda/development/mugharred/backend/src/webrtc-signaling.ts
    
    echo "✅ Old P2P files removed!"
    echo "📁 Current voice files:"
    ls -la /home/reda/development/mugharred/frontend/src/ | grep -E "(voice|Voice|janus|Janus)"
else
    echo "❌ Cancelled - no files removed"
fi