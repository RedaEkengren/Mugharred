import React, { useMemo, useState, useEffect, useRef } from "react";
import { ArrowRight, Shield, Zap, Users, MessageSquareText, Globe2, Send, X } from "lucide-react";

type Message = {
  id: string;
  user: string;
  text: string;
  timestamp: number;
};

const ROW_HEIGHT = 80;
const PAGE_SIZE = 10;

export default function MugharredLandingPage() {
  // Login state
  const [sessionId, setSessionId] = useState<string | null>(
    () => localStorage.getItem("mugharred_session") || null,
  );
  const [name, setName] = useState(
    () => localStorage.getItem("mugharred_name") || ""
  );
  const [error, setError] = useState<string | null>(null);

  // Feed state
  const [ws, setWs] = useState<WebSocket | null>(null);
  const [messages, setMessages] = useState<Message[]>([]);
  const [totalMessages, setTotalMessages] = useState(0);
  const [onlineUsers, setOnlineUsers] = useState<string[]>([]);
  const [input, setInput] = useState("");
  const [expandedMessage, setExpandedMessage] = useState<Message | null>(null);
  
  // Virtual scroll state
  const containerRef = useRef<HTMLDivElement | null>(null);
  const [scrollTop, setScrollTop] = useState(0);

  const canJoin = useMemo(() => name.trim().length >= 2, [name]);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    const trimmed = name.trim();
    if (trimmed.length < 2) {
      setError("Skriv minst 2 tecken.");
      return;
    }
    setError(null);

    try {
      const res = await fetch("/api/login", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ name: trimmed }),
      });
      if (!res.ok) {
        const body = await res.json().catch(() => ({}));
        setError(body.error || "Inloggning misslyckades");
        return;
      }
      const data = await res.json();
      setSessionId(data.sessionId);
      localStorage.setItem("mugharred_session", data.sessionId);
      localStorage.setItem("mugharred_name", data.name);
    } catch (err) {
      setError("Kunde inte ansluta till servern");
    }
  }

  async function loadPage(offset: number) {
    try {
      const res = await fetch(
        `/api/messages?offset=${offset}&limit=${PAGE_SIZE}`,
      );
      const data = await res.json();
      setTotalMessages(data.total);
      setMessages((prev) => {
        const existingIds = new Set(prev.map((m) => m.id));
        const merged = [...prev];
        for (const m of data.items) {
          if (!existingIds.has(m.id)) merged.push(m);
        }
        return merged;
      });
    } catch (err) {
      console.error("Failed to load messages:", err);
    }
  }

  function handleScroll(e: React.UIEvent<HTMLDivElement>) {
    const el = e.currentTarget;
    setScrollTop(el.scrollTop);

    if (
      el.scrollTop + el.clientHeight >= el.scrollHeight - ROW_HEIGHT * 2 &&
      messages.length < totalMessages
    ) {
      loadPage(messages.length);
    }
  }

  function sendMessage() {
    if (!ws || !input.trim()) return;
    ws.send(JSON.stringify({ type: "send_message", text: input.trim() }));
    setInput("");
  }

  // WebSocket connection
  useEffect(() => {
    if (!sessionId) return;

    loadPage(0);

    const protocol = window.location.protocol === "https:" ? "wss:" : "ws:";
    const wsUrl = `${protocol}//${window.location.host}/ws?sessionId=${encodeURIComponent(sessionId)}`;
    const socket = new WebSocket(wsUrl);
    
    socket.onmessage = (event) => {
      const data = JSON.parse(event.data);
      if (data.type === "message") {
        setMessages((prev) => [data.message, ...prev]);
        setTotalMessages((prev) => prev + 1);
      } else if (data.type === "online_users") {
        setOnlineUsers(data.users);
      } else if (data.type === "error") {
        alert(data.error);
        // If error is about inactivity, logout user
        if (data.error.includes("inaktivitet")) {
          localStorage.removeItem("mugharred_session");
          localStorage.removeItem("mugharred_name");
          setSessionId(null);
        }
      }
    };
    
    socket.onclose = () => {
      console.log("WS closed");
    };
    
    setWs(socket);

    return () => {
      socket.close();
    };
  }, [sessionId]);

  // If logged in, show feed interface
  if (sessionId) {
    const totalHeight = totalMessages * ROW_HEIGHT;
    const visibleStartIndex = Math.floor(scrollTop / ROW_HEIGHT);
    const visibleCount = 10;
    const visibleEndIndex = Math.min(
      visibleStartIndex + visibleCount,
      totalMessages,
    );
    const visibleMessages = messages.slice(
      visibleStartIndex,
      visibleEndIndex,
    );
    const topSpacerHeight = visibleStartIndex * ROW_HEIGHT;

    return (
      <div className="min-h-screen bg-[radial-gradient(1200px_circle_at_20%_10%,rgba(0,108,58,0.18),transparent_55%),radial-gradient(900px_circle_at_85%_30%,rgba(212,175,55,0.18),transparent_55%),linear-gradient(to_bottom,rgba(255,255,255,0.8),rgba(255,255,255,0.55))] text-neutral-900">
        {/* Header */}
        <header className="mx-auto flex max-w-6xl items-center justify-between px-4 py-5">
          <div className="flex items-center gap-3">
            <div className="grid h-10 w-10 place-items-center rounded-2xl bg-[#006C3A] text-white shadow-[0_10px_30px_rgba(0,0,0,0.10)]">
              <span className="text-lg font-semibold">M</span>
            </div>
            <div className="leading-tight">
              <div className="text-base font-semibold tracking-tight">Mugharred</div>
              <div className="text-xs text-neutral-600">Välkommen, {name}!</div>
            </div>
          </div>

          <div className="flex items-center gap-4">
            <div className="text-sm text-neutral-700">
              <span className="inline-flex items-center gap-2">
                <Users className="h-4 w-4" />
                {onlineUsers.length} online
              </span>
            </div>
            <button
              onClick={() => {
                localStorage.removeItem("mugharred_session");
                localStorage.removeItem("mugharred_name");
                setSessionId(null);
                ws?.close();
              }}
              className="text-sm text-neutral-600 hover:text-neutral-900"
            >
              Logga ut
            </button>
          </div>
        </header>

        <main className="mx-auto max-w-4xl px-4 pb-10">
          {/* Online users */}
          <div className="mb-6 rounded-[1.75rem] border border-black/10 bg-white/70 p-4 shadow-[0_20px_60px_rgba(0,0,0,0.08)] backdrop-blur">
            <div className="text-sm font-semibold mb-2">Online nu ({onlineUsers.length}/5)</div>
            <div className="flex flex-wrap gap-2">
              {onlineUsers.map((user) => (
                <span
                  key={user}
                  className="inline-flex items-center gap-2 rounded-xl border border-black/10 bg-white px-3 py-1 text-sm"
                >
                  <div className="h-2 w-2 rounded-full bg-green-500" />
                  {user}
                </span>
              ))}
            </div>
          </div>

          {/* Message input */}
          <div className="mb-6 rounded-[1.75rem] border border-black/10 bg-white/70 p-4 shadow-[0_20px_60px_rgba(0,0,0,0.08)] backdrop-blur">
            <div className="flex gap-3">
              <textarea
                value={input}
                onChange={(e) => setInput(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === "Enter" && !e.shiftKey) {
                    e.preventDefault();
                    sendMessage();
                  }
                }}
                placeholder="Skriv ett meddelande..."
                className="flex-1 resize-none rounded-xl border border-black/10 bg-white px-3 py-2 text-sm outline-none transition focus:border-[#006C3A] focus:ring-2 focus:ring-[#006C3A]/30"
                rows={2}
                maxLength={500}
              />
              <button
                onClick={sendMessage}
                disabled={!input.trim() || !ws}
                className="inline-flex items-center justify-center rounded-xl bg-[#006C3A] px-4 py-2 text-white shadow-[0_12px_35px_rgba(0,0,0,0.12)] hover:bg-emerald-800 disabled:cursor-not-allowed disabled:bg-emerald-900/50"
              >
                <Send className="h-4 w-4" />
              </button>
            </div>
          </div>

          {/* Virtual scrolled feed */}
          <div className="rounded-[1.75rem] border border-black/10 bg-white/70 shadow-[0_20px_60px_rgba(0,0,0,0.08)] backdrop-blur overflow-hidden">
            <div className="p-4 border-b border-black/5">
              <div className="text-sm font-semibold">Live feed</div>
              <div className="text-xs text-neutral-600">Native scroll • {totalMessages} meddelanden</div>
            </div>
            
            <div
              ref={containerRef}
              style={{ height: 600, overflowY: "auto" }}
              onScroll={handleScroll}
              className="px-4"
            >
              <div style={{ height: totalHeight, position: "relative" }}>
                <div style={{ transform: `translateY(${topSpacerHeight}px)` }}>
                  {visibleMessages.map((message) => (
                    <div
                      key={message.id}
                      style={{
                        height: ROW_HEIGHT,
                        overflow: "hidden",
                        padding: "12px 0",
                        borderBottom: "1px solid rgba(0,0,0,0.05)",
                        cursor: "pointer",
                      }}
                      onClick={() => setExpandedMessage(message)}
                      className="hover:bg-black/5 transition-colors rounded-lg px-2"
                    >
                      <div className="flex items-center justify-between text-xs text-neutral-600 mb-1">
                        <span className="font-medium text-neutral-900">{message.user}</span>
                        <span>{new Date(message.timestamp).toLocaleTimeString()}</span>
                      </div>
                      <div className="text-sm text-neutral-800">
                        <span className="block truncate">{message.text}</span>
                        <span className="mt-1 inline-flex items-center gap-1 text-xs text-[#006C3A]">
                          Läs mer <ArrowRight className="h-3 w-3" />
                        </span>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </div>
        </main>

        {/* Message modal */}
        {expandedMessage && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
            <div className="max-w-2xl w-full rounded-[1.75rem] border border-black/10 bg-white p-6 shadow-[0_20px_60px_rgba(0,0,0,0.20)]">
              <div className="flex items-center justify-between mb-4">
                <div>
                  <div className="font-semibold text-lg">{expandedMessage.user}</div>
                  <div className="text-sm text-neutral-600">
                    {new Date(expandedMessage.timestamp).toLocaleString()}
                  </div>
                </div>
                <button
                  onClick={() => setExpandedMessage(null)}
                  className="inline-flex items-center justify-center rounded-xl border border-black/10 bg-white/70 p-2 text-neutral-600 hover:text-neutral-900 hover:bg-white"
                >
                  <X className="h-5 w-5" />
                </button>
              </div>
              <div className="text-sm text-neutral-800 whitespace-pre-wrap leading-relaxed">
                {expandedMessage.text}
              </div>
            </div>
          </div>
        )}
      </div>
    );
  }

  // Landing page for non-logged in users
  return (
    <div className="min-h-screen bg-[radial-gradient(1200px_circle_at_20%_10%,rgba(0,108,58,0.18),transparent_55%),radial-gradient(900px_circle_at_85%_30%,rgba(212,175,55,0.18),transparent_55%),linear-gradient(to_bottom,rgba(255,255,255,0.8),rgba(255,255,255,0.55))] text-neutral-900">
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
              <span className="inline-flex items-center gap-2"><MessageSquareText className="h-4 w-4" />Live via WebSocket</span>
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
                  { user: "Alex", time: "2m", text: "Första intrycket är att det ser väldigt rent och snyggt ut!" },
                  { user: "Robin", time: "5m", text: "Gillar hur enkelt det är att komma igång - bara skriv namn och kör." },
                  { user: "Sam", time: "8m", text: "Smart med virtualiserad scroll, märks inte ens att det bara laddar 10 åt gången." },
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
            <FeatureCard
              icon={<MessageSquareText className="h-5 w-5" />}
              title="Live feed"
              desc="Uppdateras via WebSockets eller polling. Nya inlägg dyker upp direkt." 
            />
            <FeatureCard
              icon={<Users className="h-5 w-5" />}
              title="Online-lista"
              desc="Visar vilka som är online just nu. Max fem användare samtidigt." 
            />
            <FeatureCard
              icon={<Zap className="h-5 w-5" />}
              title="Virtual scroll"
              desc="Renderar 10 rader åt gången med fast radhöjd och native scrollbar." 
            />
          </div>

          <div className="mt-4 grid gap-4 md:grid-cols-3">
            <FeatureCard
              icon={<Shield className="h-5 w-5" />}
              title="Rate limiting"
              desc="Enkel begränsning av inlägg för att minska spam och attacker." 
            />
            <FeatureCard
              icon={<Globe2 className="h-5 w-5" />}
              title="En sida"
              desc="Ingen navigation behövs. Allt sker på samma vy." 
            />
            <FeatureCard
              icon={<ArrowRight className="h-5 w-5" />}
              title="Modal för fulltext"
              desc="Klicka på ett inlägg för att läsa hela texten utan att ändra radhöjd." 
            />
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
                  <span className="inline-flex items-center gap-2"><MessageSquareText className="h-4 w-4" />Live uppdatering</span>
                </div>
              </div>

              <form onSubmit={handleSubmit} className="rounded-2xl border border-black/10 bg-white p-5 shadow-[0_10px_25px_rgba(0,0,0,0.06)]">
                <label className="text-sm font-medium">Ditt namn</label>
                <input
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  placeholder="Skriv ditt namn..."
                  className="mt-2 w-full rounded-xl border border-black/10 bg-white px-3 py-2 text-sm outline-none transition focus:border-[#006C3A] focus:ring-2 focus:ring-[#006C3A]/30"
                />
                {error && <div className="mt-2 text-xs text-red-700">{error}</div>}

                <button
                  type="submit"
                  disabled={!canJoin}
                  className="mt-4 inline-flex w-full items-center justify-center gap-2 rounded-xl bg-[#006C3A] px-4 py-2.5 text-sm font-medium text-white shadow-[0_12px_35px_rgba(0,0,0,0.12)] hover:bg-emerald-800 disabled:cursor-not-allowed disabled:bg-emerald-900/50"
                >
                  Anslut <ArrowRight className="h-4 w-4" />
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

function FeatureCard({
  icon,
  title,
  desc,
}: {
  icon: React.ReactNode;
  title: string;
  desc: string;
}) {
  return (
    <div className="rounded-[1.5rem] border border-black/10 bg-white/70 p-5 shadow-[0_14px_40px_rgba(0,0,0,0.08)] backdrop-blur">
      <div className="flex items-center gap-3">
        <div className="grid h-10 w-10 place-items-center rounded-2xl bg-[#006C3A]/10 text-[#006C3A]">
          {icon}
        </div>
        <div className="text-sm font-semibold">{title}</div>
      </div>
      <div className="mt-2 text-sm text-neutral-700">{desc}</div>
    </div>
  );
}