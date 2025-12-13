#!/bin/bash
set -e

echo "🔄 Fixar landing page med korrekt ersättning..."

# Backup
cp frontend/src/MugharredLandingPage.tsx frontend/src/MugharredLandingPage.tsx.backup.2

# Använd sed för exakt ersättning av rad 384-521
sed -i '384,521c\
  if (!sessionId) {\
    return (\
      <div className="min-h-screen bg-[radial-gradient(1200px_circle_at_20%_10%,rgba(0,108,58,0.18),transparent_55%),radial-gradient(900px_circle_at_85%_30%,rgba(212,175,55,0.18),transparent_55%),linear-gradient(to_bottom,rgba(255,255,255,0.8),rgba(255,255,255,0.55))] text-neutral-900">\
        {toast && (\
          <Toast \
            message={toast.message} \
            type={toast.type} \
            onClose={() => setToast(null)} \
          />\
        )}\
        <header className="mx-auto flex max-w-6xl items-center justify-between px-4 py-5">\
          <div className="flex items-center gap-3">\
            <div className="grid h-10 w-10 place-items-center rounded-2xl bg-[#006C3A] text-white shadow-[0_10px_30px_rgba(0,0,0,0.10)]">\
              <span className="text-lg font-semibold">M</span>\
            </div>\
            <div className="leading-tight">\
              <div className="text-base font-semibold tracking-tight">Mugharred</div>\
              <div className="text-xs text-neutral-600">Live feed • Minimal login</div>\
            </div>\
          </div>\
          <a href="#join" className="inline-flex items-center gap-2 rounded-xl bg-[#006C3A] px-4 py-2 text-sm font-medium text-white shadow-[0_12px_35px_rgba(0,0,0,0.12)] hover:bg-emerald-800">\
            Gå med <ArrowRight className="h-4 w-4" />\
          </a>\
        </header>\
        <main className="mx-auto max-w-6xl px-4">\
          <section className="grid items-center gap-10 py-10 md:grid-cols-2 md:py-16">\
            <div className="space-y-6">\
              <h1 className="text-4xl font-semibold tracking-tight md:text-5xl">\
                Mugharred\
                <span className="block text-neutral-600">en enkel social feed som uppdateras live.</span>\
              </h1>\
              <p className="max-w-xl text-base text-neutral-700">\
                Skriv ditt namn och hoppa rakt in. Alla meddelanden syns i ett gemensamt flöde med native scroll och smart virtualisering.\
              </p>\
              <div className="flex flex-wrap gap-3">\
                <a href="#join" className="inline-flex items-center justify-center rounded-xl bg-[#006C3A] px-5 py-2.5 text-sm font-medium text-white shadow-[0_12px_35px_rgba(0,0,0,0.12)] hover:bg-emerald-800">\
                  Starta nu <ArrowRight className="ml-2 h-4 w-4" />\
                </a>\
              </div>\
            </div>\
            <div className="relative">\
              <div className="rounded-[1.75rem] border border-black/10 bg-white/70 p-5 shadow-[0_20px_60px_rgba(0,0,0,0.10)] backdrop-blur">\
                <div className="mb-4 flex items-center justify-between">\
                  <div className="text-sm font-semibold">Live feed</div>\
                </div>\
                <div className="space-y-3">\
                  <div className="rounded-2xl border border-black/5 bg-white p-4">\
                    <div className="mb-1 flex items-center justify-between text-xs text-neutral-600">\
                      <span className="font-medium text-neutral-900">Noura</span>\
                      <span>1m</span>\
                    </div>\
                    <div className="text-sm text-neutral-800">Kul att se att allt uppdateras direkt.</div>\
                  </div>\
                  <div className="rounded-2xl border border-black/5 bg-white p-4">\
                    <div className="mb-1 flex items-center justify-between text-xs text-neutral-600">\
                      <span className="font-medium text-neutral-900">Fahad</span>\
                      <span>3m</span>\
                    </div>\
                    <div className="text-sm text-neutral-800">En sida, en feed. Perfekt!</div>\
                  </div>\
                </div>\
              </div>\
            </div>\
          </section>\
          <section id="join" className="py-12 md:py-16">\
            <div className="rounded-[2rem] border border-black/10 bg-white/70 p-6 shadow-[0_20px_60px_rgba(0,0,0,0.10)] backdrop-blur md:p-10">\
              <div className="grid items-center gap-8 md:grid-cols-2">\
                <div>\
                  <h2 className="text-2xl font-semibold tracking-tight">Gå med i Mugharred</h2>\
                  <p className="mt-2 text-sm text-neutral-700">Skriv ditt namn för att ansluta.</p>\
                </div>\
                <form onSubmit={handleLogin} className="rounded-2xl border border-black/10 bg-white p-5">\
                  <label className="text-sm font-medium">Ditt namn</label>\
                  <input\
                    type="text"\
                    value={name}\
                    onChange={(e) => setName(e.target.value)}\
                    placeholder="Skriv ditt namn..."\
                    className="mt-2 w-full rounded-xl border border-black/10 bg-white px-3 py-2 text-sm outline-none transition focus:border-[#006C3A]"\
                    required\
                    minLength={2}\
                    maxLength={50}\
                    disabled={loginLoading}\
                  />\
                  {loginError && (\
                    <div className="mt-2 text-xs text-red-700">{loginError}</div>\
                  )}\
                  <button\
                    type="submit"\
                    disabled={loginLoading || !name.trim()}\
                    className="mt-4 inline-flex w-full items-center justify-center gap-2 rounded-xl bg-[#006C3A] px-4 py-2.5 text-sm font-medium text-white shadow-[0_12px_35px_rgba(0,0,0,0.12)] hover:bg-emerald-800 disabled:cursor-not-allowed disabled:bg-emerald-900/50"\
                  >\
                    {loginLoading ? (\
                      <>\
                        <Loader2 className="animate-spin" size={20} />\
                        Ansluter...\
                      </>\
                    ) : (\
                      <>\
                        Anslut <ArrowRight className="h-4 w-4" />\
                      </>\
                    )}\
                  </button>\
                </form>\
              </div>\
            </div>\
          </section>\
        </main>\
      </div>\
    );\
  }\
' frontend/src/MugharredLandingPage.tsx

echo "🚀 Bygger och deployar..."
./deploy-frontend.sh

echo "✅ Landing page fixad!"