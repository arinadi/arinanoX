<div align="center">
  <h1>📱 DroidDesk Proot XFCE</h1>
  <p>A portable Linux environment for Android designed to overcome mobile OS limitations.</p>
</div>

---

## ⚡ Quick Start

Download and run the setup script directly from GitHub in Termux:

```bash
curl -sL https://raw.githubusercontent.com/arinadi/DroidDesk/main/setup-proot-xfce.sh -o ~/setup-proot-xfce.sh
chmod +x ~/setup-proot-xfce.sh
bash ~/setup-proot-xfce.sh
```

> [!NOTE]
> This script installs XFCE inside an Ubuntu proot and creates specialized launcher scripts for Termux:X11 and PulseAudio.

## 📦 Install Extra Apps (TUI)

After the main installation, you can install Browsers (Firefox), AI Tools, and Development IDEs using the interactive package installer:

```bash
curl -sL https://raw.githubusercontent.com/arinadi/DroidDesk/main/install-tui-packages.sh | bash
```

---

## 💡 The Vision: Portable Linux Power

DroidDesk isn't just a terminal; it's a **complete Linux workstation in your pocket**. It solves the two biggest pain points of mobile productivity:

1.  **Overcoming Android Sleep Limits:** Native Android browsers (Chrome/Firefox) aggressively sleep background tabs when the screen is off. By running a full desktop browser inside a proot Linux session, you can keep complex web apps alive.
    *   *Usecase:* Running **Google Colab** as a background backend for a Telegram bot or long-running scripts that must not sleep.
2.  **Native Developer Tooling:** Mobile apps are limited. DroidDesk provides standard `glibc` environments for the tools you actually use.
    *   *Usecase:* A full **Web Development IDE** (VS Code, Geany) with native Node.js, Python, and Git, allowing you to code anywhere with a desktop-class experience.

## 🧐 Why Ubuntu Proot?

While you can install XFCE natively in Termux, running the **entire desktop inside a proot Ubuntu environment** offers a much smoother "daily-driver" experience:

