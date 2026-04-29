#!/data/data/com.termux/files/usr/bin/bash
# proot-xfce-setup.sh v6.0 (Audio Focused, No GPU)
# Fixed: variable expansion, dialog, apt-get, --no-install-recommends,
#        launcher escaping, error handling
set -euo pipefail

# --- Configuration ---
DISTRO="ubuntu"
PROOT_USER="admin"
PROOT_PASS="admin"
ROOTFS="/data/data/com.termux/files/usr/var/lib/proot-distro/installed-rootfs/${DISTRO}"

# =============================================
#  Step 1/3: Termux Host Setup
# =============================================
echo ">>> 1/3: Termux Host Setup..."
pkg update -y
pkg install -y x11-repo tur-repo
pkg install -y termux-x11-nightly proot-distro pulseaudio xorg-xrandr

# =============================================
#  Step 2/3: Ubuntu Distro Setup
# =============================================
echo ">>> 2/3: Ubuntu Distro Setup..."
if [ ! -d "$ROOTFS" ]; then
    echo "  [*] Installing Ubuntu rootfs (this may take a while)..."
    proot-distro install "$DISTRO"
fi

# Run Ubuntu-side setup
# NOTE: Using double quotes for the bash -c string so that $PROOT_USER
# and $PROOT_PASS are expanded by the HOST shell before being sent to proot.
# Inner heredocs use 'EOF' (single-quoted) to prevent double-expansion.
echo "  [*] Bootstrapping Ubuntu packages..."
proot-distro login "$DISTRO" -- bash -c "
    export DEBIAN_FRONTEND=noninteractive

    # Update package lists
    apt-get update -y -q

    # Install dialog FIRST — prevents freeze on keyboard-configuration/tzdata
    # prompts that need a dialog backend even under noninteractive mode
    apt-get install -y -q --no-install-recommends dialog

    # Upgrade existing packages
    apt-get upgrade -y -q -o Dpkg::Options::='--force-confold'

    # Install XFCE + dependencies (minimal set, no recommends)
    apt-get install -y -q --no-install-recommends \
        sudo dbus-x11 \
        xfce4-session xfwm4 xfce4-panel xfce4-terminal \
        xfce4-settings xfconf thunar xfdesktop4 \
        fonts-noto pulseaudio-utils libgl1 mesa-utils \
        firefox-esr

    # --- User Setup ---
    id ${PROOT_USER} &>/dev/null || useradd -m -s /bin/bash ${PROOT_USER}
    echo \"${PROOT_USER}:${PROOT_PASS}\" | chpasswd
    echo \"${PROOT_USER} ALL=(ALL:ALL) NOPASSWD: ALL\" > /etc/sudoers.d/${PROOT_USER}
    chmod 0440 /etc/sudoers.d/${PROOT_USER}

    # --- Bash Config ---
    cat > /home/${PROOT_USER}/.bashrc << 'BASHEOF'
export DISPLAY=:0
export XDG_RUNTIME_DIR=/tmp
alias update='sudo apt-get update && sudo apt-get upgrade -y'
BASHEOF

    # --- PulseAudio Client Config (Unix Socket) ---
    mkdir -p /home/${PROOT_USER}/.pulse
    cat > /home/${PROOT_USER}/.pulse/client.conf << 'PULSEEOF'
default-server = unix:/tmp/pulse-socket
autospawn = no
daemon-binary = /bin/true
PULSEEOF

    chown -R ${PROOT_USER}:${PROOT_USER} /home/${PROOT_USER}
" || {
    echo "ERROR: Ubuntu setup failed. Check network and disk space."
    exit 1
}
echo "  [+] Ubuntu setup complete."

# =============================================
#  Step 3/3: Generating Launchers
# =============================================
echo ">>> 3/3: Generating Launchers & Shortcuts..."

mkdir -p ~/.shortcuts

# --- Launcher 1: X11 & Audio Server (Termux Side) ---
# Single-quoted heredoc ('EOF') — nothing is expanded at generation time.
cat > ~/.shortcuts/start-x11.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
TERMUX_TMP="${TMPDIR:-/data/data/com.termux/files/usr/tmp}"
PULSE_SOCK="${TERMUX_TMP}/pulse-socket"


# Start PulseAudio with Unix Socket for high fidelity and low latency
echo ">>> Starting PulseAudio..."
pulseaudio --start --exit-idle-time=-1 \
    --load="module-native-protocol-unix socket=${PULSE_SOCK}"

# Start X11
echo ">>> Starting Termux-X11..."
termux-x11 :0 -ac &
sleep 2

# Auto-open the Termux:X11 Android App
echo ">>> Switching to Termux:X11 App..."
am start -n com.termux.x11/com.termux.x11.MainActivity 2>/dev/null || true

echo ""
echo ">>> X11/High-Fidelity Audio Ready."
echo ">>> Run: bash ~/start-xfce.sh (or tap the widget!)"
EOF

