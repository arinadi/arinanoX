<div align="center">
  <h1>📱 DroidDesk Proot XFCE</h1>
  <p>A focused, audio-optimized setup script for running a complete XFCE desktop inside a Termux proot environment.</p>
</div>

---

## ⚡ Quick Install

Download and run the setup script directly from GitHub in Termux:

```bash
curl -sL https://raw.githubusercontent.com/arinadi/DroidDesk/main/proot-xfce-setup.sh -o ~/proot-xfce-setup.sh
chmod +x ~/proot-xfce-setup.sh
bash ~/proot-xfce-setup.sh
```

> [!NOTE]
> This script installs XFCE inside an Ubuntu proot and creates separate start scripts for Termux:X11 and the proot session.

## 🧐 Why Ubuntu Proot?

While you can install XFCE natively in Termux, running the **entire desktop inside a proot Ubuntu environment** offers a much smoother "daily-driver" experience:

- 📦 **Standard `glibc` binaries:** Termux uses `bionic` (Android's libc), which breaks many standard Linux apps. Ubuntu proot uses standard `glibc`, ensuring maximum compatibility.
- 🔗 **Seamless App Integration:** While you *could* run native Termux XFCE and sync proot apps to the menu, setting them as default apps is extremely difficult because the binaries aren't natively in the Termux directory. By putting the *entire* XFCE desktop inside Ubuntu, setting apps like `firefox-esr` as your default browser "Just Works".
- 🛡️ **Better App Stability:** Apps run exactly as they would on a standard desktop without complex cross-environment workarounds. For example, Firefox ESR handles complex JavaScript and Google logins perfectly inside proot.
- 🐧 **Why specifically Ubuntu?**
  - **Debian** is incredibly stable, but Ubuntu provides far superior out-of-the-box binary support and PPA availability for ARM64 architectures (especially for proprietary apps and newer packages).
  - **Fedora** is excellent on desktop (my personal daily driver!), but its ARM ports within proot environments currently feel less mature and have more friction compared to Ubuntu.

## 🛠️ What this script does

- Installs Termux-required packages (`x11-repo`, `termux-x11-nightly`, `proot-distro`).
- Sets up an **Ubuntu** proot distro.
- Installs XFCE and basic GUI tooling (thunar, settings, audio utils).
- Generates 6 focused launcher scripts in `~/.shortcuts/` (with symlinks to `~/`):
  - 🟢 `start-x11.sh` — Start Termux:X11 and PulseAudio (Host).
  - 🟢 `start-xfce.sh` — Start XFCE session (Proot).
  - 🔴 `kill-x11.sh` — Stop X11 and PulseAudio (cleans sockets).
  - 🔴 `kill-proot.sh` — Stop all XFCE processes and clean session cache.
  - 🔴 `kill-all.sh` — Stop everything with one command.
  - 🔄 `update-droiddesk.sh` — Safely update these scripts from GitHub.

## 🧩 The Minimalist Package Philosophy

To keep the environment lightning-fast and prevent storage bloat, this script deliberately avoids "kitchen-sink" meta-packages (like `xfce4` or `xubuntu-desktop`) which install hundreds of unnecessary background services. Instead, we use a highly curated, modular list:

**1. Termux Host Packages:**
- `x11-repo` & `tur-repo`: Required to access the specialized X11 and Termux User Repository packages.
- `termux-x11-nightly`: The absolute best, highest-performance X server for Android (far superior to VNC).
- `proot-distro`: The official, safest way to manage Linux containers in Termux.
- `pulseaudio` & `xorg-xrandr`: Essential for native audio forwarding and display scaling.

**2. Ubuntu Proot Packages (`--no-install-recommends`):**
- `dbus-x11`: Crucial for Inter-Process Communication (IPC). Without this, XFCE components cannot talk to each other and will crash.
- `xfce4-session`, `xfwm4`, `xfce4-panel`: The absolute bare minimum trinity to render a working desktop (Session manager, Window manager, and Taskbar).
- `xfdesktop4`, `thunar`, `xfce4-settings`, `xfce4-terminal`: Provides the desktop background, file manager, GUI settings app, and a terminal to actually interact with the system.
- `libgl1`, `mesa-utils`: Provides OpenGL rendering support so the window manager doesn't crash on Android displays.

> [!TIP]
> Use `bash ~/patch-tui.sh` after installation to easily install Browsers (Firefox), AI Tools, and Dev IDEs.

## 📋 Requirements

- Android phone (ARM64)
- **Termux** (installed from F-Droid, NOT Play Store)
- **Termux:X11** Android app (Nightly release)
- **Termux:Widget** (Optional, but highly recommended for 1-tap launchers)

## 🛑 CRITICAL: Android 12+ Background Restrictions (Signal 9 Error)

If your Termux session suddenly crashes with `[Process completed (signal 9) - press Enter]`, it means Android's **Phantom Process Killer** has forcefully terminated your Linux desktop for running too many background processes. Running a full desktop environment (Window manager, panels, DBus) easily hits this limit.

**To fix this permanently:**

- **Android 14+**: 
  1. Enable **Developer Options** in your Android Settings.
  2. Find the setting **"Disable child process restrictions"** and turn it **ON**.
- **Android 12 & 13**:
  You must use ADB (from a PC, or via Wireless Debugging directly in Termux) to run these commands:
  ```bash
  adb shell "/system/bin/device_config put activity_manager max_phantom_processes 2147483647"
  adb shell settings put global settings_enable_monitor_phantom_procs false
  ```

> [!WARNING]
> Without disabling this restriction, your Proot XFCE session **will** crash repeatedly during heavy usage (e.g., browsing the web with Firefox or compiling code).

## 🚀 Usage

### 📱 Termux:Widget Support
If you have the **Termux:Widget** app installed, the setup script automatically makes launchers available on your homescreen! You can start or stop sessions with a single tap without ever opening the terminal.

For terminal usage, simply run the symlinks in your home directory:

### 1. Start the Server & Audio
```bash
bash ~/start-x11.sh
```
*(Starts Termux:X11 on display `:0` and starts the PulseAudio server)*

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

Alternatively, you can stop them individually:
```bash
bash ~/kill-proot.sh
bash ~/kill-x11.sh
```

> [!TIP]
> **Recommended Workflow:** Always run the `kill` scripts before starting a new session to ensure a clean slate and avoid "X server already running" or missing cursor errors!

## ⚠️ Notes

- `start-xfce.sh` **must** be run only after `start-x11.sh` is already running.
- The container session runs natively via `dbus-run-session startxfce4`.
- If the display is unstable or tearing, try adding Termux:X11 flags such as `-legacy-drawing` or `-force-bgra` to the `start-x11.sh` script.

## 🔄 How to Safely Update Scripts

If this repository receives an update, **DO NOT** delete your files or run `rm -rf *`. The setup script is designed to be safe and idempotent.

To update your launcher and kill scripts without losing your Linux installation or personal files, simply run the update script (also available in the Termux:Widget):

```bash
bash ~/update-droiddesk.sh
```

*(Alternatively, you can manually re-run the `curl` Quick Install command from the top of this guide).*

This will quickly download the newest script, skip the OS installation, update any missing packages, and overwrite your old shortcuts with the newest versions automatically.

## 🧹 Cleanup Tips (Nuclear Option)

If your environment breaks entirely or you want to free up space and start completely fresh:
1. Go to your **Android Settings** > **Apps** > **Termux**.
2. Tap **Storage** > **Clear Data** (and Clear Cache).
3. Open Termux again and re-run the Quick Install script. 

> [!CAUTION]
> This will permanently wipe your proot distro and all Linux files/configurations inside Termux, giving you a 100% clean slate.

## 📜 License

Released under the GPLv3 license.
