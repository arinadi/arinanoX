#!/data/data/com.termux/files/usr/bin/bash
# proot-xfce-setup.sh v5.0 (Audio Focused, No GPU)
set -uo pipefail

# --- Configuration ---
DISTRO="ubuntu"; USER="admin"; PASS="admin"
ROOTFS="/data/data/com.termux/files/usr/var/lib/proot-distro/installed-rootfs/${DISTRO}"

echo ">>> 1/3: Termux Host Setup..."
pkg update -y
pkg install -y x11-repo tur-repo
pkg install -y termux-x11-nightly proot-distro pulseaudio xorg-xrandr

# --- Ubuntu Rootfs Setup ---
echo ">>> 2/3: Ubuntu Distro Setup..."
[ ! -d "$ROOTFS" ] && proot-distro install "$DISTRO"

# Run Ubuntu-side setup
proot-distro login "$DISTRO" -- bash -c "
    apt update && apt upgrade -y
    DEBIAN_FRONTEND=noninteractive apt install -y \
        sudo dbus-x11 xfce4-session xfwm4 xfce4-panel xfce4-terminal \
        xfce4-settings xfconf thunar fonts-noto pulseaudio-utils

    # User Setup
    id $USER &>/dev/null || useradd -m -s /bin/bash $USER
    echo '$USER:$PASS' | chpasswd
    echo '$USER ALL=(ALL:ALL) NOPASSWD: ALL' > /etc/sudoers.d/admin

    # Bash Config
    cat > /home/$USER/.bashrc << 'EOF'
export DISPLAY=:0 XDG_RUNTIME_DIR=/tmp
alias update='sudo apt update && sudo apt upgrade -y'
EOF
    
    # PulseAudio Client Config (Unix Socket for better latency/quality)
    mkdir -p /home/$USER/.pulse
    cat > /home/$USER/.pulse/client.conf << 'EOF'
default-server = unix:/tmp/pulse-socket
autospawn = no
daemon-binary = /bin/true
EOF
    chown -R $USER:$USER /home/$USER
"

# --- Launchers ---
echo ">>> 3/3: Generating Optimized Launchers..."

# Launcher 1: X11 & Audio Server (Termux Side)
cat > ~/start-x11.sh << 'EOF'
#!/bin/bash
pkill -9 -f "termux-x11|pulseaudio"
rm -f /tmp/.X0-lock /data/data/com.termux/files/usr/tmp/.X11-unix/X0 2>/dev/null
rm -f /data/data/com.termux/files/usr/tmp/pulse-socket 2>/dev/null

# Start PulseAudio with Unix Socket for high fidelity and low latency
pulseaudio --start --exit-idle-time=-1 --load="module-native-protocol-unix socket=/data/data/com.termux/files/usr/tmp/pulse-socket"
termux-x11 :0 -ac &

echo ">>> X11/High-Fidelity Audio Ready."
echo ">>> Open Termux:X11 app, then run start-xfce.sh in a new tab."
EOF

# Launcher 2: XFCE Desktop (Proot Side)
cat > ~/start-xfce.sh << EOF
#!/bin/bash
X11_SOCK="/data/data/com.termux/files/usr/tmp/.X11-unix"
PULSE_SOCK="/data/data/com.termux/files/usr/tmp/pulse-socket"

BINDS="--bind \$X11_SOCK:/tmp/.X11-unix --bind \$PULSE_SOCK:/tmp/pulse-socket"

echo ">>> Starting XFCE Desktop..."
proot-distro login $DISTRO \$BINDS -- su - $USER -c "
    # Safe Cleanup
    pkill -9 -f \"xfce4|dbus|thunar\" 2>/dev/null
    rm -rf /tmp/.X* /tmp/dbus-* /tmp/ssh-* 2>/dev/null
    rm -rf ~/.cache/sessions/* 2>/dev/null
    
    # Start fresh session
    dbus-run-session startxfce4
"
EOF

chmod +x ~/start-x11.sh ~/start-xfce.sh

echo "=========================================="
echo " SETUP COMPLETE (Audio Optimized)"
echo " 1. bash ~/start-x11.sh"
echo " 2. Open Termux:X11 app"
echo " 3. bash ~/start-xfce.sh"
echo "=========================================="