- 📦 **Standard `glibc` binaries:** Termux uses `bionic` (Android's libc), which breaks many standard Linux apps. Ubuntu proot uses standard `glibc`, ensuring maximum compatibility.
- 📂 **Android Storage Integration:** DroidDesk bridges the gap between mobile and desktop files. It bind-mounts your internal storage to `/sdcard` and creates native-style symlinks:
  - **`~/Downloads`** → Android's `Download` folder.
  - **`~/Pictures`** → Android's `DCIM/Camera` folder.
  - **`~/Android_Internal`** → Full `/sdcard` access.
- 🔗 **Seamless App Integration:** Setting proot apps as defaults in native Termux XFCE is difficult. By putting the *entire* XFCE desktop inside Ubuntu, apps like `firefox-esr` "Just Work" as the system browser.
- 🛡️ **Better App Stability:** Apps run exactly as they would on a standard desktop. Firefox ESR, for example, handles complex JavaScript and Google logins perfectly inside proot.
- 🐧 **Why Ubuntu?** Ubuntu provides superior binary support and PPA availability for ARM64 compared to Debian or Fedora ARM ports in proot environments.

## 🛠️ What this script does

- Installs Termux-required packages (`x11-repo`, `termux-x11-nightly`, `proot-distro`).
- Sets up an **Ubuntu** proot distro.
- Installs XFCE and basic GUI tooling (thunar, settings, audio utils).
- **Android Storage Integration:** Automatically mounts your phone's internal storage to `/sdcard` and creates symlinks in the Ubuntu home directory (`~/Downloads`, `~/Pictures`, `~/Android_Internal`).
- Generates 6 focused launcher scripts in `~/.shortcuts/` (with symlinks to `~/`):
  - 🟢 `start-x11.sh` — Start Termux:X11 and PulseAudio (Host).
  - 🟢 `start-xfce.sh` — Start XFCE session (Proot).
  - 🔴 `kill-x11.sh` — Stop X11 and PulseAudio (cleans sockets).
  - 🔴 `kill-proot.sh` — Stop all XFCE processes and clean session cache.
  - 🔴 `kill-all.sh` — Stop everything with one command.
  - 🔄 `update-droiddesk.sh` — Safely update these scripts from GitHub.

## 🧩 The Minimalist Package Philosophy

To keep the environment lightning-fast and prevent storage bloat, this script avoids "kitchen-sink" meta-packages. Instead, we use a highly curated, modular list:

**1. Termux Host Packages:**
- `termux-setup-storage`: Grants Termux access to your phone's internal memory.
- `x11-repo` & `tur-repo`: Required for high-performance X11 and Termux User Repository packages.
- `termux-x11-nightly`: The best, highest-performance X server for Android.
- `proot-distro`: The safest way to manage Linux containers in Termux.
- `pulseaudio` & `xorg-xrandr`: Essential for audio forwarding and display scaling.

**2. Ubuntu Proot Packages (`--no-install-recommends`):**
- `dbus-x11`: Crucial for Inter-Process Communication (IPC).
- `xfce4-session`, `xfwm4`, `xfce4-panel`: Bare minimum to render a working desktop.
- `xfdesktop4`, `thunar`, `xfce4-settings`, `xfce4-terminal`: Desktop background, file manager, GUI settings, and terminal.
- `libgl1`, `mesa-utils`: OpenGL rendering support.

## 📋 Requirements

- Android phone (ARM64)
- **Termux** (installed from F-Droid, NOT Play Store)
- **Termux:X11** Android app (Nightly release)
- **Termux:Widget** (Optional, but recommended for 1-tap launchers)

## 🎨 Personalization & Pre-config
DroidDesk comes with an optimized XFCE configuration (64px panel, high DPI, black wallpaper) designed for mobile screens.

To apply the pre-set theme inside your Proot environment:
```bash
curl -sL https://raw.githubusercontent.com/arinadi/DroidDesk/main/apply-xfce-config.sh | bash
```
*Note: Restart your XFCE session after applying.*

## 🛑 CRITICAL: Android 12+ Background Restrictions (Signal 9 Error)

If your Termux session crashes with `[Process completed (signal 9) - press Enter]`, Android's **Phantom Process Killer** has terminated your desktop.

**To fix this permanently:**

- **Android 14+**: 
  1. Enable **Developer Options** in Android Settings.
  2. Find **"Disable child process restrictions"** and turn it **ON**.
- **Android 12 & 13**:
  You must use ADB (from a PC or via Wireless Debugging) to run:
  ```bash
  adb shell "/system/bin/device_config put activity_manager max_phantom_processes 2147483647"
  adb shell settings put global settings_enable_monitor_phantom_procs false
  ```

> [!WARNING]
> Without this fix, your Proot XFCE session **will** crash repeatedly during heavy usage (e.g., browsing the web).

## 🚀 Usage

### 📱 Termux:Widget Support
If you have **Termux:Widget** installed, the setup script automatically makes launchers available on your homescreen! Start or stop sessions with a single tap.

For terminal usage, run the symlinks in your home directory:

### 1. Start the Server & Audio
```bash
bash ~/start-x11.sh
```
*(Starts Termux:X11 and PulseAudio server)*

### 2. Start the Desktop
```bash
bash ~/start-xfce.sh
```
*(Launches the XFCE session inside the proot container)*

### 3. Stop Everything
```bash
bash ~/kill-all.sh
```
*(Securely kills all desktop processes, audio servers, and cleans socket files)*

> [!TIP]
> **Workflow:** Always run the `kill` scripts before starting a new session to ensure a clean slate and avoid "X server already running" or missing cursor errors!

## ⚠️ Notes

- `start-xfce.sh` **must** be run only after `start-x11.sh` is already running.
- The session runs via `dbus-launch --exit-with-session startxfce4`.
- If display is unstable, try adding `-legacy-drawing` or `-force-bgra` to the `start-x11.sh` script.

## 🔄 How to Safely Update Scripts

To update your launcher and kill scripts without losing your Linux installation or personal files, run the update script:

```bash
bash ~/update-droiddesk.sh
```

This will download the newest scripts, update missing packages, and overwrite your old shortcuts automatically.

## 🧹 Cleanup Tips (Nuclear Option)

To free up space and start completely fresh:
1. Go to **Android Settings** > **Apps** > **Termux**.
2. Tap **Storage** > **Clear Data**.

> [!CAUTION]
> This will permanently wipe your proot distro and all Linux files inside Termux.

## 📜 License

Released under the GPLv3 license.
