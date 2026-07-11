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

**Silverblue-style atomic upgrades:** `bash ~/update.sh` renames the old deployment to `arinanox-prev` before deploying the new image. Instant rollback: `bash ~/.arinanox/scripts/proot-rollback.sh`.

| Concept | NixOS | arinanoX |
|---------|-------|-----------|
| System definition | `configuration.nix` | `image/Dockerfile` |
| Packages | declarative list | `RUN apt-get install` |
| Config files | `environment.etc` | `COPY configs/ → /home/admin` |
| Reproducible | yes (closures) | yes (CI + GHCR) |
| Atomic upgrades | generations | rename + rollback script |
| Rollback | `nixos-rebuild switch --rollback` | `proot-rollback.sh` |
| User overlays | home-manager | `patch.sh` (layers tracked) |

**Base:** Debian 13 (Trixie). Firefox ESR from native repos — zero external APT sources.

**Update:** `bash ~/update.sh` pulls latest GHCR image, re-deploys as new atomic generation.

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
| Updates | `update.sh` (30s) | re-do everything |

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

### Install more with patch

```bash
bash ~/.arinanox/scripts/patch.sh                    # Interactive
bash ~/.arinanox/scripts/patch.sh --chromium --code --zsh
bash ~/.arinanox/scripts/patch.sh --list
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

## 🚀 Start / Stop / Update

```bash
bash ~/start.sh    # PulseAudio → X11 → virgl(?) → XFCE (one command)
bash ~/stop.sh     # Stop everything
bash ~/update.sh   # Update arinanoX
```

### 🎮 GPU Acceleration (virglrenderer)

arinanoX auto-detects `virglrenderer-android`. Install once:

```bash
pkg install virglrenderer-android
# → restart ~/start.sh  (now with GPU)
```

| Mode | Env | Performance |
|------|-----|-------------|
| GPU (virgl) | `GALLIUM_DRIVER=virpipe` | 4K video, 3D games |
| CPU (fallback) | `LIBGL_ALWAYS_SOFTWARE=1` | Desktop only |

### 📱 Termux:Widget (1-tap launchers)

| Shortcut | Action |
|----------|--------|
| 🟢 `start.sh` | Full startup |
| 🔴 `stop.sh` | Full stop |
| 🔄 `update.sh` | Update |

---

## 📋 Commands

### Desktop

| Command | Action |
|---------|--------|
| `bash ~/start.sh` | Start desktop (auto GPU) |
| `bash ~/stop.sh` | Stop everything |
| `bash ~/update.sh` | Update |
| `bash ~/.arinanox/scripts/patch.sh` | Install software |

### Termux:API (inside proot terminal)

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

### Panel Widgets (Whisker Menu → Panel → Add → Generic Monitor)

```
bash ~/.arinanox/tools/genmon-battery.sh   # 🔋
bash ~/.arinanox/tools/genmon-volume.sh    # 🔊
```

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
| No GPU acceleration | Mesa software rendering; xfwm4 compositing off |
| ARM64 only | QEMU user-mode for cross-arch |
| No native X11 | Termux:X11 app |
| Storage restrictions | `termux-setup-storage` |

All warnings (systemd proxy, system bus, DPMS, GL renderer) are suppressed at the declarative layer — arinanoX runs clean out of the box.

**Cannot do:** Docker containers, GPU hardware access, systemd services, x86 natively.

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
│   └── configs/          ←    XFCE, bash, GTK, autostart
├── scripts/              ← setup, patch, theme, rollback
├── launchers/            ← start/kill/update shortcuts
├── docs/                 ← documentation
└── .github/workflows/    ← CI → GHCR image on push
```

---

## 📜 License

## 🖱️ Right-Click on Touchscreen

Trackpad mode is recommended. For right-click without switching modes:

1. `Ctrl+Alt+R` triggers right-click at pointer (via xdotool)
2. Add a button to Termux Extra Keys:

`~/.termux/termux.properties`:
```properties
extra-keys = [ \
 ['ESC','/',{key: '-', popup: '|'},'HOME','UP','END','PGUP',{macro: "CTRL ALT r", display: "🖱️R"}], \
 ['TAB','CTRL','ALT','LEFT','DOWN','RIGHT','PGDN','KEYBOARD'] \
]
```

Run `termux-reload-settings` after saving.

GPLv3
