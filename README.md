<div align="center">
  <h1>📱 arinanoX</h1>
  <p><strong>Your phone is a Linux workstation — in 30 seconds.</strong></p>
  <p>
    <a href="https://arinano.work"><img src="https://img.shields.io/badge/site-arinano.work-blue"></a>
    <a href="https://github.com/arinadi/arinanoX/actions"><img src="https://img.shields.io/github/actions/workflow/status/arinadi/arinanoX/build-image.yml?label=build"></a>
    <a href="https://github.com/arinadi/arinanoX/blob/main/LICENSE"><img src="https://img.shields.io/github/license/arinadi/arinanoX"></a>
  </p>

  ```bash
curl -sL https://raw.githubusercontent.com/arinadi/arinanoX/main/bootstrap.sh | bash
```

  <img src="docs/arinanox-screenshot.jpg" alt="arinanoX desktop" width="360" style="border-radius:12px;">
  <p>
    Debian 13 &nbsp;·&nbsp; XFCE &nbsp;·&nbsp; Firefox ESR &nbsp;·&nbsp; Dev tools &nbsp;·&nbsp; Touch-optimized<br>
    <small>TermuX&nbsp;→&nbsp;X11&nbsp;→&nbsp;LinuX&nbsp;→&nbsp;Trixie&nbsp;→&nbsp;XFCE</small>
  </p>
</div>

---

## ⚡ Why

Your Android phone is a pocket PC with 8GB+ RAM and an ARM64 CPU — it deserves a real desktop.

| | arinanoX |
|---|---|
| 🏗️ | **Declarative.** A single Dockerfile defines the entire system. Like NixOS, but on Debian. |
| ⚡ | **Prebuilt.** 580MB image from CI. Extract and run — 30 seconds. No 30-minute apt wait. |
| 🔄 | **Atomic.** Updates to a fresh image. Old one kept as `arinanox-prev`. Instant rollback. |
| 🎯 | **Proot-aware.** Compositing off, power daemon removed, all systemd warnings suppressed. |
| 🎨 | **Orchis Material Design + elementary-hidpi icons.** Dark, touch-friendly, baked in. |
| 📱 | **Termux:API.** Battery, clipboard, voice, camera, notifications — from inside proot. |

---

### Requirements

