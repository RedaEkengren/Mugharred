#!/bin/bash
# Rollback to session-based architecture if needed
# Safety script for reverting stateless changes

set -e

echo "🔄 ROLLING BACK TO SESSION ARCHITECTURE"
echo "Reverting JWT + Redis changes..."

cd /home/reda/development/mugharred/backend

# Restore session-based server if backup exists
if [ -f "src/server-sessions-backup.ts" ]; then
    cp src/server-sessions-backup.ts src/server.ts
    echo "✅ Restored session-based server"
    
    # Rebuild and restart
    npm run build
    pm2 restart mugharred-backend
    echo "✅ Backend reverted to session architecture"
else
    echo "❌ No session backup found - manual restore required"
fi

echo "🔄 Rollback complete - Session architecture restored"
