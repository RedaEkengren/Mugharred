# Mugharred Technical Implementation

Technical details for the Mugharred instant rooms platform.

## Current Implementation (MVP Phase 1 - KRITISK STATUS)

**🚨 ENDAST 10% AV PHASE 1 KLART - KREDIT-SLÖSERI**:
- ✅ **Room Creation Modal**: Finns på landing page
- ❌ **Room API Endpoints**: Saknas helt - backend kan ej skapa rum  
- ❌ **Join Room Flow**: Saknas - ingen kan gå med i rum
- ❌ **Room Timer**: Saknas - ingen countdown synlig
- ❌ **Host Controls**: Saknas - kan ej kicka/låsa rum
- ❌ **Room Chat**: Saknas - bara global chat finns
- ❌ **Auto-expire**: Saknas - rum försvinner ej

### Room System Architecture (NEW)
```typescript
// Room Management Foundation (IMPLEMENTED)
interface Room {
  id: string;           // "quiet-sun-5821" format per MVP.md
  name: string;         // User-friendly room name
  hostId: string;       // Creator sessionId  
  maxParticipants: number; // 2-12 per MVP.md
  duration: number;     // 15/30/60/120 min per MVP.md
  createdAt: number;    // timestamp
  expiresAt: number;    // auto-calculated
  participants: Map<string, Participant>;
  messages: RoomMessage[];
  isLocked: boolean;    // Host can lock room
}

// Room Service (IMPLEMENTED) 
class RoomService {
  createRoom(request: CreateRoomRequest, hostSessionId: string)
  joinRoom(request: JoinRoomRequest, sessionId: string) 
  leaveRoom(roomId: string, sessionId: string)
  addMessage(roomId: string, sessionId: string, text: string)
  lockRoom(roomId: string, hostSessionId: string)
  kickParticipant(roomId: string, hostSessionId: string, targetSessionId: string)
  // Auto-cleanup expired rooms every 60 seconds
}
```

### Current Chat System (Legacy - Being Replaced)
```typescript
// SecureAPI class for CSRF-protected requests
class SecureAPI {
  private static csrfToken: string = '';
  
  static async secureRequest(url: string, options: RequestInit = {}): Promise<Response> {
    const token = await this.getCsrfToken();
    return fetch(url, {
      ...options,
      credentials: 'include',
      headers: { 'X-CSRF-Token': token, ...options.headers }
    });
  }
}

// Main component with security and modern design
export default function MugharredLandingPage() {
  // Secure state management
  const [sessionId, setSessionId] = useState<string | null>()
  const [messages, setMessages] = useState<Message[]>([])
  const [toast, setToast] = useState<ToastType | null>(null)
  
  // Secure login with DOMPurify sanitization
  const handleSubmit = async (e: React.FormEvent) => {
    const sanitizedName = DOMPurify.sanitize(name.trim());
    const response = await SecureAPI.secureRequest('/api/login', {
      method: 'POST',
      body: JSON.stringify({ name: sanitizedName })
    });
  }
  
  // Secure WebSocket with input sanitization
  socket.onmessage = (event) => {
    const sanitizedMessage = {
      ...data.message,
      text: DOMPurify.sanitize(data.message.text),
      user: DOMPurify.sanitize(data.message.user)
    };
  }
}
```

### Secure Backend (Node.js + Express + WS)
```typescript
// Redis session store for security
const redisClient = createClient({ url: REDIS_URL })
app.use(session({
  store: new RedisStore({ client: redisClient }),
  secret: SESSION_SECRET,
  cookie: { httpOnly: true, secure: true, sameSite: 'strict' }
}))

// CSRF protection på alla POST endpoints
const { generateCsrfToken, doubleCsrfProtection } = doubleCsrf({
  getSecret: () => SESSION_SECRET,
  getSessionIdentifier: (req) => req.session?.id || ''
})

// Input sanitization med DOMPurify
function sanitizeInput(input: string): string {
  return DOMPurify.sanitize(input, { ALLOWED_TAGS: [] })
}

// Rate limiting med IP-baserad begränsning
const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, max: 100,
  message: "För många förfrågningar"
})
```

### Legal Page Modal System
```typescript
// Modal state management
const [activeModal, setActiveModal] = useState<'privacy' | 'terms' | 'about' | null>(null);

// Footer with modal triggers instead of broken HTML links
<footer className="mt-16 pt-8 border-t border-white/10 text-center">
  <div className="flex flex-wrap justify-center gap-4 text-sm text-white/60 mb-4">
    <button 
      onClick={() => setActiveModal('privacy')}
      className="hover:text-white transition-colors"
    >
      Privacy Policy
    </button>
    // Modal rendering with full legal content
    {activeModal && (
      <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center p-4 z-50">
        <div className="bg-white rounded-xl shadow-xl max-w-4xl w-full max-h-[80vh] overflow-hidden">
          // Full legal content rendered based on activeModal state
        </div>
      </div>
    )}
  </div>
</footer>
```

