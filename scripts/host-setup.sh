#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

echo ">>> Installing host packages..."

# Skip termux-setup-storage if ~/storage already exists
if [ ! -d "$HOME/storage" ]; then
    termux-setup-storage
else
    echo "  [*] ~/storage already exists, skipping."
fi

pkg update -y
pkg install -y x11-repo tur-repo
pkg install -y termux-x11-nightly proot-distro pulseaudio xorg-xrandr netcat-openbsd termux-api virglrenderer-android android-tools
# mesa-utils provides glxinfo/glxgears for GPU testing
pkg install -y mesa-utils 2>/dev/null || true
echo ">>> Host packages installed."
