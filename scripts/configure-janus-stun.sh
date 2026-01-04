#!/bin/bash
# Script to configure STUN server in Janus for ICE connectivity
# Following goldenrules.md principles

set -e

echo "🔧 Configuring STUN server for Janus Gateway"

# Backup current config
echo "📋 Creating backup of current config..."
sudo cp /usr/local/etc/janus/janus.jcfg /usr/local/etc/janus/janus.jcfg.backup.$(date +%Y%m%d_%H%M%S)

# Update STUN configuration
echo "✏️  Enabling STUN server (Google's public STUN)..."
sudo sed -i 's/#stun_server = "stun.voip.eutelia.it"/stun_server = "stun.l.google.com"/' /usr/local/etc/janus/janus.jcfg
sudo sed -i 's/#stun_port = 3478/stun_port = 19302/' /usr/local/etc/janus/janus.jcfg

# Also enable ICE consent freshness for better connection detection
echo "✏️  Enabling ICE consent freshness..."
sudo sed -i 's/#ice_consent_freshness = true/ice_consent_freshness = true/' /usr/local/etc/janus/janus.jcfg

# Show the changes
echo "📄 Configuration changes:"
grep -E "stun_server|stun_port|ice_consent_freshness" /usr/local/etc/janus/janus.jcfg | grep -v "#"

# Restart Janus
echo "🔄 Restarting Janus Gateway..."
pm2 restart mugharred-janus

echo "✅ STUN configuration complete!"
echo "🔍 Check Janus logs: pm2 logs mugharred-janus"