## Current Features

### 1. Säker Inloggning
- **Input**: Endast användarnamn (minst 2 tecken)
- **Validering**: Express-validator client-side och server-side
- **Session**: Redis-baserad session store med HttpOnly cookies
- **CSRF Protection**: Double submit cookie pattern
- **Rate Limiting**: 5 inloggningsförsök per 15 minuter per IP
- **Begränsning**: Max 5 användare samtidigt
- **Feedback**: Tydliga felmeddelanden på svenska

### 2. Live Feed
- **Realtid**: WebSocket för direkta uppdateringar  
- **Fallback**: HTTP polling som backup (ej implementerat ännu)
- **Virtualisering**: Endast 10 meddelanden renderade åt gången
- **Native scroll**: Använder webbläsarens inbyggda scrollbar
- **Uniform höjd**: Alla meddelanden har samma höjd (80px)

### 3. Message System
- **Skicka**: Enter eller klick på skicka-knapp
- **Längd**: Max 500 tecken per meddelande
- **Rate limiting**: Max 5 meddelanden per 10 sekunder
- **Trunkering**: Meddelanden visas trunkerade i listan
- **Fulltext modal**: Klicka för att se hela meddelandet

### 4. Online Users
- **Lista**: Visa alla online användare (max 5)
- **Status**: Grön indikator för online status
- **Realtid**: Uppdateras när användare går online/offline
- **Auto-cleanup**: Inaktiva användare rensas automatiskt efter 5 min

### 5. Modern Enterprise Design
- **Glassmorphism**: Genomskinliga kort med backdrop-blur effekter
- **Avancerade animationer**: Fade-in, slide-up, scale-in, hover-lift effekter
- **Mobile-first**: Safe areas, responsive breakpoints, touch targets
- **Toast notifications**: Professionella meddelanden med auto-timeout
- **Loading states**: Skeleton screens, spinners, success animations
- **Brand consistency**: Green/gold color scheme throughout
- **Legal Page Modals**: Privacy, Terms, About accessible via React modal system instead of separate HTML files
- **Accessibility**: Focus states, keyboard navigation, screen reader support

## Infrastructure

### Secure Infrastructure
- **Nginx**: Reverse proxy + static file serving
- **SSL**: Let's Encrypt automatiska certifikat  
- **Redis**: Session store och caching
- **Deployment**: PM2 process manager
- **Security**: Helmet.js security headers
- **Logging**: Winston security logging
- **Monitoring**: PM2 + systemd + säkerhetsloggar

## Security Model

### Säkerhetsmodell (Enterprise-Grade)
1. **Max 5 användare**: Håller nere serverbelastning
2. **In-memory storage**: Inga persistenta data = mindre risk
3. **Rate limiting**: Förhindrar spam och enkla attacker
4. **Kort meddelanden**: 500 tecken max
5. **Auto-logout**: Automatisk utloggning efter 5 minuters inaktivitet
6. **Ingen e-post**: Undviker persondata hantering

### Vad som INTE finns (medvetet)
- ❌ Lösenord eller autentisering
- ❌ Persistent storage/databas
- ❌ Användar profiler  
- ❌ Privata meddelanden
- ❌ Moderering/admin funktioner
- ❌ Fil uppladdning
- ❌ Push notiser

## Performance

### Svarstider
- **Login**: < 500ms
- **Skicka meddelande**: < 200ms  
- **Få nya meddelanden**: < 100ms (WebSocket)
- **Ladda äldre meddelanden**: < 300ms

### Skalning
- **Samtidiga användare**: 5 (hårdkodad begränsning)
- **Meddelanden per minut**: Max 150 (5 users × 5 msgs/10sec × 6)
- **Memory usage**: < 50MB för backend
- **CPU usage**: < 10% på moderna server

## Future Architecture (Instant Rooms)

### New Components Needed
- Room management service
- WebRTC signaling 
- Timer/expiry system
- Room state in Redis (temporary)

### Scaling Strategy
- Start with P2P WebRTC (light on server)
- Add SFU later if needed (LiveKit/mediasoup)
- Keep text chat as primary (low bandwidth)
- Video as optional enhancement

### P2P WebRTC (Recommended Start)
- Server load: Minimal (just signaling)
- User bandwidth: Each sends to all others
- Works well: 2-4 people
- Falls apart: 5+ people