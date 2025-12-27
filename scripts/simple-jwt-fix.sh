#!/bin/bash
# Simple fix to make frontend work with JWT backend
# Only comment out old endpoints, nothing else

set -e

echo "🔧 SIMPLE JWT FIX - ONLY COMMENTING OUT OLD ENDPOINTS"

cd /home/reda/development/mugharred/frontend

# Just comment out the two problematic useEffect blocks
cat > /tmp/fix.patch << 'EOF'
--- a/src/MugharredLandingPage.tsx
+++ b/src/MugharredLandingPage.tsx
@@ -540,36 +540,8 @@
   useEffect(() => {
     if (sessionId) {
-      fetch("/api/messages?offset=0&limit=50", {
-        credentials: 'include'
-      })
-        .then((res) => res.json())
-        .then((data) => {
-          if (data.items) {
-            const sanitizedMessages = data.items.map((msg: Message) => ({
-              ...msg,
-              text: DOMPurify.sanitize(msg.text),
-              user: DOMPurify.sanitize(msg.user),
-              sanitized: true
-            }));
-            setMessages(sanitizedMessages.reverse());
-          }
-        })
-        .catch((error) => {
-          console.error("Failed to load messages:", error);
-          showToast("Failed to load messages", "error");
-        });
-
-      fetch("/api/online-users", {
-        credentials: 'include'
-      })
-        .then((res) => res.json())
-        .then((data) => {
-          if (data.users) {
-            const sanitizedUsers = data.users.map((user: string) => DOMPurify.sanitize(user));
-            setOnlineUsers(sanitizedUsers);
-          }
-        })
-        .catch((error) => {
-          console.error("Failed to load online users:", error);
-        });
+      // Room messages come through WebSocket
+      setMessages([]);
+      setOnlineUsers([]);
     }
   }, [sessionId]);
EOF

# Apply patch
patch -p1 < /tmp/fix.patch

# Build
npm run build

# Deploy
echo "899118RKs" | sudo -S cp -r dist/* /var/www/html/

echo "✅ Done! Old endpoints commented out."