- Android ARM64 + [Termux](https://f-droid.org/en/packages/com.termux/) (F-Droid, NOT Play Store)
- [Termux:X11](https://github.com/termux/termux-x11/releases/tag/nightly) — display server
- [Termux:API](https://f-droid.org/en/packages/com.termux.api/) (optional — battery, clipboard, voice)
- [Termux:Widget](https://f-droid.org/en/packages/com.termux.widget/) (recommended — home screen launchers)

---

## 🏗️ How It Works

```
┌─────────────────────────────────────┐
│  USER LAYER (mutable)               │  ← Your packages, configs, data
│  VS Code, Chromium, Ollama, etc.    │     Preserved across updates
├─────────────────────────────────────┤
│  CORE LAYER (declarative & reproducible) │  ← Built from Dockerfile in CI
│  Debian 13 + XFCE + Firefox + dev   │     ghcr.io/arinadi/arinanox
└─────────────────────────────────────┘
```

### Declarative Image (NixOS-inspired)

The image is built from a **single Dockerfile** — your system as code.

- 📦 **All packages, configs, and themes** defined declaratively in one file
- ⚙️ **XFCE optimized for proot**: compositing off, DPI/scale, touch-friendly
- 🎨 **Orchis Material Design + elementary-hidpi icons** — baked in
- 🎯 **Proot-aware**: systemd warnings suppressed, power daemon removed, dbus locked down
- ⚡ **CI-built and deployed** to GHCR on every push

**Silverblue-style atomic upgrades:** `bash ~/.arinanox/scripts/proot-setup.sh` renames the old deployment to `arinanox-prev` before deploying the new image. Instant rollback: `bash ~/.arinanox/scripts/proot-rollback.sh`.

| Concept | NixOS | arinanoX |
|---------|-------|-----------|
| System definition | `configuration.nix` | `image/Dockerfile` |
| Packages | declarative list | `RUN apt-get install` |
| Config files | `environment.etc` | `COPY configs-target/ → /home/admin` |
| Reproducible | yes (closures) | yes (CI + GHCR) |
| Atomic upgrades | generations | rename + rollback script |
| Rollback | `nixos-rebuild switch --rollback` | `proot-rollback.sh` |
| User overlays | home-manager | `arinanox install`, `user-manifest.yaml` |

**Base:** Debian 13 (Trixie). Firefox ESR from native repos — zero external APT sources.

### Prebuilt vs DIY

| | arinanoX (prebuilt) | DIY (manual install) |
|---|---|---|
| Download | **~580 MB** (1 image) | ~450 MB (base distro) + packages |
| Install time | **~30s** (extract + setup) | **20-30 min** (apt + config + theme) |
| XFCE desktop | configured, ready | must install + configure |
| Orchis theme | baked-in | manual install + set |
| Touch-friendly | scrollbars, single-click, scale 2x | manual GTK config |
| Proot fixes | compositing off, warnings suppressed, power removed | trial-and-error |
| TAPI utilities | included | must copy + configure |
| Rollback | atomic (rename) | manual backup/restore |
| Updates | `curl bootstrap.sh \| bash` (30s) | re-do everything |

**Why prebuilt?** The Dockerfile does 30 minutes of apt installs, config tweaks, and proot optimizations so you skip straight to a working desktop.

---

## 📦 Built-In + Extras

### In the image (ready to use)

| Category | Tools |
|----------|-------|
| 🌐 Browser | Firefox ESR |
| 🖥️ Desktop | XFCE4 + Whisker Menu + PulseAudio tray |
| 🖱️ Touch | Single-click Thunar, large scrollbars, clipboard auto-sync |
| 📝 Apps | Mousepad (editor), Ristretto (images) |
| 🔧 Dev | Git, Node.js 22 LTS, Python 3 (pip/venv/dev), GCC, Make, CMake |
| 📊 Sys | htop, tmux, OpenSSH |
| 🎨 Theme | Orchis-Dark (Material Design) + elementary-hidpi icons |

### Install more with APT Store

Launch **APT Store** from Whisker Menu → System, or:

```bash
bash ~/.arinanox/tools/apt-store.sh
```

Quick-add repos for VS Code, Firefox, Docker, OpenJDK right from the GUI.

### CLI extras (patch.sh)

```bash
bash ~/.arinanox/scripts/patch.sh --chromium --code --zsh
```

| Category | Packages |
|----------|----------|
| 🌐 Browser | Chromium |
| 💻 IDE | VS Code (code-server), Geany, Neovim |
| 🤖 AI | Ollama (local LLM) |
| 🖥️ System | Zsh + Oh My Zsh, Nala |
| 🔧 CLI | ripgrep, GitHub CLI |
| 🎨 GUI | Viewnior, Xarchiver, Galculator |

---

## 🚀 Usage

```bash
arinanox start        # One-command launch
arinanox stop         # Stop everything
arinanox status       # System overview
arinanox doctor       # Full health-check
arinanox store        # APT Store GUI
arinanox backup       # Backup to /sdcard
arinanox snapshot     # Instant checkpoint (hardlinked)
arinanox update       # Fresh image + re-apply configs
arinanox help         # All commands
```

### 🎮 GPU Acceleration (virglrenderer)

arinanoX auto-detects the best GPU path (3-tier):

```
1. android         → virgl_test_server_android      (native GLES)
2. angle-vulkan-null → virgl + ANGLE passthrough    (Vulkan GPUs)
3. CPU fallback    → LIBGL_ALWAYS_SOFTWARE=1
```

| Mode | Env | Performance |
|------|-----|-------------|
| GPU (virgl) | `GALLIUM_DRIVER=virpipe` | 4K video, 3D games |
| CPU (fallback) | `LIBGL_ALWAYS_SOFTWARE=1` | Desktop only |

### 📱 Termux:Widget (1-tap launchers)

| Shortcut | Action |
|----------|--------|
| 🟢 `1-start-arinanox.sh` | Full startup |
| 🔴 `0-stop-arinanox.sh` | Full stop |

### 🔄 Update (preserves user config via manifest)

```bash
arinanox snapshot create    # Checkpoint first
arinanox update              # Fresh image + re-apply user-manifest.yaml
```

### Declarative User Layer

`~/.arinanox/user-manifest.yaml` tracks your packages, dotfiles, and XFCE configs. Auto-generated by snapshot, auto-reapplied after update.

```bash
arinanox install  # Apply packages from manifest
```

---

## 🤖 AI VibeCoding Stack

arinanoX can serve as a **portable AI coding workstation** — all agent tools run natively inside proot (not via Termux bind-mount).

| Tool | Function | Install |
|------|----------|---------|
| [Pi](https://github.com/earendil-works/pi-coding-agent) | Agent orchestration (loop, tool-calling, LLM API) | `npm install -g @earendil-works/pi-coding-agent` |
| [lean-ctx](https://github.com/yvgude/lean-ctx) | Context compression (shell output, file read, session memory) | Binary musl ARM64 from GH releases |
| [ddg_search](https://github.com/oevortex/ddg_search) | Web search via AI (IAsk) + DuckDuckGo CLI | `npm install -g @oevortex/ddg_search` |
| [playwright-cli](https://playwright.dev/agent-cli/) | Browser automation (Playwright Firefox) | `npm install -g @playwright/cli` + `playwright-cli install-browser firefox` |
| DeepSeek API | Model provider (V4 Chat, 1M context) | Config `~/.pi/agent/models.json` |

### Pre-installed in image

All tools are **pre-installed** in the arinanoX image — no setup needed after login:

| Tool | Status |
|------|--------|
| **Pi** v0.80.6 | ✅ `node /usr/lib/.../pi-coding-agent/dist/cli.js` |
| **lean-ctx** v3.9.8 | ✅ `/usr/local/bin/lean-ctx` |
| **ddg_search** v1.4.0 | ✅ `/usr/lib/.../ddg_search/` |
| **playwright-cli** v0.1.17 | ✅ + Firefox 152.0.4 downloaded |
| **DeepSeek config** | ✅ `~/.pi/agent/models.json` |
| **MCP config** | ✅ `~/.pi/agent/mcp.json` |
| **Firefox user.js** | 📦 Copy manually after first Firefox run (see below) |

> **Note:** Firefox user.js is **pre-deployed** in the image. Firefox is started briefly during
> build to create the profile, so `user.js` is ready on first launch. No manual copy needed.

For first-time setup (run once after login):
```bash
arinanox-ai-setup
```
This ensures lean-ctx hooks and user.js are properly initialized.

### Important: PROOT_NO_SECCOMP=1

Node.js tools (Pi, ddg_search, playwright) require `export PROOT_NO_SECCOMP=1` before `proot-distro login` to work around known proot bugs:
- `uv__io_poll: EINTR` (libuv crash)
- `fork: Function not implemented` (seccomp blocks clone/fork)
- `futex` error (V8/libuv thread sync)

Already applied automatically in `~/.shortcuts/1-start-arinanox.sh`.

### Note: Termux Bind-Mount

Termux binaries (`/data/data/com.termux/files/usr/bin/...`) are bind-mounted into the proot container, but **cannot be executed** due to different linker/libc:
- Termux: bionic libc (Android NDK)
- Proot: glibc (Debian)

The container PATH correctly points to `/usr/bin/` (proot-native). See `docs/plan-ai-stack.md` §8 for details.

### Preventive Measures

arinanoX applies multiple layers to prevent Termux binary shadowing:

| Layer | Mechanism | Location |
|---|---|---|
| **1. PATH hardening** | `.bashrc` sets clean PATH + guard strips Termux paths at end of init | `~/.bashrc`, `image/configs-target/home/admin/.bashrc` |
| **2. Runtime audit** | `arinanox doctor` checks every binary + PATH — warns if Termux found | `~/.arinanox/scripts/doctor.sh` |
| **3. PROOT_NO_SECCOMP** | Fix fork/futex/libuv for Node.js tools | `~/.shortcuts/1-start-arinanox.sh` |
| **4. Documentation** | Bind-mount explanation + how to audit | `README.md`, `docs/plan-ai-stack.md` §8 |

Check status anytime:
```bash
bash ~/.arinanox/scripts/doctor.sh
# or just binary audit:
bash ~/.arinanox/scripts/doctor.sh 2>/dev/null | grep -E "Binary|PATH"
```

---

## 📋 Termux:API (inside proot)

| Command | Action |
|---------|--------|
| `battery` | Battery % and health |
| `clipget` / `clipset` | Android clipboard |
| `vol-up` / `vol-down` | Media volume |
| `bright 50` | Brightness 0-100 |
| `toast "msg"` | Toast popup |
| `notify "T" "B"` | Notification |
| `buzz` | Short vibration |
| `speak "hello"` | Text-to-speech |
| `listen` | Speech-to-text |
| `openurl` / `share` | Open / share in Android |
| `whereami` / `wifi` | GPS / WiFi |
| `photo` / `flash` | Camera / flashlight |

---

## 💡 Why arinanoX?

| Problem | arinanoX Solution |
|---------|-------------------|
| Chrome sleeps tabs | Firefox ESR desktop browser — stays alive |
| No glibc apps | Debian 13 proot — standard glibc |
| No dev tools | Node.js 22, Python 3, GCC, CMake built-in |
| Background killed | Termux:WakeLock keeps sessions alive |
| No clipboard bridge | Auto-sync Android ↔ proot |

---

## ⚠️ Limitations

| Limitation | Workaround |
|-----------|------------|
| No root | proot provides root-like environment |
| No systemd | Start services manually; power-manager removed |
| No GPU | virglrenderer auto-detected (3-tier: android → angle → CPU) |
| ARM64 only | QEMU user-mode for cross-arch |
| No native X11 | Termux:X11 app |
| Storage restrictions | `termux-setup-storage` |

All warnings (systemd proxy, system bus, DPMS, GL renderer) are suppressed at the declarative layer — arinanoX runs clean out of the box.

**Cannot do:** Docker containers, systemd services, x86 natively.

---

## 🛑 Android 12+ Phantom Process Killer

- **Android 14+:** Developer Options → Disable child process restrictions
- **Android 12-13:** `adb shell settings put global settings_enable_monitor_phantom_procs false`

---

## 📂 Structure

```
arinanoX/
├── bootstrap.sh          ← one-command entry point
├── image/                ← 🎯 System definition (Dockerfile)
│   ├── Dockerfile        ←    declarative: packages, configs, themes
│   └── configs-target/    ←    XFCE, bash, GTK, autostart
├── scripts/              ← setup, patch, rollback, status
├── launchers/            ← start/stop shortcuts
├── docs/                 ← documentation
└── .github/workflows/    ← CI → GHCR image on push
```

---

## 📜 License

GPLv3 — see [LICENSE](LICENSE).

--- on Touchscreen

`Ctrl+Alt+R` triggers right-click via xdotool (auto-installed).

Add to `~/.termux/termux.properties`:
```properties
extra-keys = [ \
 ['ESC','/',{key: '-', popup: '|'},'HOME','UP','END','PGUP',{macro: "CTRL ALT r", display: "🖱️R"}], \
 ['TAB','CTRL','ALT','LEFT','DOWN','RIGHT','PGDN','KEYBOARD'] \
]
```

Run `termux-reload-settings` after saving.
