#!/data/data/com.termux/files/usr/bin/bash
# ========================================================
# Proot XFCE Setup Script
#
# Installs XFCE inside a selected proot distro instead of the
# Termux root environment, then creates a start wrapper for
# launching XFCE via Termux-X11.
# ========================================================

set -e

if [ -z "$PREFIX" ]; then
    echo "[!] This script must be run inside Termux."
    exit 1
fi

if ! command -v pkg >/dev/null 2>&1; then
    echo "[!] pkg command not found. Run this from Termux."
    exit 1
fi

install_termux_pkg() {
    local pkgname="$1"
    echo "[+] Installing Termux package: $pkgname"
    pkg install -y "$pkgname"
}

show_banner() {
    clear
    cat <<'BANNER'
==========================================================
  Proot XFCE Setup
  Install XFCE in selected proot distro, not in Termux root.
==========================================================
BANNER
    echo
}

select_distro() {
    echo "Choose a proot distro to install XFCE into:"
    echo "  1) Ubuntu 22.04 LTS (recommended)"
    echo "  2) Debian 12"
    echo "  3) Kali Linux"
    echo
    while true; do
        read -p "Enter number (1-3) [default: 1]: " choice
        choice=${choice:-1}
        case "$choice" in
            1) PROOT_DISTRO="ubuntu"; PROOT_LABEL="Ubuntu 22.04"; break;;
            2) PROOT_DISTRO="debian"; PROOT_LABEL="Debian 12"; break;;
            3) PROOT_DISTRO="kali-nethunter"; PROOT_LABEL="Kali Linux"; break;;
            *) echo "Please enter 1, 2, or 3.";;
        esac
    done
    echo
    echo "[+] Selected proot distro: $PROOT_LABEL"
    echo
}

install_base() {
    echo "[+] Updating Termux package lists..."
    pkg update -y

    echo "[+] Enabling X11 repository (needed for Termux-X11)."
    install_termux_pkg "x11-repo"

    echo "[+] Installing Termux X11 display support and proot manager."
    install_termux_pkg "termux-x11-nightly"
    install_termux_pkg "proot"
    install_termux_pkg "proot-distro"
}

install_proot_distro() {
    echo "[+] Installing $PROOT_LABEL rootfs..."
    proot-distro install "$PROOT_DISTRO"
    echo "[+] Rootfs installed: $PROOT_DISTRO"
}

install_xfce_in_distro() {
    echo "[+] Bootstrapping XFCE inside $PROOT_LABEL..."
    proot-distro login "$PROOT_DISTRO" -- bash -lc '
        set -e
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -y -q
        apt-get install -y -q --no-install-recommends \
            xfce4 xfce4-terminal thunar dbus-x11 xauth xinit sudo curl wget git nano \
            > /dev/null 2>&1
    '
    echo "[+] XFCE installed in $PROOT_LABEL."
}

