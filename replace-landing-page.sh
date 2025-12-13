#!/bin/bash
set -e

# Färgkoder
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}🔄 Replace Landing Page Script${NC}"
echo "====================================="

# Kontrollera att vi är i rätt katalog
if [ ! -f "frontend/src/MugharredLandingPage.tsx" ]; then
    echo -e "${RED}❌ FEL: frontend/src/MugharredLandingPage.tsx hittades inte${NC}"
    exit 1
fi

# Backup original
echo -e "${YELLOW}📋 Skapar backup...${NC}"
cp frontend/src/MugharredLandingPage.tsx frontend/src/MugharredLandingPage.tsx.backup

# Extrahera de tre sektionerna
echo -e "${YELLOW}✂️ Extraherar koda sektioner...${NC}"

# Sektion 1: Imports och logik (rad 1-383)
sed -n '1,383p' frontend/src/MugharredLandingPage.tsx > /tmp/section1.tsx

# Sektion 3: Chat interface (rad 522-slutet)  
sed -n '522,$p' frontend/src/MugharredLandingPage.tsx > /tmp/section3.tsx

# Skapa ny landing page sektion (sektion 2)
cat > /tmp/section2.tsx << 'EOF'
  if (!sessionId) {
    return (
      <div className="min-h-screen bg-[radial-gradient(1200px_circle_at_20%_10%,rgba(0,108,58,0.18),transparent_55%),radial-gradient(900px_circle_at_85%_30%,rgba(212,175,55,0.18),transparent_55%),linear-gradient(to_bottom,rgba(255,255,255,0.8),rgba(255,255,255,0.55))] text-neutral-900">
        {toast && (
          <Toast 
            message={toast.message} 
            type={toast.type} 
            onClose={() => setToast(null)} 
          />
        )}
        
        {/* Top bar */}
        <header className="mx-auto flex max-w-6xl items-center justify-between px-4 py-5">
          <div className="flex items-center gap-3">
            <div className="grid h-10 w-10 place-items-center rounded-2xl bg-[#006C3A] text-white shadow-[0_10px_30px_rgba(0,0,0,0.10)]">
              <span className="text-lg font-semibold">M</span>
            </div>
            <div className="leading-tight">
              <div className="text-base font-semibold tracking-tight">Mugharred</div>
              <div className="text-xs text-neutral-600">Live feed • Minimal login</div>
            </div>
          </div>

          <nav className="hidden items-center gap-6 text-sm text-neutral-700 md:flex">
            <a href="#features" className="hover:text-neutral-950">Funktioner</a>
            <a href="#how" className="hover:text-neutral-950">Hur det funkar</a>
            <a href="#security" className="hover:text-neutral-950">Säkerhet</a>
          </nav>

          <a
            href="#join"
            className="inline-flex items-center gap-2 rounded-xl bg-[#006C3A] px-4 py-2 text-sm font-medium text-white shadow-[0_12px_35px_rgba(0,0,0,0.12)] hover:bg-emerald-800 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#D4AF37] focus-visible:ring-offset-2"
          >
            Gå med <ArrowRight className="h-4 w-4" />
          </a>
        </header>

        {/* Hero */}
        <main className="mx-auto max-w-6xl px-4">
          <section className="grid items-center gap-10 py-10 md:grid-cols-2 md:py-16">
            <div className="space-y-6">
              <div className="inline-flex items-center gap-2 rounded-full border border-black/10 bg-white/70 px-3 py-1 text-xs text-neutral-700 backdrop-blur">
                <Zap className="h-3.5 w-3.5" />
                Ett flöde för alla – i realtid
              </div>

              <h1 className="text-4xl font-semibold tracking-tight md:text-5xl">
                Mugharred
                <span className="block text-neutral-600">en enkel social feed som uppdateras live.</span>
              </h1>

              <p className="max-w-xl text-base text-neutral-700">
                Skriv ditt namn och hoppa rakt in. Alla meddelanden syns i ett gemensamt flöde med native scroll och smart virtualisering.
                Klicka på ett inlägg för att läsa hela texten i en modal.
              </p>

              <div className="flex flex-wrap gap-3">
                <a
                  href="#join"
                  className="inline-flex items-center justify-center rounded-xl bg-[#006C3A] px-5 py-2.5 text-sm font-medium text-white shadow-[0_12px_35px_rgba(0,0,0,0.12)] hover:bg-emerald-800 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#D4AF37] focus-visible:ring-offset-2"
                >
                  Starta nu <ArrowRight className="ml-2 h-4 w-4" />
                </a>
                <a
                  href="#features"
                  className="inline-flex items-center justify-center rounded-xl border border-black/10 bg-white/70 px-5 py-2.5 text-sm font-medium text-neutral-900 backdrop-blur hover:bg-white"
                >
                  Se funktioner
                </a>
              </div>

              <div className="flex flex-wrap items-center gap-x-6 gap-y-2 text-xs text-neutral-600">
                <span className="inline-flex items-center gap-2"><Users className="h-4 w-4" />Max 5 online samtidigt</span>
                <span className="inline-flex items-center gap-2"><Shield className="h-4 w-4" />Enkel rate limiting</span>
                <span className="inline-flex items-center gap-2"><Globe2 className="h-4 w-4" />Live via WebSocket</span>
              </div>
            </div>

            {/* Preview card */}
            <div className="relative">
              <div className="absolute -inset-4 -z-10 rounded-[2rem] bg-gradient-to-tr from-[#006C3A]/20 via-transparent to-[#D4AF37]/20 blur-2xl" />
              <div className="rounded-[1.75rem] border border-black/10 bg-white/70 p-5 shadow-[0_20px_60px_rgba(0,0,0,0.10)] backdrop-blur">
                <div className="mb-4 flex items-center justify-between">
                  <div className="text-sm font-semibold">Live feed</div>
                  <div className="text-xs text-neutral-600">Native scroll • 10 i taget</div>
                </div>

                <div className="space-y-3">
                  {[
                    { user: "Noura", time: "1m", text: "Kul att se att allt uppdateras direkt. Minimalistiskt och snabbt." },
                    { user: "Fahad", time: "3m", text: "En sida, en feed. Inga distraktioner. Perfekt för snabba uppdateringar." },
                    { user: "Sara", time: "7m", text: "Gillar att texten öppnas i en modal istället för att ändra höjden." },
                  ].map((p, idx) => (
                    <div key={idx} className="rounded-2xl border border-black/5 bg-white p-4 shadow-[0_10px_25px_rgba(0,0,0,0.06)]">
                      <div className="mb-1 flex items-center justify-between text-xs text-neutral-600">
                        <span className="font-medium text-neutral-900">{p.user}</span>
                        <span>{p.time}</span>
                      </div>
                      <div className="text-sm text-neutral-800">
                        <span className="block truncate">{p.text}</span>
                        <span className="mt-2 inline-flex items-center gap-1 text-xs text-[#006C3A]">Läs mer <ArrowRight className="h-3.5 w-3.5" /></span>
                      </div>
                    </div>
                  ))}
                </div>

                <div className="mt-4 rounded-2xl border border-black/5 bg-white p-3">
                  <div className="flex items-center gap-2">
                    <div className="h-9 w-9 rounded-xl bg-[#006C3A]/10" />
                    <div className="h-9 flex-1 rounded-xl bg-neutral-100" />
                    <div className="h-9 w-20 rounded-xl bg-[#006C3A]" />
                  </div>
                  <div className="mt-2 text-xs text-neutral-600">Skriv → Skicka → Visas direkt</div>
                </div>
              </div>
            </div>
          </section>

          {/* Features */}
          <section id="features" className="py-10 md:py-14">
            <div className="mb-8 flex items-end justify-between gap-6">
              <div>
                <h2 className="text-2xl font-semibold tracking-tight">Funktioner</h2>
                <p className="mt-2 max-w-2xl text-sm text-neutral-700">
                  Mugharred är byggd för enkelhet. En sida, en feed, och en stabil upplevelse med native scrollbar.
                </p>
              </div>
            </div>

            <div className="grid gap-4 md:grid-cols-3">
              <div className="rounded-[1.5rem] border border-black/10 bg-white/70 p-5 shadow-[0_14px_40px_rgba(0,0,0,0.08)] backdrop-blur">
                <div className="flex items-center gap-3">
                  <div className="grid h-10 w-10 place-items-center rounded-2xl bg-[#006C3A]/10 text-[#006C3A]">
                    <Globe2 className="h-5 w-5" />
                  </div>
                  <div className="text-sm font-semibold">Live feed</div>
                </div>
                <div className="mt-2 text-sm text-neutral-700">Uppdateras via WebSockets eller polling. Nya inlägg dyker upp direkt.</div>
              </div>
              <div className="rounded-[1.5rem] border border-black/10 bg-white/70 p-5 shadow-[0_14px_40px_rgba(0,0,0,0.08)] backdrop-blur">
                <div className="flex items-center gap-3">
                  <div className="grid h-10 w-10 place-items-center rounded-2xl bg-[#006C3A]/10 text-[#006C3A]">
                    <Users className="h-5 w-5" />
                  </div>
                  <div className="text-sm font-semibold">Online-lista</div>
                </div>
                <div className="mt-2 text-sm text-neutral-700">Visar vilka som är online just nu. Max fem användare samtidigt.</div>
              </div>
              <div className="rounded-[1.5rem] border border-black/10 bg-white/70 p-5 shadow-[0_14px_40px_rgba(0,0,0,0.08)] backdrop-blur">
                <div className="flex items-center gap-3">
                  <div className="grid h-10 w-10 place-items-center rounded-2xl bg-[#006C3A]/10 text-[#006C3A]">
                    <Zap className="h-5 w-5" />
                  </div>
                  <div className="text-sm font-semibold">Virtual scroll</div>
                </div>
                <div className="mt-2 text-sm text-neutral-700">Renderar 10 rader åt gången med fast radhöjd och native scrollbar.</div>
              </div>
            </div>

            <div className="mt-4 grid gap-4 md:grid-cols-3">
              <div className="rounded-[1.5rem] border border-black/10 bg-white/70 p-5 shadow-[0_14px_40px_rgba(0,0,0,0.08)] backdrop-blur">
                <div className="flex items-center gap-3">
                  <div className="grid h-10 w-10 place-items-center rounded-2xl bg-[#006C3A]/10 text-[#006C3A]">
                    <Shield className="h-5 w-5" />
                  </div>
                  <div className="text-sm font-semibold">Rate limiting</div>
                </div>
                <div className="mt-2 text-sm text-neutral-700">Enkel begränsning av inlägg för att minska spam och attacker.</div>
              </div>
              <div className="rounded-[1.5rem] border border-black/10 bg-white/70 p-5 shadow-[0_14px_40px_rgba(0,0,0,0.08)] backdrop-blur">
                <div className="flex items-center gap-3">
                  <div className="grid h-10 w-10 place-items-center rounded-2xl bg-[#006C3A]/10 text-[#006C3A]">
                    <Globe2 className="h-5 w-5" />
                  </div>
                  <div className="text-sm font-semibold">En sida</div>
                </div>
                <div className="mt-2 text-sm text-neutral-700">Ingen navigation behövs. Allt sker på samma vy.</div>
              </div>
              <div className="rounded-[1.5rem] border border-black/10 bg-white/70 p-5 shadow-[0_14px_40px_rgba(0,0,0,0.08)] backdrop-blur">
                <div className="flex items-center gap-3">
                  <div className="grid h-10 w-10 place-items-center rounded-2xl bg-[#006C3A]/10 text-[#006C3A]">
                    <ArrowRight className="h-5 w-5" />
                  </div>
                  <div className="text-sm font-semibold">Modal för fulltext</div>
                </div>
                <div className="mt-2 text-sm text-neutral-700">Klicka på ett inlägg för att läsa hela texten utan att ändra radhöjd.</div>
              </div>
            </div>
          </section>

          {/* How it works */}
          <section id="how" className="py-10 md:py-14">
            <div className="grid gap-6 md:grid-cols-2">
              <div className="rounded-[1.75rem] border border-black/10 bg-white/70 p-6 shadow-[0_20px_60px_rgba(0,0,0,0.08)] backdrop-blur">
                <h3 className="text-lg font-semibold">Hur det funkar</h3>
                <ol className="mt-4 space-y-3 text-sm text-neutral-700">
                  <li className="flex gap-3"><span className="mt-0.5 inline-flex h-6 w-6 items-center justify-center rounded-xl bg-[#006C3A] text-xs font-semibold text-white">1</span> Skriv ditt namn och gå med direkt.</li>
                  <li className="flex gap-3"><span className="mt-0.5 inline-flex h-6 w-6 items-center justify-center rounded-xl bg-[#006C3A] text-xs font-semibold text-white">2</span> Se live-flödet och vilka som är online.</li>
                  <li className="flex gap-3"><span className="mt-0.5 inline-flex h-6 w-6 items-center justify-center rounded-xl bg-[#006C3A] text-xs font-semibold text-white">3</span> Skicka meddelanden – de syns direkt i flödet.</li>
                  <li className="flex gap-3"><span className="mt-0.5 inline-flex h-6 w-6 items-center justify-center rounded-xl bg-[#006C3A] text-xs font-semibold text-white">4</span> Scrolla bakåt med virtualisering (10 i taget).</li>
                </ol>
              </div>

              <div id="security" className="rounded-[1.75rem] border border-black/10 bg-white/70 p-6 shadow-[0_20px_60px_rgba(0,0,0,0.08)] backdrop-blur">
                <h3 className="text-lg font-semibold">Säkerhet (enkel modell)</h3>
                <p className="mt-3 text-sm text-neutral-700">
                  Mugharred använder medvetet en minimalistisk inloggning. För att begränsa risker:
                </p>
                <ul className="mt-4 space-y-2 text-sm text-neutral-700">
                  <li className="flex gap-2"><span className="mt-1 h-1.5 w-1.5 rounded-full bg-[#D4AF37]" />Max fem användare online samtidigt.</li>
                  <li className="flex gap-2"><span className="mt-1 h-1.5 w-1.5 rounded-full bg-[#D4AF37]" />Rate limiting för att minska spam/attacker.</li>
                  <li className="flex gap-2"><span className="mt-1 h-1.5 w-1.5 rounded-full bg-[#D4AF37]" />Inlägg trunceras i listan och fulltext visas i modal.</li>
                </ul>
                <div className="mt-5 rounded-2xl border border-black/5 bg-white p-4">
                  <div className="text-xs font-medium text-neutral-900">Rekommendation (nästa steg)</div>
                  <div className="mt-1 text-xs text-neutral-600">
                    Vill ni stärka säkerheten senare kan vi lägga till e-postverifiering, riktig session-hantering och bättre skydd.
                  </div>
                </div>
              </div>
            </div>
          </section>

          {/* Join */}
          <section id="join" className="py-12 md:py-16">
            <div className="rounded-[2rem] border border-black/10 bg-white/70 p-6 shadow-[0_20px_60px_rgba(0,0,0,0.10)] backdrop-blur md:p-10">
              <div className="grid items-center gap-8 md:grid-cols-2">
                <div>
                  <h2 className="text-2xl font-semibold tracking-tight">Gå med i Mugharred</h2>
                  <p className="mt-2 text-sm text-neutral-700">
                    Skriv ditt namn för att ansluta. Om det redan finns fem användare online kommer du få vänta.
                  </p>

                  <div className="mt-5 flex flex-wrap items-center gap-3 text-xs text-neutral-600">
                    <span className="inline-flex items-center gap-2"><Users className="h-4 w-4" />Max 5 online</span>
                    <span className="inline-flex items-center gap-2"><Shield className="h-4 w-4" />Rate limiting</span>
                    <span className="inline-flex items-center gap-2"><Globe2 className="h-4 w-4" />Live uppdatering</span>
                  </div>
                </div>

                <form onSubmit={handleLogin} className="rounded-2xl border border-black/10 bg-white p-5 shadow-[0_10px_25px_rgba(0,0,0,0.06)]">
                  <label className="text-sm font-medium">Ditt namn</label>
                  <input
                    type="text"
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    placeholder="Skriv ditt namn..."
                    className="mt-2 w-full rounded-xl border border-black/10 bg-white px-3 py-2 text-sm outline-none transition focus:border-[#006C3A] focus:ring-2 focus:ring-[#006C3A]/30"
                    required
                    minLength={2}
                    maxLength={50}
                    disabled={loginLoading}
                  />
                  {loginError && (
                    <div className="mt-2 text-xs text-red-700">{loginError}</div>
                  )}

                  <button
                    type="submit"
                    disabled={loginLoading || !name.trim()}
                    className="mt-4 inline-flex w-full items-center justify-center gap-2 rounded-xl bg-[#006C3A] px-4 py-2.5 text-sm font-medium text-white shadow-[0_12px_35px_rgba(0,0,0,0.12)] hover:bg-emerald-800 disabled:cursor-not-allowed disabled:bg-emerald-900/50"
                  >
                    {loginLoading ? (
                      <>
                        <Loader2 className="animate-spin" size={20} />
                        Ansluter...
                      </>
                    ) : (
                      <>
                        Anslut <ArrowRight className="h-4 w-4" />
                      </>
                    )}
                  </button>

                  <div className="mt-3 text-xs text-neutral-600">
                    Genom att ansluta godkänner du att detta är en minimalistisk demo med enkel inloggning.
                  </div>
                </form>
              </div>
            </div>
          </section>

          {/* Footer */}
          <footer className="pb-10 pt-6 text-xs text-neutral-600">
            <div className="flex flex-col items-start justify-between gap-3 border-t border-black/10 pt-6 md:flex-row md:items-center">
              <div className="inline-flex items-center gap-2">
                <div className="h-8 w-8 rounded-2xl bg-[#006C3A] text-white grid place-items-center">M</div>
                <span>© {new Date().getFullYear()} Mugharred</span>
              </div>
              <div className="flex gap-4">
                <a className="hover:text-neutral-950" href="#features">Funktioner</a>
                <a className="hover:text-neutral-950" href="#how">Hur det funkar</a>
                <a className="hover:text-neutral-950" href="#join">Gå med</a>
              </div>
            </div>
          </footer>
        </main>
      </div>
    );
  }
EOF

# Sätt ihop nya filen
echo -e "${YELLOW}🔧 Sätter ihop ny komponent...${NC}"
cat /tmp/section1.tsx /tmp/section2.tsx /tmp/section3.tsx > frontend/src/MugharredLandingPage.tsx

# Rensa temp-filer
rm -f /tmp/section1.tsx /tmp/section2.tsx /tmp/section3.tsx

# Bygg och deploya
echo -e "${YELLOW}🚀 Bygger och deployar...${NC}"
./deploy-frontend.sh

echo -e "${GREEN}✅ Landing page uppdaterad!${NC}"
echo ""
echo "Backup finns på: frontend/src/MugharredLandingPage.tsx.backup"
echo "Testa: https://mugharred.se"
EOF