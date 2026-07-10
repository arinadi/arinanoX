<div align="center">
  <h1>📱 DroidDesk</h1>
  <p><strong>Your phone is a Linux workstation.</strong></p>
  <p>Debian 13 + XFCE + Firefox ESR + dev tools — running natively on Android.</p>
</div>

---

## ⚡ Install

```bash
curl -sL "https://raw.githubusercontent.com/arinadi/DroidDesk/main/bootstrap.sh" | bash
```

Installs XFCE desktop, launchers, and all built-in tools. **Under 30 seconds.**

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
│  Debian 13 + XFCE + Firefox + dev   │     ghcr.io/arinadi/droiddesk
└─────────────────────────────────────┘
```

### Declarative Image (NixOS-inspired)

The image is built from a **single Dockerfile** — your system as code:

- 📦 **All packages, configs, and themes** defined declaratively in one file
- ⚙️ **XFCE optimized for proot**: compositing off, DPI/scale, touch-friendly
- 🎨 **Orchis Material Design + elementary-hidpi icons** — baked in
- 🎯 **Proot-aware**: systemd warnings suppressed, power daemon removed, dbus locked down
- ⚡ **CI-built and deployed** to GHCR on every push

**Silverblue-style atomic upgrades:** `bash ~/update.sh` renames the old deployment to `droiddesk-prev` before deploying the new image. Instant rollback: `bash ~/.droiddesk/scripts/proot-rollback.sh`.

| Concept | NixOS | DroidDesk |
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
bash ~/.droiddesk/scripts/patch.sh                    # Interactive
bash ~/.droiddesk/scripts/patch.sh --chromium --code --zsh
bash ~/.droiddesk/scripts/patch.sh --list
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
bash ~/start-x11.sh    # X11 server + PulseAudio
# → Open Termux:X11 app
bash ~/start-xfce.sh   # XFCE desktop

bash ~/kill-all.sh     # Stop everything
bash ~/update.sh       # Update DroidDesk
```

### 📱 Termux:Widget (1-tap launchers)

| Shortcut | Action |
|----------|--------|
| 🟢 `start-x11.sh` | X11 + audio |
| 🟢 `start-xfce.sh` | Desktop |
| 🔴 `kill-all.sh` | Stop all |
| 🔄 `update.sh` | Update |

---

## 📋 Commands

### Desktop

| Command | Action |
|---------|--------|
| `bash ~/start-x11.sh` | Start X11 + PulseAudio |
| `bash ~/start-xfce.sh` | Start XFCE desktop |
| `bash ~/kill-all.sh` | Stop everything |
| `bash ~/update.sh` | Update |
| `bash ~/.droiddesk/scripts/patch.sh` | Install software |

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
bash ~/.droiddesk/tools/genmon-battery.sh   # 🔋
bash ~/.droiddesk/tools/genmon-volume.sh    # 🔊
```

---

## 💡 Why DroidDesk?

| Problem | DroidDesk Solution |
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

All warnings (systemd proxy, system bus, DPMS, GL renderer) are suppressed at the declarative layer — DroidDesk runs clean out of the box.

**Cannot do:** Docker containers, GPU hardware access, systemd services, x86 natively.

---

## 🛑 Android 12+ Phantom Process Killer

- **Android 14+:** Developer Options → Disable child process restrictions
- **Android 12-13:** `adb shell settings put global settings_enable_monitor_phantom_procs false`

---

## 📂 Structure

```
DroidDesk/
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

GPLv3
