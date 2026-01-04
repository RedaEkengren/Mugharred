# NEXT CLAUDE TODO - PRE-LAUNCH FOCUS

## PRIORITET 1: VIDEO OPTIMIZATION 🎯
**MÅL**: Video ska fungera 100% innan offentlig lansering

### Video Issues att Fixa:
1. **Mute button state sync** - Ibland kräver flera klick
2. **Video orientation** - Kontrollera att remote/local videos är rätt orienterade  
3. **Mobile camera permissions** - Förbättra error handling och UX
4. **Speaker switching** - Testa thumbnail → main speaker transitions
5. **3-user limit** - Verifiera att 4+ users får audio-only automatiskt

## PRIORITET 2: FINAL TESTING 🧪
- **Multi-device testing** - Desktop + mobil samtidigt
- **Cross-browser** - Chrome, Safari, Firefox
- **Network stress** - Sämre anslutningar
- **Edge cases** - User leaves, network drops, etc.

## PRIORITET 3: POST-LAUNCH OBSERVERING 📊
**EFTER video är perfekt:**

1. **Lansera offentligt** 
2. **Observera användning**:
   - Vilka rum skapas?
   - När används voice/video?
   - Var finns smärtpunkter?
3. **Identifiera monetiseringsområden**:
   - När gör det ont att rummet försvinner?
   - Vad vill användare ha "lite mer" av?

## MONETISERING: AVVAKTA! ⏳
**INTE** implementera betalning förrän:
- Video fungerar 100%
- Användarfeedback samlat  
- Naturliga smärtpunkter identifierade

**Potential modeller** (för framtida referens):
- Pro rooms: 29-99kr per rum
- B2B light: 500-2000kr/mån  
- One-off: 49kr för 24h upgrade

## Status Update (2026-01-04)
### Completed Features ✅
- ✅ **Voice Chat** - Push-to-talk, mute/unmute, multi-speaker
- ✅ **Video Chat** - Camera toggle, speaker focus layout, 3-user limit
- ✅ **WhatsApp/Telegram UI** - Fullscreen overlays, minimizable calls
- ✅ **Legal Compliance** - GDPR/COPPA Privacy Policy & Terms modals
- ✅ **Mobile-First** - Responsive design, touch-friendly controls

### Infrastructure ✅
- ✅ **PM2 Services** - mugharred-backend + mugharred-janus online
- ✅ **Janus Gateway** - WebRTC with STUN, videoroom plugin
- ✅ **Security** - HTTPS, JWT, input sanitization, rate limiting