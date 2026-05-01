#!/data/data/com.termux/files/usr/bin/bash
# proot-xfce-setup.sh (Audio Focused, No GPU)
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
        fonts-noto pulseaudio-utils libgl1 mesa-utils

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

    # --- PulseAudio Client Config (TCP) ---
    mkdir -p /home/${PROOT_USER}/.pulse
    cat > /home/${PROOT_USER}/.pulse/client.conf << 'PULSEEOF'
default-server = 127.0.0.1
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


# Start PulseAudio
echo ">>> Starting PulseAudio..."
pulseaudio --start --exit-idle-time=-1

# Load Audio Sinks (Try AAudio then SLES)
pactl load-module module-aaudio-sink 2>/dev/null || pactl load-module module-sles-sink 2>/dev/null

# Load TCP Protocol for Proot Access
pactl load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1 2>/dev/null

# Start X11
echo ">>> Starting Termux-X11..."
termux-x11 :0 -ac &
sleep 2

# Auto-open the Termux:X11 Android App
echo ">>> Switching to Termux:X11 App..."
am start -n com.termux.x11/com.termux.x11.MainActivity 2>/dev/null || true

echo ""
echo ">>> X11/TCP Audio Ready."
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

    # Set Audio to Host TCP
    export PULSE_SERVER=127.0.0.1

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

# Kill X11 server
if pkill -f "termux-x11" 2>/dev/null; then
    echo "  [x] termux-x11 killed"
else
    echo "  [-] termux-x11 not running"
fi

# Kill PulseAudio
if pkill "pulseaudio" 2>/dev/null; then
    echo "  [x] pulseaudio killed"
    sleep 1
else
    echo "  [-] pulseaudio not running"
fi

# Cleanup stale files (Termux tmp, not /tmp)
TERMUX_TMP="${TMPDIR:-/data/data/com.termux/files/usr/tmp}"
rm -f "${TERMUX_TMP}/.X0-lock" 2>/dev/null
rm -rf "${TERMUX_TMP}/.X11-unix" 2>/dev/null
rm -f "${TERMUX_TMP}/pulse-socket" 2>/dev/null

echo ">>> X11 and PulseAudio stopped."
KILLX11EOF

# --- Kill Script 2: Kill Proot/XFCE (Termux Side) ---
# Double-quoted heredoc — $DISTRO and $PROOT_USER are baked in at generation.
cat > ~/.shortcuts/kill-proot.sh << KILLPROOTEOF
#!/data/data/com.termux/files/usr/bin/bash
echo ">>> Stopping XFCE and proot sessions..."

# Kill desktop processes — leaf apps first, session managers last
XFCE_PROCS="thunar xfdesktop4 xfce4-panel xfce4-terminal xfwm4 xfce4-session"
for proc in \$XFCE_PROCS; do
    if pkill -f "\$proc" 2>/dev/null; then
        echo "  [x] \$proc killed"
    fi
done

# Kill dbus session daemon (spawned by dbus-run-session)
pkill -f "dbus-daemon --nofork --session" 2>/dev/null && echo "  [x] dbus-daemon killed" || true

# Kill proot-distro login session (specific match to avoid killing other proot jobs)
pkill -f "proot-distro login ${DISTRO}" 2>/dev/null && echo "  [x] proot-distro killed" || true

# Kill orphan proot processes tied to the distro rootfs
pkill -f "proot.*installed-rootfs/${DISTRO}" 2>/dev/null && echo "  [x] orphan proot killed" || true

# Short wait to let processes terminate cleanly
sleep 1

# Force-kill anything that survived graceful shutdown
for proc in \$XFCE_PROCS; do
    pkill -9 -f "\$proc" 2>/dev/null || true
done
pkill -9 -f "proot.*installed-rootfs/${DISTRO}" 2>/dev/null || true

# Clean temp inside rootfs (preserves all config files)
ROOTFS="/data/data/com.termux/files/usr/var/lib/proot-distro/installed-rootfs/${DISTRO}"
if [ -d "\$ROOTFS/tmp" ]; then
    echo "  [*] Cleaning temp and session cache..."
    rm -rf "\$ROOTFS/tmp/.X"* 2>/dev/null
    rm -rf "\$ROOTFS/tmp/dbus-"* 2>/dev/null
    rm -rf "\$ROOTFS/tmp/ssh-"* 2>/dev/null
    rm -f "\$ROOTFS/tmp/.dbus"* 2>/dev/null
    rm -rf "\$ROOTFS/tmp/xdg-${PROOT_USER}" 2>/dev/null
    
    # Clean corrupt XFCE sessions to ensure fresh start (does NOT delete user config)
    rm -rf "\$ROOTFS/home/${PROOT_USER}/.cache/sessions/"* 2>/dev/null
