// ═══════════════════════════════════════════════════════════════════
// arinanoX — user.js untuk Firefox ESR di proot XFCE (Android)
// Sumber: cheatsheet/docs/firefox-userjs-proot.md
//
// Cara pakai:
//   cp user.js ~/.mozilla/firefox/xxxxxxxx.default-release/
//   firefox
//
// Cek: buka about:config, cari browser.cache.disk.enable → false (bold)
// ═══════════════════════════════════════════════════════════════════

// ──── RENDERING ────────────────────────────────────────────────────
// Di proot tidak ada akses GPU native, hardware acceleration malah
// bikin lag/crash. Paksa software WebRender.
user_pref("gfx.webrender.software", true);           // WebRender mode software
user_pref("gfx.webrender.all", false);                // jangan paksa HW WebRender
user_pref("gfx.webrender.enabled", true);             // aktifkan WR (otomatis pilih software)
user_pref("layers.acceleration.disabled", true);      // matikan HW layers
user_pref("gfx.direct2d.disabled", true);
user_pref("gfx.canvas.accelerated", false);           // canvas pake CPU aja

// ──── ANIMASI UI ──────────────────────────────────────────────────
// Matikan semua animasi, hemat CPU/render
user_pref("browser.tabs.animated", false);
user_pref("browser.tabs.allowTabDetach", false);
user_pref("browser.panorama.animate_zoom", false);
user_pref("browser.fullscreen.animate", false);
user_pref("browser.download.animateNotifications", false);
user_pref("toolkit.cosmeticAnimations.enabled", false);
user_pref("ui.prefersReducedMotion", 1);              // prefers-reduced-motion: reduce

// ──── MEMORY ──────────────────────────────────────────────────────
// Batasi proses konten, cache di RAM bukan disk
user_pref("dom.ipc.processCount", 2);                 // max 2 content process
user_pref("dom.ipc.processCount.extension", 1);       // extension di 1 proses aja
user_pref("browser.cache.memory.enable", true);       // cache di RAM
user_pref("browser.cache.memory.capacity", 49152);    // 48 MB RAM cache (48*1024)
user_pref("browser.sessionhistory.max_entries", 20);  // kurangi history per tab
user_pref("browser.sessionstore.interval", 60000);    // session store tiap 60 detik
user_pref("browser.sessionstore.restore_on_demand", true);
user_pref("browser.sessionstore.restore_tabs_lazily", true);
user_pref("browser.sessionstore.max_tabs_undo", 5);
user_pref("browser.sessionstore.max_windows_undo", 3);
user_pref("browser.tabs.unloadOnLowMemory", true);   // unload tab kalo RAM mepet

// ──── DISK CACHE ──────────────────────────────────────────────────
// I/O storage Android lewat bind-mount lambat. Matikan total.
user_pref("browser.cache.disk.enable", false);
user_pref("browser.cache.disk_cache_ssl", false);
user_pref("browser.cache.offline.enable", false);
user_pref("browser.cache.disk.smart_size.enabled", false);
user_pref("browser.cache.disk.capacity", 0);
user_pref("media.cache_size", 0);                     // no media disk cache
user_pref("media.cache_readahead_limit", 0);

// ──── NETWORK ─────────────────────────────────────────────────────
// Matikan prefetch/preconnect/speculative — hemat request nganggur,
// bagus juga untuk jaringan mobile data.
user_pref("network.prefetch-next", false);
user_pref("network.dns.disablePrefetch", true);
user_pref("network.dns.disablePrefetchFromHTTPS", true);
user_pref("network.http.speculative-parallel-limit", 0);
user_pref("network.predictor.enabled", false);
user_pref("network.predictor.enable-prefetch", false);
user_pref("network.preconnect", false);
user_pref("browser.places.speculativeConnect.enabled", false);
user_pref("network.http.pacing.requests.enabled", false);  // kirim request secepatnya
user_pref("network.http.max-connections", 256);            // koneksi paralel cukup
user_pref("network.http.max-persistent-connections-per-server", 12);