create_start_wrappers() {
    cat > "$HOME/start-x11.sh" <<EOF
#!/data/data/com.termux/files/usr/bin/bash
# Start Termux:X11 display server only.
echo "[+] Starting Termux-X11 display server on :1"
termux-x11 :1 -ac &
echo "[+] Termux-X11 started on DISPLAY=:1"
EOF
    chmod +x "$HOME/start-x11.sh"

    cat > "$HOME/start-proot-xfce.sh" <<EOF
#!/data/data/com.termux/files/usr/bin/bash
# ============================================
#   XFCE4 Proot Launcher - Termux X11
#   Fix: WM, libGL, cursor, dbus, session
# ============================================

PROOT_DISTRO="$PROOT_DISTRO"
TERMUX_TMP="${TMPDIR:-/data/data/com.termux/files/usr/tmp}"

BINDS=""
[ -d "$TERMUX_TMP/.X11-unix" ] && BINDS="$BINDS --bind $TERMUX_TMP/.X11-unix:/tmp/.X11-unix"
[ -d "/dev/dri" ] && BINDS="$BINDS --bind /dev/dri:/dev/dri"
[ -e "/dev/kgsl-3d0" ] && BINDS="$BINDS --bind /dev/kgsl-3d0:/dev/kgsl-3d0"

echo "╔══════════════════════════════════════╗"
echo "║   XFCE4 Proot Launcher - Termux X11  ║"
echo "╚══════════════════════════════════════╝"
echo "[*] Distro : $PROOT_DISTRO"
echo "[*] Display: :1"
echo ""

# ── Install dependencies jika belum ada ──
echo "[1/3] Checking & installing dependencies..."
proot-distro login "$PROOT_DISTRO" --shared-tmp $BINDS -- /bin/bash -c '
    MISSING=""
    command -v xfwm4 >/dev/null 2>&1 || MISSING="$MISSING xfwm4"
    [ -f /usr/lib/x86_64-linux-gnu/libGL.so.1 ] || \
    [ -f /usr/lib/aarch64-linux-gnu/libGL.so.1 ] || \
    [ -f /usr/lib/arm-linux-gnueabihf/libGL.so.1 ] || MISSING="$MISSING libgl1 libgl1-mesa-dri"
    command -v xsetroot >/dev/null 2>&1 || MISSING="$MISSING x11-xserver-utils"
    dpkg -l dmz-cursor-theme >/dev/null 2>&1 || MISSING="$MISSING dmz-cursor-theme"

    if [ -n "$MISSING" ]; then
        echo "[!] Installing:$MISSING"
        apt-get install -y $MISSING -qq 2>/dev/null
    else
        echo "[✓] Dependencies OK"
    fi

    # Fix libGL symlink jika missing
    for dir in /usr/lib/aarch64-linux-gnu /usr/lib/x86_64-linux-gnu /usr/lib/arm-linux-gnueabihf; do
        if [ -f "$dir/libGL.so.1.7.0" ] && [ ! -f "$dir/libGL.so.1" ]; then
            ln -sf "$dir/libGL.so.1.7.0" "$dir/libGL.so.1"
        fi
    done

    # Fix wallpaper
    mkdir -p /usr/share/xfce4/backdrops
    if [ ! -f /usr/share/xfce4/backdrops/xubuntu-wallpaper.png ]; then
        WALL=$(find /usr/share/wallpapers /usr/share/backgrounds /usr/share/pixmaps -name "*.png" 2>/dev/null | head -1)
        if [ -n "$WALL" ]; then
            cp "$WALL" /usr/share/xfce4/backdrops/xubuntu-wallpaper.png
            echo "[✓] Wallpaper: $WALL"
        else
            # Buat wallpaper solid jika tidak ada sama sekali
            apt-get install -y imagemagick -qq 2>/dev/null
            convert -size 1920x1080 xc:#1e1e2e /usr/share/xfce4/backdrops/xubuntu-wallpaper.png 2>/dev/null
            echo "[✓] Wallpaper: generated"
        fi
    else
        echo "[✓] Wallpaper OK"
    fi

    # Fix pm-is-supported agar tidak error
    if [ ! -f /usr/bin/pm-is-supported ]; then
        echo "#!/bin/bash\nexit 1" > /usr/bin/pm-is-supported
        chmod +x /usr/bin/pm-is-supported
        echo "[✓] pm-is-supported: created dummy"
    fi
' 2>/dev/null

# ── Bersihkan sisa sesi lama ──
echo "[2/3] Cleaning old session..."
proot-distro login "$PROOT_DISTRO" --shared-tmp $BINDS -- /bin/bash -c '
    rm -f /tmp/.dbus-*
    rm -f /tmp/.ICE-unix/*
    rm -f /run/dbus/pid
    rm -f /tmp/xdg-runtime/.dbus-*
    # Reset xfce4-session lock agar tidak skip start
    rm -f ~/.cache/xfce4/xfce4-session/xfce4-session.verbose-log
    rm -f ~/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-session.xml 2>/dev/null
' 2>/dev/null

echo "[✓] Cleanup done"

# ── Start XFCE4 ──
echo "[3/3] Starting XFCE4..."
echo ""

proot-distro login "$PROOT_DISTRO" --shared-tmp $BINDS -- /bin/bash -c '
    # ── Exports ──
    export DISPLAY=:1
    export TMPDIR=/tmp
    export XDG_RUNTIME_DIR=/tmp/xdg-runtime
    export NO_AT_BRIDGE=1
    export LIBGL_ALWAYS_SOFTWARE=1
    export MESA_NO_ERROR=1
    export MESA_GL_VERSION_OVERRIDE=4.6
    export MESA_GLES_VERSION_OVERRIDE=3.2
    export GALLIUM_DRIVER=zink
    export MESA_LOADER_DRIVER_OVERRIDE=zink
    export XCURSOR_THEME=DMZ-White
    export XCURSOR_SIZE=24

    mkdir -p /tmp/xdg-runtime
    chmod 700 /tmp/xdg-runtime

    # ── Start dbus system ──
    mkdir -p /run/dbus
    rm -f /run/dbus/pid
    dbus-daemon --system --fork 2>/dev/null
    sleep 0.5

    # ── Set default cursor ──
    xsetroot -cursor_name left_ptr 2>/dev/null

    # ── Start XFCE session via dbus ──
    exec dbus-launch --exit-with-session xfce4-session 2>&1 | grep -v \
        -e "systemd proxy" \
        -e "_NET_NUMBER_OF_DESKTOPS" \
        -e "_NET_WORKAREA" \
        -e "_NET_CURRENT_DESKTOP" \
        -e "No GPG agent" \
        -e "No SSH authentication" \
        -e "AT-SPI" \
        -e "pm-is-supported" \
        -e "DPMS"
'
EOF
    chmod +x "$HOME/start-proot-xfce.sh"

    cat > "$HOME/start-proot.sh" <<EOF
#!/data/data/com.termux/files/usr/bin/bash
PROOT_DISTRO="$PROOT_DISTRO"
TERMUX_TMP="${TMPDIR:-/data/data/com.termux/files/usr/tmp}"

BINDS=""
[ -d "$TERMUX_TMP/.X11-unix" ] && BINDS="$BINDS --bind $TERMUX_TMP/.X11-unix:/tmp/.X11-unix"
[ -d "/dev/dri" ] && BINDS="$BINDS --bind /dev/dri:/dev/dri"
[ -e "/dev/kgsl-3d0" ] && BINDS="$BINDS --bind /dev/kgsl-3d0:/dev/kgsl-3d0"

echo "[+] Starting Proot shell in distro: $PROOT_DISTRO"
proot-distro login "$PROOT_DISTRO" --shared-tmp $BINDS -- /bin/bash
EOF
    chmod +x "$HOME/start-proot.sh"

    cat > "$HOME/stop-linux.sh" <<EOF
#!/data/data/com.termux/files/usr/bin/bash
# Stop Termux-X11 and any running desktop/proot sessions.
pkill -9 termux-x11 2>/dev/null
pkill -9 -f "Xvnc" 2>/dev/null
pkill -9 -f "pulseaudio" 2>/dev/null
pkill -9 -f "dbus" 2>/dev/null
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1 2>/dev/null
EOF
    chmod +x "$HOME/stop-linux.sh"

    echo "[+] Created ~/start-x11.sh, ~/start-proot-xfce.sh, ~/start-proot.sh, and ~/stop-linux.sh"
}

show_banner
select_distro
install_base
install_proot_distro
install_xfce_in_distro
create_start_wrappers

echo
echo "=========================================================="
echo "Setup complete!"
echo "1) Run the Termux-X11 app on your phone."
echo "2) Start the X11 server only: bash ~/start-x11.sh"
echo "3) Then start the XFCE session inside Proot: bash ~/start-proot-xfce.sh"
echo "4) Start the Proot shell: bash ~/start-proot.sh"
echo "5) Stop desktop or sessions: bash ~/stop-linux.sh"
echo "=========================================================="