fi

echo ">>> Proot sessions stopped, temp and cache cleaned."
KILLPROOTEOF

# --- Kill Script 3: Kill ALL (Convenience — runs both kill scripts) ---
cat > ~/.shortcuts/kill-all.sh << 'KILLALLEOF'
#!/data/data/com.termux/files/usr/bin/bash
echo ">>> Stopping ALL DroidDesk services..."
echo ""
bash ~/.shortcuts/kill-proot.sh
echo ""
bash ~/.shortcuts/kill-x11.sh
echo ""
echo ">>> All DroidDesk services stopped."
KILLALLEOF

# --- Launcher 5: Auto-Updater ---
cat > ~/.shortcuts/update-droiddesk.sh << 'UPDATEEOF'
#!/data/data/com.termux/files/usr/bin/bash
echo ">>> Updating DroidDesk..."
cd ~
rm -f proot-xfce-setup.sh.new
curl -sL "https://raw.githubusercontent.com/arinadi/DroidDesk/main/proot-xfce-setup.sh?v=$(date +%s)" -o proot-xfce-setup.sh.new

if [ -s proot-xfce-setup.sh.new ]; then
    chmod +x proot-xfce-setup.sh.new
    mv -f proot-xfce-setup.sh.new proot-xfce-setup.sh
    echo ">>> Update successful. Running setup..."
    ./proot-xfce-setup.sh
else
    echo "ERROR: Download failed. Check your internet connection."
    rm -f proot-xfce-setup.sh.new
    exit 1
fi
UPDATEEOF

chmod +x ~/.shortcuts/start-x11.sh ~/.shortcuts/start-xfce.sh ~/.shortcuts/kill-x11.sh ~/.shortcuts/kill-proot.sh ~/.shortcuts/kill-all.sh ~/.shortcuts/update-droiddesk.sh

# Create symlinks in home directory for terminal usage
ln -sf ~/.shortcuts/start-x11.sh ~/start-x11.sh
ln -sf ~/.shortcuts/start-xfce.sh ~/start-xfce.sh
ln -sf ~/.shortcuts/kill-x11.sh ~/kill-x11.sh
ln -sf ~/.shortcuts/kill-proot.sh ~/kill-proot.sh
ln -sf ~/.shortcuts/kill-all.sh ~/kill-all.sh
ln -sf ~/.shortcuts/update-droiddesk.sh ~/update-droiddesk.sh

# --- Termux MOTD Update ---
cat > /data/data/com.termux/files/usr/etc/motd << MOTDEOF

==========================================
 📱 DroidDesk Proot XFCE
==========================================

 Start:
   1. bash ~/start-x11.sh
   2. Open Termux:X11 app
   3. bash ~/start-xfce.sh  (in new tab)

 Stop/Update:
    bash ~/kill-all.sh         (stop ALL)
    bash ~/kill-proot.sh       (stop XFCE only)
    bash ~/kill-x11.sh         (stop X11/Audio only)
    bash ~/update-droiddesk.sh (update)

 User: ${PROOT_USER} / Pass: ${PROOT_PASS}
==========================================
MOTDEOF

echo ""
echo "=========================================="
echo " SETUP COMPLETE (Widget Support)"
echo ""
echo " Start:"
echo "   1. bash ~/start-x11.sh"
echo "   2. Open Termux:X11 app"
echo "   3. bash ~/start-xfce.sh  (in new tab)"
echo ""
echo " Stop/Update:"
echo "   bash ~/kill-all.sh         (stop ALL)"
echo "   bash ~/kill-proot.sh       (stop XFCE/proot only)"
echo "   bash ~/kill-x11.sh         (stop X11/audio only)"
echo "   bash ~/update-droiddesk.sh (update scripts)"
echo ""
echo " User: ${PROOT_USER} / Pass: ${PROOT_PASS}"
echo "=========================================="
