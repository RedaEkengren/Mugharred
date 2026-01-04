#!/bin/bash
set -e

echo "🎨 DEPLOYING FAVICON & META TAG UPDATE"

# Ensure we're in the right directory
cd /home/reda/development/mugharred/frontend

# Build frontend with new favicon and meta tags
echo "📦 Building frontend..."
npm run build

# Deploy to production
echo "🚀 Deploying to production..."
sudo cp -r dist/* /var/www/html/

# Verify deployment
echo "✅ Verifying deployment..."
ls -la /var/www/html/favicon.ico
curl -s -I https://mugharred.se/favicon.ico | head -1

echo "🎉 FAVICON & META TAG UPDATE COMPLETE!"
echo "✅ New Mugharred logo favicon deployed"
echo "✅ OpenGraph tags for social sharing added"
echo "✅ Apple touch icon configured" 
echo "📱 Live at: https://mugharred.se"