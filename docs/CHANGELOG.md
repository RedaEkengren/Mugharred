# Changelog

All notable changes to the Mugharred project will be documented in this file.

## [1.0.5] - 2025-12-27 (IN PROGRESS)
### Added - MVP Phase 1 Implementation
- **Room Management Foundation**: Complete room system architecture (room-types.ts, room-service.ts)
- **Room Features**: Auto-generated room IDs (quiet-sun-5821 format), 15/30/60/120 min duration, 2-12 participants
- **Host Controls**: Room locking, participant kicking, room management
- **Auto-Expiry**: Rooms automatically destroyed when expired or empty
- **Room Isolation**: Room-specific messaging and participant management

### In Progress
- **Room API Endpoints**: 9 new endpoints for room creation, joining, management
- **Frontend Room UI**: Room creation wizard, join flow, room routing (/r/room-id)
- **WebSocket Room Support**: Room-specific message broadcasting

## [1.0.4] - 2025-12-27
### Added
- **Global English Interface**: Complete translation from Swedish to English for worldwide usage
- **Legal Pages as React Modals**: Privacy Policy, Terms of Service, and About pages now open as modals
- **Combined Hero+CTA Section**: Streamlined landing page with form directly in hero for better conversion
- **Footer Enhancement**: Professional footer with proper legal links and benbo.se connection

### Changed  
- **Rotating Hero Text**: "Create a room for [Trip planning | Job interviews | etc.]" with 10 use cases
- **Footer Links**: Changed from broken external links to working React modal triggers
- **Landing Page Copy**: Updated all text for global audience and instant rooms positioning

### Fixed
- **Golden Rules Compliance**: Removed unauthorized HTML files, implemented proper React component structure
- **Modal System**: Legal pages now work correctly as in-app modals instead of separate HTML files

### Removed
- **GitHub Link**: Removed from footer as unnecessary for end users
- **Swedish Text**: Replaced with English throughout the application

## [1.0.3] - 2025-12-27  
### Infrastructure
- ✅ Backend running on port 3010
- ✅ Enterprise security fully implemented  
- ✅ Visual identity complete

## [1.0.2] - 2025-12-13
### Added
- WebP logo implementation with rounded corners
- Favicon creation and deployment
- Modern glassmorphism design with hover effects
- Cross-platform visual consistency

### Fixed
- Critical WebSocket sessionId mismatch bug
- Mock-message blocking real backend integration
- Corrupted frontend assets elimination
- Nginx WebP MIME-type support

## [1.0.1] - 2025-12-12
### Added
- CSRF protection with SecureAPI class
- DOMPurify sanitization on all user input/output
- Redis sessions with HttpOnly cookies
- Toast notifications system
- Mobile-first design with safe areas
- Full keyboard navigation and accessibility

### Security
- Enterprise-grade security implementation
- Input sanitization to prevent XSS attacks
- Session security improvements
- Rate limiting enhancements

## [1.0.0] - 2025-12-12
### Initial Release
- ✅ Live chat functionality
- ✅ WebSocket real-time communication
- ✅ Virtual scroll with native scrollbar
- ✅ Message modal for full text
- ✅ Online users list (max 5)
- ✅ Auto-logout after 5 minutes inactivity
- ✅ Responsive design for mobile
- ✅ SSL/HTTPS deployment
- ✅ PM2 process management
- ✅ Nginx reverse proxy configuration

### Technical Implementation
- React + TypeScript + Tailwind frontend
- Node.js + Express + WebSocket backend
- Redis session store
- PM2 + systemd monitoring
- Let's Encrypt SSL certificates

### Deployment
- Live at https://mugharred.se
- Backend uptime > 99%
- Message delivery latency < 200ms
- Zero data loss during normal operation