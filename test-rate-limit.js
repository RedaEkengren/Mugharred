#!/usr/bin/env node
import WebSocket from 'ws';

async function testRateLimit() {
  console.log('🧪 Testing Rate Limiting...\n');

  // Login
  const loginResponse = await fetch('https://mugharred.se/api/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ name: 'SpamBot' })
  });
  
  const { sessionId } = await loginResponse.json();
  console.log(`✅ Logged in as SpamBot`);

  const ws = new WebSocket(`wss://mugharred.se/ws?sessionId=${sessionId}`);

  ws.on('open', () => {
    console.log('✅ WebSocket connected\n');
    
    // Try to send 10 messages quickly (should hit rate limit)
    console.log('📤 Attempting to send 10 messages rapidly...');
    for (let i = 1; i <= 10; i++) {
      ws.send(JSON.stringify({
        type: 'send_message',
        text: `Spam message ${i}`
      }));
      console.log(`   Sent message ${i}`);
    }
  });

  ws.on('message', (data) => {
    const message = JSON.parse(data.toString());
    if (message.type === 'error') {
      console.log(`\n❌ Rate limit triggered: ${message.error}`);
    } else if (message.type === 'message') {
      console.log(`✅ Message accepted: "${message.message.text}"`);
    }
  });

  setTimeout(() => {
    ws.close();
    console.log('\n🔚 Rate limit test completed!');
  }, 2000);
}

testRateLimit().catch(console.error);