#!/data/data/com.termux/files/usr/bin/bash
# ═══════════════════════════════════════════════════════════════
# arinanoX — Start (unified launcher)
#  PulseAudio → X11 → virgl (auto) → XFCE desktop
# ═══════════════════════════════════════════════════════════════
set -euo pipefail

TERMUX_TMP="${TMPDIR:-/data/data/com.termux/files/usr/tmp}"

# ── PulseAudio ──────────────────────────────────────────────
echo ">>> [1/4] PulseAudio..."
pulseaudio --start --exit-idle-time=-1
pactl load-module module-aaudio-sink 2>/dev/null || pactl load-module module-sles-sink 2>/dev/null || true
pactl load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1 port=4713 2>/dev/null || true
echo "  ✓ PulseAudio ready"

# ── Termux:API Bridge ───────────────────────────────────────
echo ">>> [2/4] Termux:API Bridge..."
termux-wake-lock
pkill -f run-api-bridge.sh 2>/dev/null || true
bash ~/run-api-bridge.sh > /dev/null 2>&1 &
echo "  ✓ API bridge started"

# ── Termux:X11 ──────────────────────────────────────────────
echo ">>> [3/4] X11 Server..."
export XDG_RUNTIME_DIR="$TERMUX_TMP"
termux-x11 :0 -ac &
sleep 2
am start -n com.termux.x11/com.termux.x11.MainActivity 2>/dev/null || true
echo "  ✓ X11 running"

# ── virgl GPU (auto-detect) ─────────────────────────────────
echo ">>> [4/4] Desktop..."
VIRGL_SOCKET="/data/data/com.termux/files/usr/tmp/.virgl_test"

if command -v virgl_test_server_android &>/dev/null; then
    echo "  ✓ virglrenderer detected — starting GPU server..."
    virgl_test_server_android &>/dev/null &
    sleep 1
    USE_VIRGL=1
else
    echo "  • virglrenderer not installed (CPU rendering only)"
    use_virgl=0
fi

# ── XFCE Desktop ────────────────────────────────────────────
if [ "${USE_VIRGL:-0}" -eq 1 ]; then
    echo "  ✓ Launching XFCE with GPU acceleration..."
    proot-distro login arinanox --shared-tmp -- su - admin -c '
        export DISPLAY=:0
        export PULSE_SERVER=tcp:127.0.0.1:4713
        export NO_AT_BRIDGE=1
        export GALLIUM_DRIVER=virpipe
        export MESA_GL_VERSION_OVERRIDE=3.3
        rm -f /tmp/dbus-* 2>/dev/null
        dbus-launch --exit-with-session xfce4-session
    '
else
    echo "  ✓ Launching XFCE (CPU rendering)..."
    proot-distro login arinanox --shared-tmp -- su - admin -c '
        export DISPLAY=:0
        export PULSE_SERVER=tcp:127.0.0.1:4713
        export NO_AT_BRIDGE=1
        export LIBGL_ALWAYS_SOFTWARE=1
        rm -f /tmp/dbus-* 2>/dev/null
        dbus-launch --exit-with-session xfce4-session
    '
fi

echo ">>> arinanoX desktop ended."
