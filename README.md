<div align="center">
  <h1>📱 DroidDesk</h1>
  <p><strong>Your phone is a Linux workstation.</strong></p>
  <p>Full desktop environment with XFCE, Firefox, VS Code, and AI tools — running natively on Android.</p>
</div>

---

## ⚡ One Command Install

```bash
curl -sL "https://raw.githubusercontent.com/arinadi/DroidDesk/main/bootstrap.sh?v=$(date +%s%3N)" | bash
```

That's it. Installs XFCE desktop with stock theme and all launchers. **Under 30 seconds.**

---

## 💡 Why DroidDesk?

### Your Phone, Your Desktop

Connect a monitor and it's a Linux PC. Unplug and your entire setup comes with you.

- 🖥️ **Full Desktop** — XFCE4 + Whisker Menu, Firefox ESR, Mousepad, touch-friendly
- 🖱️ **Touch Optimized** — Single-click Thunar, large scrollbars, XFCE power/pulseaudio tray
- 🌐 **Real Browsers** — Firefox ESR native from Debian repos, no external APT needed
- 💻 **Ready to Code** — Node.js 22, Python 3 (pip/venv/dev), GCC, CMake, Git
- 🤖 **Local AI** — Ollama runs LLMs offline, 5+ tokens/sec
- 📱 **Android Integration** — Battery, clipboard sync, volume, camera, voice, GPS

### Overcomes Android's Biggest Limitations

| Problem | DroidDesk Solution |
|---------|-------------------|
| Chrome sleeps background tabs | Full desktop browser in proot — stays alive |
| No glibc apps | Debian proot with standard glibc |
| Can't run VS Code | Native Linux VS Code with extensions |
| Background processes killed | Termux:WakeLock keeps sessions alive |
| No developer tools | GCC, CMake, Node.js 22, Python 3 built-in |

---

## 🚀 Getting Started

### Requirements

