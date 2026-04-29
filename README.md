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

## 🧐 Why Proot? (Termux vs Ubuntu)

While you can install XFCE natively in Termux, running the **entire desktop inside a proot Ubuntu environment** offers a much smoother "daily-driver" experience:

- 📦 **Standard `glibc` binaries:** Termux uses `bionic` (Android's libc), which breaks many standard Linux apps. Ubuntu proot uses standard `glibc`, ensuring maximum compatibility.
- 🔗 **Seamless App Integration:** While you *could* run native Termux XFCE and sync proot apps to the menu, setting them as default apps is extremely difficult because the binaries aren't natively in the Termux directory. By putting the *entire* XFCE desktop inside Ubuntu, setting apps like `firefox-esr` as your default browser "Just Works".
- 🛡️ **Better App Stability:** Apps run exactly as they would on a standard desktop without complex cross-environment workarounds. For example, Firefox ESR handles complex JavaScript and Google logins perfectly inside proot.
- 📚 **Standard Repositories:** You get access to the full `apt` repository of Ubuntu/Debian instead of just the limited Termux packages.

## 🛠️ What this script does

- Installs Termux-required packages (`x11-repo`, `termux-x11-nightly`, `proot-distro`).
- Sets up an **Ubuntu** proot distro.
- Installs XFCE and basic GUI tooling (thunar, settings, audio utils).
- Generates 4 focused launcher scripts in `~/.shortcuts/` (with symlinks to `~/`):
  - 🟢 `start-x11.sh` — Start Termux:X11 and PulseAudio (Host).
  - 🟢 `start-xfce.sh` — Start XFCE session (Proot).
  - 🔴 `kill-x11.sh` — Stop X11 and PulseAudio.
  - 🔴 `kill-proot.sh` — Stop all XFCE processes and clean temp files securely.

## 📋 Requirements

- Android phone (ARM64)
- **Termux** (installed from F-Droid, NOT Play Store)
- **Termux:X11** Android app (Nightly release)
- **Termux:Widget** (Optional, but highly recommended for 1-tap launchers)

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
bash ~/kill-proot.sh
bash ~/kill-x11.sh
```
*(Securely kills all desktop processes and cleans socket files without deleting your personal configs)*

> [!TIP]
> **Recommended Workflow:** Always run the `kill` scripts before starting a new session to ensure a clean slate and avoid "X server already running" or missing cursor errors!

## ⚠️ Notes

- `start-xfce.sh` **must** be run only after `start-x11.sh` is already running.
- The container session runs natively via `dbus-run-session startxfce4`.
- If the display is unstable or tearing, try adding Termux:X11 flags such as `-legacy-drawing` or `-force-bgra` to the `start-x11.sh` script.

## 🔄 How to Safely Update Scripts

If this repository receives an update, **DO NOT** delete your files or run `rm -rf *`. The setup script is designed to be safe and idempotent.

To update your launcher and kill scripts without losing your Linux installation or personal files, simply re-run the Quick Install command:

```bash
curl -sL https://raw.githubusercontent.com/arinadi/DroidDesk/main/proot-xfce-setup.sh -o ~/proot-xfce-setup.sh
bash ~/proot-xfce-setup.sh
```

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
