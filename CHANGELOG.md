# Changelog

## [1.0.0] - 2024-12-27 🚀

### Phase 1 MVP Complete - Production Ready!

**Major Features Added:**
- ✅ Complete JWT + Redis stateless architecture
- ✅ Instant room creation with auto-generated IDs (`/r/cool-sun-1234`)
- ✅ Real-time bidirectional WebSocket chat
- ✅ Share room links (copy/share buttons)
- ✅ Online users display with participant names
- ✅ Auto-expiring rooms (15/30/60/120 minutes)
- ✅ Mobile-responsive design optimized for all screen sizes
- ✅ Enterprise-grade security with input sanitization

**Bug Fixes:**
- Fixed Redis Map/Object data structure conflicts
- Fixed WebSocket room joining for both host and participants
- Fixed asymmetric message broadcasting
- Fixed virtual scrolling hiding messages
- Fixed participant names showing as empty strings
- Fixed backend port configuration (3010)

**Mobile Optimizations:**
- Responsive chat layout with proper height scaling
- Compact header with smart text hiding on mobile
- Horizontal scrolling online users bar on mobile
- Touch-friendly input controls
- Optimized spacing and typography for mobile screens

**Technical Improvements:**
- Stateless WebSocket service with JWT authentication
- Redis persistence with automatic TTL management
- Comprehensive error handling and validation
- Real-time participant tracking and broadcasting
- DOMPurify XSS protection
- Rate limiting and security headers

**What Works:**
1. Create room → Get shareable link
2. Share link → Others join instantly
3. Real-time chat between all participants
4. See who's online with names
5. Rooms auto-expire and cleanup
6. Works perfectly on mobile and desktop

**Ready for Phase 2:** WebRTC voice/video calling

---

*Built with Node.js + Express + JWT + Redis + WebSocket + React + TypeScript*