<div align="center">
  <h1>📱 DroidDesk</h1>
  <p><strong>Your phone is a Linux workstation.</strong></p>
  <p>Full desktop environment with XFCE, Firefox, VS Code, and AI tools — running natively on Android.</p>
</div>

---

## ⚡ One Command Install

```bash
curl -sL https://raw.githubusercontent.com/arinadi/DroidDesk/main/bootstrap.sh | bash
```

That's it. Installs XFCE desktop, mobile-optimized theme, and all launchers. **Under 30 seconds.**

---

## 💡 Why DroidDesk?

### Your Phone, Your Desktop

Connect a monitor and it's a Linux PC. Unplug and your entire setup comes with you.

- 🖥️ **Full Desktop** — XFCE4 with mobile-optimized 64px panel, high DPI, dark theme
- 🌐 **Real Browsers** — Firefox ESR that doesn't sleep when screen is off
- 💻 **Real IDE** — VS Code, Geany, Neovim with native Node.js, Python, Git
- 🤖 **Local AI** — Ollama runs LLMs offline, 5+ tokens/sec
- 📱 **Android Integration** — Control battery, notifications, camera from Linux terminal

### Overcomes Android's Biggest Limitations

| Problem | DroidDesk Solution |
|---------|-------------------|
| Chrome sleeps background tabs | Full desktop browser in proot — stays alive |
| No glibc apps | Ubuntu proot with standard glibc |
| Can't run VS Code | Native Linux VS Code with extensions |
| Background processes killed | Termux:WakeLock keeps sessions alive |
| No developer tools | Full gcc, Node.js, Python, Docker |

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
curl -sL https://raw.githubusercontent.com/arinadi/DroidDesk/main/bootstrap.sh | bash
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
bash ~/.droiddesk/scripts/patch.sh --firefox --code --nodejs

# See all available
bash ~/.droiddesk/scripts/patch.sh --list
```

### Available Packages

| Category | Packages |
|----------|----------|
| 🌐 Browser | Firefox ESR, Chromium |
| 💻 IDE | VS Code, Geany, Neovim |
| 🟢 Dev | Node.js 24, Python 3, Git, GitHub CLI, Build Essential |
| 🤖 AI | Ollama (local LLM) |
| 🖥️ System | htop, tmux, Zsh, Nala, Docker |
| 🔧 CLI | jq, tree, ripgrep, SQLite, curl, wget |
| 🎨 GUI | Viewnior, Xarchiver, Galculator |

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
│  Firefox, VS Code, custom themes    │     Preserved across updates
├─────────────────────────────────────┤
│  IMAGE LAYER (immutable)            │  ← Pre-built from Dockerfile
│  Ubuntu 24.04 + XFCE + base tools   │     ghcr.io/arinadi/droiddesk
└─────────────────────────────────────┘
```

### Base Image

DroidDesk uses the **official Ubuntu 24.04 Docker image** (`ubuntu:24.04`) as its base. This ensures:
- Standard glibc compatibility with all Linux software
- Regular security updates from Canonical
- ARM64 native support for Android devices
- Full apt package repository access

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

| Command | Action |
|---------|--------|
| `bash ~/start-x11.sh` | Start X11 + PulseAudio |
| `bash ~/start-xfce.sh` | Start XFCE desktop |
| `bash ~/kill-all.sh` | Stop everything |
| `bash ~/kill-proot.sh` | Stop desktop only |
| `bash ~/kill-x11.sh` | Stop X11/audio only |
| `bash ~/update.sh` | Update DroidDesk |
| `bash ~/.droiddesk/scripts/patch.sh` | Install software |

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