# --- Launcher 2: XFCE Desktop (Proot Side) ---
# Double-quoted heredoc — $DISTRO and $PROOT_USER are baked in at generation.
# Runtime variables use \$ to defer expansion.
cat > ~/.shortcuts/start-xfce.sh << XFCEOF
#!/data/data/com.termux/files/usr/bin/bash
TERMUX_TMP="\${TMPDIR:-/data/data/com.termux/files/usr/tmp}"
X11_SOCK="\${TERMUX_TMP}/.X11-unix"
PULSE_SOCK="\${TERMUX_TMP}/pulse-socket"

# Build bind mounts
BINDS=""
[ -d "\$X11_SOCK" ]   && BINDS="\$BINDS --bind \$X11_SOCK:/tmp/.X11-unix"
[ -e "\$PULSE_SOCK" ] && BINDS="\$BINDS --bind \$PULSE_SOCK:/tmp/pulse-socket"

echo ">>> Starting XFCE Desktop..."
proot-distro login ${DISTRO} \$BINDS -- su - ${PROOT_USER} -c "

    # Export display and accessibility (suppress warnings)
    export DISPLAY=:0
    export NO_AT_BRIDGE=1

    # Fix XDG_RUNTIME_DIR permission issue
    export XDG_RUNTIME_DIR=/tmp/xdg-${PROOT_USER}
    mkdir -p \$XDG_RUNTIME_DIR
    chmod 700 \$XDG_RUNTIME_DIR

    # Start fresh session
    dbus-run-session startxfce4
"
XFCEOF

# --- Kill Script 1: Kill X11 & Audio (Termux Side) ---
cat > ~/.shortcuts/kill-x11.sh << 'KILLX11EOF'
#!/data/data/com.termux/files/usr/bin/bash
echo ">>> Stopping X11 and PulseAudio..."
pkill -9 -f "termux-x11" 2>/dev/null || true
pkill -9 -f "pulseaudio" 2>/dev/null || true

TERMUX_TMP="${TMPDIR:-/data/data/com.termux/files/usr/tmp}"
rm -f /tmp/.X0-lock 2>/dev/null
rm -rf "${TERMUX_TMP}/.X11-unix" 2>/dev/null
rm -f "${TERMUX_TMP}/pulse-socket" 2>/dev/null

echo ">>> X11 and PulseAudio stopped."
KILLX11EOF

# --- Kill Script 2: Kill Proot/XFCE (Termux Side) ---
# Double-quoted heredoc — $DISTRO is baked in at generation.
cat > ~/.shortcuts/kill-proot.sh << KILLPROOTEOF
#!/data/data/com.termux/files/usr/bin/bash
echo ">>> Stopping XFCE and proot sessions..."

# Kill desktop processes (leaf first, then session managers)
pkill -9 -f "thunar" 2>/dev/null || true
pkill -9 -f "xfce4-panel" 2>/dev/null || true
pkill -9 -f "xfce4-terminal" 2>/dev/null || true
pkill -9 -f "xfwm4" 2>/dev/null || true
pkill -9 -f "xfce4-session" 2>/dev/null || true
pkill -9 -f "dbus-daemon" 2>/dev/null || true
pkill -9 -f "proot-distro" 2>/dev/null || true
pkill -9 -f "proot --" 2>/dev/null || true

# Clean temp inside rootfs (preserves all config files)
ROOTFS="/data/data/com.termux/files/usr/var/lib/proot-distro/installed-rootfs/${DISTRO}"
if [ -d "\$ROOTFS/tmp" ]; then
    echo "  [*] Cleaning temp and session cache..."
    rm -rf "\$ROOTFS/tmp/.X"* 2>/dev/null
    rm -rf "\$ROOTFS/tmp/dbus-"* 2>/dev/null
    rm -rf "\$ROOTFS/tmp/ssh-"* 2>/dev/null
    rm -f "\$ROOTFS/tmp/.dbus"* 2>/dev/null
    
    # Clean corrupt XFCE sessions to ensure fresh start (does NOT delete user config)
    rm -rf "\$ROOTFS/home/${PROOT_USER}/.cache/sessions/"* 2>/dev/null
fi

echo ">>> Proot sessions stopped, temp and cache cleaned."
KILLPROOTEOF

chmod +x ~/.shortcuts/start-x11.sh ~/.shortcuts/start-xfce.sh ~/.shortcuts/kill-x11.sh ~/.shortcuts/kill-proot.sh

# Create symlinks in home directory for terminal usage
ln -sf ~/.shortcuts/start-x11.sh ~/start-x11.sh
ln -sf ~/.shortcuts/start-xfce.sh ~/start-xfce.sh
ln -sf ~/.shortcuts/kill-x11.sh ~/kill-x11.sh
ln -sf ~/.shortcuts/kill-proot.sh ~/kill-proot.sh

echo ""
echo "=========================================="
echo " SETUP COMPLETE (Widget Support, v8.0)"
echo ""
echo " Start:"
echo "   1. bash ~/start-x11.sh"
echo "   2. Open Termux:X11 app"
echo "   3. bash ~/start-xfce.sh  (in new tab)"
echo ""
echo " Stop:"
echo "   bash ~/kill-proot.sh   (stop XFCE/proot)"
echo "   bash ~/kill-x11.sh     (stop X11/audio)"
echo ""
echo " User: ${PROOT_USER} / Pass: ${PROOT_PASS}"
echo "=========================================="
