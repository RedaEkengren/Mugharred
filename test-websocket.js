#!/usr/bin/env node
import WebSocket from 'ws';

// Test WebSocket connection and messaging
async function testWebSocket() {
  console.log('🧪 Testing Mugharred WebSocket...\n');

  // First, login to get a session
  console.log('1. 👤 Logging in...');
  const loginResponse = await fetch('https://mugharred.se/api/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ name: 'TestBot' })
  });
  
  const { sessionId, name } = await loginResponse.json();
  console.log(`   ✅ Logged in as "${name}" with session: ${sessionId.substring(0, 8)}...`);

  // Connect WebSocket
  console.log('\n2. 🔌 Connecting WebSocket...');
  const ws = new WebSocket(`wss://mugharred.se/ws?sessionId=${sessionId}`);

  return new Promise((resolve) => {
    ws.on('open', () => {
      console.log('   ✅ WebSocket connected!');
      
      // Test sending a message
      console.log('\n3. 📤 Sending test message...');
      const testMessage = `Hej från test bot! Tid: ${new Date().toLocaleTimeString()}`;
      ws.send(JSON.stringify({
        type: 'send_message',
        text: testMessage
      }));
      console.log(`   📝 Sent: "${testMessage}"`);
    });

    ws.on('message', (data) => {
      const message = JSON.parse(data.toString());
      console.log('\n4. 📥 Received message:');
      
      if (message.type === 'message') {
        console.log(`   👤 ${message.message.user}: ${message.message.text}`);
        console.log(`   🕐 ${new Date(message.message.timestamp).toLocaleString()}`);
      } else if (message.type === 'online_users') {
        console.log(`   👥 Online users: ${message.users.join(', ')}`);
      } else if (message.type === 'error') {
        console.log(`   ❌ Error: ${message.error}`);
      }
    });

    ws.on('error', (error) => {
      console.log(`   ❌ WebSocket error: ${error.message}`);
      resolve(false);
    });

    // Close after 3 seconds
    setTimeout(() => {
      console.log('\n5. 🔚 Closing connection...');
      ws.close();
      console.log('   ✅ Test completed!\n');
      resolve(true);
    }, 3000);
  });
}

// Run test
testWebSocket().catch(console.error);