// ──── TELEMETRY & BACKGROUND ──────────────────────────────────────
// Matikan semua telemetry & background task — hemat CPU/RAM.
user_pref("datareporting.healthreport.uploadEnabled", false);
user_pref("datareporting.policy.dataSubmissionEnabled", false);
user_pref("datareporting.sessions.current.clean", false);
user_pref("toolkit.telemetry.unified", false);
user_pref("toolkit.telemetry.enabled", false);
user_pref("toolkit.telemetry.server", "data:,");
user_pref("toolkit.telemetry.archive.enabled", false);
user_pref("toolkit.telemetry.bhrPing.enabled", false);
user_pref("toolkit.telemetry.cachedClientID", "");
user_pref("toolkit.telemetry.firstShutdownPing.enabled", false);
user_pref("toolkit.telemetry.hybridContent.enabled", false);
user_pref("toolkit.telemetry.newProfilePing.enabled", false);
user_pref("toolkit.telemetry.reportingpolicy.firstRun", false);
user_pref("toolkit.telemetry.shutdownPingSender.enabled", false);
user_pref("toolkit.telemetry.updatePing.enabled", false);
user_pref("browser.laterrun.enabled", false);
user_pref("browser.newtabpage.activity-stream.feeds.telemetry", false);
user_pref("browser.newtabpage.activity-stream.telemetry", false);
user_pref("browser.ping-centre.telemetry", false);
user_pref("beacon.enabled", false);                    // matikan navigator.sendBeacon

// ──── PRIVASI DASAR ───────────────────────────────────────────────
// Level moderat — tidak seekstrim arkenfox, biar tidak banyak breakage
// di environment proot yang resource terbatas.
user_pref("privacy.trackingprotection.fingerprinting.enabled", true);
user_pref("privacy.trackingprotection.cryptomining.enabled", true);
user_pref("privacy.trackingprotection.enabled", true);
user_pref("privacy.trackingprotection.socialtrack.enabled", true);
user_pref("network.cookie.cookieBehavior", 1);         // blokir cookie pihak ke-3
user_pref("network.cookie.thirdparty.sessionOnly", true);
user_pref("network.cookie.lifetimePolicy", 2);         // cookie hanya untuk sesi
user_pref("dom.security.https_only_mode", true);        // HTTPS-only mode
user_pref("dom.security.https_only_mode_ever_enabled", true);
user_pref("browser.safebrowsing.malware.enabled", false);  // hemat request
user_pref("browser.safebrowsing.phishing.enabled", false);

// ──── SANDBOX ─────────────────────────────────────────────────────
// Dimatikan total. Kernel Android biasanya tidak izinkan unprivileged
// user namespaces yang dibutuhkan sandbox Firefox — akibatnya di proot
// sandbox sering bikin tab crash atau gagal start.
//
// Trade-off: tanpa sandbox, exploit lewat halaman web punya akses lebih
// luas ke rootfs proot (bukan Android host). Kalau device dipakai buka
// situs sembarangan, set content.level ke 1 atau 2 dulu.
user_pref("security.sandbox.content.level", 0);
user_pref("security.sandbox.gpu.level", 0);
user_pref("security.sandbox.windows.content.enabled", false);
user_pref("security.sandbox.windows.gpu.enabled", false);
user_pref("security.sandbox.logging.enabled", false);
user_pref("security.sandbox.content.shadow-server.enabled", false);

// ──── UPDATE & STARTUP ────────────────────────────────────────────
user_pref("app.update.auto", false);
user_pref("app.update.enabled", false);
user_pref("app.update.silent", false);
user_pref("browser.startup.page", 0);                 // about:blank saat start
user_pref("browser.newtabpage.enabled", false);
user_pref("browser.newtabpage.activity-stream.enabled", false);
user_pref("browser.aboutwelcome.enabled", false);
user_pref("browser.privatebrowsing.autostart", false); // jangan paksa private mode