- Android phone (ARM64)
- [Termux](https://f-droid.org/en/packages/com.termux/) (from F-Droid, NOT Play Store)
- [Termux:X11](https://github.com/termux/termux-x11/releases/tag/nightly) app
- [Termux:API](https://f-droid.org/en/packages/com.termux.api/) app (optional)
- [Termux:Widget](https://f-droid.org/en/packages/com.termux.widget/) app (**recommended** — one-tap launchers from home screen)

### Install

```bash
curl -sL "https://raw.githubusercontent.com/arinadi/DroidDesk/main/bootstrap.sh?v=$(date +%s%3N)" | bash
```

### Start

```bash
bash ~/start-x11.sh    # Start X11 server + audio
# Open Termux:X11 app on your phone
bash ~/start-xfce.sh   # Start desktop
```

### Stop

```bash
bash ~/kill-all.sh     # Stop everything
```

---

## 📱 Termux:Widget Support

DroidDesk auto-creates home screen shortcuts. Install [Termux:Widget](https://f-droid.org/en/packages/com.termux.widget/) to use them.

### Setup

1. Install Termux:Widget from F-Droid
2. Add Termux:Widget to your home screen
3. Select `~/.shortcuts/` as the shortcuts folder

### Available Shortcuts

| Shortcut | Action |
|----------|--------|
| 🟢 start-x11.sh | Start X11 + PulseAudio |
| 🟢 start-xfce.sh | Start XFCE desktop |
| 🔴 kill-all.sh | Stop everything |
| 🔴 kill-proot.sh | Stop desktop only |
| 🔴 kill-x11.sh | Stop X11/audio only |
| 🔄 update.sh | Update DroidDesk |

One tap to start, one tap to stop.

---

## 📦 Install Software

After setup, add software with the patch installer:

```bash
# Interactive (choose what to install)
bash ~/.droiddesk/scripts/patch.sh

# Or install specific packages
bash ~/.droiddesk/scripts/patch.sh --chromium --code --zsh

# See all available
bash ~/.droiddesk/scripts/patch.sh --list
```

### Available Packages

| Category | Packages |
|----------|----------|
| 🌐 Browser | Chromium |
| 💻 IDE | VS Code, Geany, Neovim |
| 🤖 AI | Ollama (local LLM) |
| 🖥️ System | Zsh, Nala, Docker |
| 🔧 CLI | ripgrep, GitHub CLI |
| 🎨 GUI | Viewnior, Xarchiver, Galculator |

> **Built into image**: Firefox ESR, Mousepad, Ristretto, Git, Node.js 22 LTS, Python 3 (pip/venv/dev), GCC/Make/CMake/pkg-config, htop, tmux, OpenSSH, xfce4-whiskermenu/power-manager/pulseaudio/genmon. Adwaita icons, single-click Thunar, clipboard auto-sync. Stock XFCE Greybird theme.

---

## 🔄 Update

```bash
bash ~/update.sh
```

Or re-run install — it detects existing installation and offers to update.

---

## 🏗️ How It Works

### Image Architecture

```
┌─────────────────────────────────────┐
│  USER LAYER (mutable)               │  ← Your packages, configs, data
│  VS Code, Chromium, Ollama, etc.    │     Preserved across updates
├─────────────────────────────────────┤
│  IMAGE LAYER (immutable)            │  ← Pre-built from Dockerfile
│  Debian 13 + XFCE + Firefox ESR + dev  │     ghcr.io/arinadi/droiddesk
└─────────────────────────────────────┘
```

### Base Image

DroidDesk uses the **official Debian 13 (Trixie) Docker image** (`debian:13`) as its base. This ensures:
- Standard glibc compatibility with all Linux software
- Regular security updates
- ARM64 native support for Android devices
- Full apt package repository access
- Firefox ESR directly from Debian repos (no external APT source)

### Update Workflow

- **Install:** Pull pre-built image from GHCR (~30 seconds)
- **Update scripts:** Download new launchers from GitHub
- **Update packages:** `apt-get upgrade` inside proot
- **Major upgrade:** Auto backup/restore preserves your data

---

## ⚠️ Termux Limitations

DroidDesk runs on top of Termux, which has inherent limitations:

| Limitation | Impact | Workaround |
|-----------|--------|------------|
| **No root access** | Cannot modify `/system` | proot provides root-like environment |
| **No kernel modules** | Cannot load drivers | Uses proot for syscall translation |
| **No systemd** | No service management | Start services manually |
| **No native Docker** | Cannot run containers | Use proot-distro instead |
| **ARM64 only** | No x86 emulation | QEMU user-mode for cross-arch |
| **No GPU acceleration** | Limited OpenGL | Mesa software rendering |
| **Battery optimization** | Android kills background | Use Termux:WakeLock |
| **Storage restrictions** | Android 11+ scoped storage | Grant via `termux-setup-storage` |
| **No native X11** | No display server | Use Termux:X11 app |
| **No PulseAudio daemon** | No system audio | Use TCP audio forwarding |

### What DroidDesk Cannot Do

- ❌ Run Docker containers (uses proot instead)
- ❌ Access GPU hardware directly (software rendering only)
- ❌ Run systemd services (manual process management)
- ❌ Survive Android's Phantom Process Killer (without Developer Options fix)
- ❌ Run x86 software natively (ARM64 only, QEMU for cross-arch)

---

## 📱 Commands

### Desktop

| Command | Action |
|---------|--------|
| `bash ~/start-x11.sh` | Start X11 + PulseAudio |
| `bash ~/start-xfce.sh` | Start XFCE desktop |
| `bash ~/kill-all.sh` | Stop everything |
| `bash ~/kill-proot.sh` | Stop desktop only |
| `bash ~/kill-x11.sh` | Stop X11/audio only |
| `bash ~/update.sh` | Update DroidDesk |
| `bash ~/.droiddesk/scripts/patch.sh` | Install software |

### 📱 Termux:API Commands (inside proot)

> Requires [Termux:API](https://f-droid.org/en/packages/com.termux.api/) app.

| Command | Action |
|---------|--------|
| `battery` | Show battery % and health |
| `clipget` | Paste from Android clipboard |
| `clipset "text"` | Copy to Android clipboard |
| `vol-up` / `vol-down` | Control media volume |
| `bright 50` | Set screen brightness 0-100 |
| `toast "hello"` | Show Android toast popup |
| `notify "Title" "Body"` | Send Android notification |
| `buzz` | Short vibration feedback |
| `speak "hello"` | Text-to-speech |
| `listen` | Speech-to-text (voice input) |
| `openurl "https://..."` | Open URL in Android browser |
| `share file.txt` | Share file to Android apps |
| `whereami` | GPS location (JSON) |
| `wifi` | WiFi connection info |
| `photo shot.jpg` | Take photo with camera |
| `flash` / `flash-off` | Toggle flashlight |

### 🔋 Panel Monitors (optional, add via Whisker Menu → Panel → Add)

| Monitor | Command |
|---------|---------|
| Battery % | `bash ~/.droiddesk/tools/genmon-battery.sh` |
| Volume level | `bash ~/.droiddesk/tools/genmon-volume.sh` |

### 🔄 Clipboard Sync (auto-starts on login)

Android and proot clipboards stay in sync automatically. No manual copy-paste needed.

---

## 🛑 Android 12+ Fix

If Termux crashes with `signal 9`:

- **Android 14+:** Developer Options → Disable child process restrictions
- **Android 12-13:** Run via ADB:
  ```bash
  adb shell settings put global settings_enable_monitor_phantom_procs false
  ```

---

## 📂 Project Structure

```
DroidDesk/
├── bootstrap.sh          ← curl target (entry point)
├── scripts/              ← setup + patch scripts
├── launchers/            ← desktop shortcuts
├── image/                ← Dockerfile + configs
├── docs/                 ← documentation
└── archive/              ← old files (git history)
```

---

## 📜 License

GPLv3
