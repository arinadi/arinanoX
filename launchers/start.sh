#!/data/data/com.termux/files/usr/bin/bash
# ═══════════════════════════════════════════════════════════════
# arinanoX — Start (unified launcher)
#  Parallel: PulseAudio + virgl + X11 → XFCE desktop
# ═══════════════════════════════════════════════════════════════
set -euo pipefail

TMPDIR="${TMPDIR:-/data/data/com.termux/files/usr/tmp}"
ANGLE_DIR="/data/data/com.termux/files/usr/opt/angle-android"
X11_SOCK="${TMPDIR}/.X11-unix/X0"

# ── [1/3] Start all services in parallel ────────────────────
echo ">>> [1/3] Starting services..."

# PulseAudio
pulseaudio --start --exit-idle-time=-1 2>/dev/null &
PA_PID=$!
pactl load-module module-aaudio-sink 2>/dev/null || \
pactl load-module module-sles-sink 2>/dev/null || true
pactl load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 \
    auth-anonymous=1 port=4713 2>/dev/null || true

# API Bridge
pkill -f run-api-bridge.sh 2>/dev/null || true
bash ~/run-api-bridge.sh &>/dev/null &

# virgl (auto-detect) — start in background
VIRGL_MODE="cpu"
if command -v virgl_test_server_android &>/dev/null; then
    virgl_test_server_android &>/dev/null &
    VIRGL_MODE="android"
elif command -v virgl_test_server &>/dev/null && [ -d "${ANGLE_DIR}/vulkan-null" ]; then
    LD_LIBRARY_PATH="${ANGLE_DIR}/vulkan-null" \
        virgl_test_server --use-egl-surfaceless --use-gles &>/dev/null &
    VIRGL_MODE="angle-vulkan-null"
elif command -v virgl_test_server &>/dev/null && [ -d "${ANGLE_DIR}/vulkan" ]; then
    LD_LIBRARY_PATH="${ANGLE_DIR}/vulkan" \
        virgl_test_server --use-egl-surfaceless --use-gles &>/dev/null &
    VIRGL_MODE="angle-vulkan"
fi

# X11
export XDG_RUNTIME_DIR="$TMPDIR"
termux-x11 :0 -ac &
X11_PID=$!

# Wake lock
termux-wake-lock

# Switch to X11 app (background — don't block)
am start -n com.termux.x11/com.termux.x11.MainActivity &>/dev/null &

echo "  PulseAudio + API + virgl($VIRGL_MODE) + X11 started"

# ── [2/3] Wait for X11 socket ───────────────────────────────
echo ">>> [2/3] Waiting for X11..."
for i in $(seq 1 30); do
    [ -S "$X11_SOCK" ] && break
    sleep 0.1
done
[ -S "$X11_SOCK" ] && echo "  ✓ X11 ready ($(busybox expr $i \* 100)ms)" || \
    echo "  ⚠ X11 socket timeout, proceeding anyway..."

# ── [3/3] XFCE Desktop ──────────────────────────────────────
echo ">>> [3/3] Launching desktop..."

if [ "$VIRGL_MODE" != "cpu" ]; then
    echo "  ✓ GPU mode: ${VIRGL_MODE}"
    proot-distro login arinanox --shared-tmp -- su - admin -c "
        export DISPLAY=:0
        export PULSE_SERVER=tcp:127.0.0.1:4713
        export NO_AT_BRIDGE=1
        export GALLIUM_DRIVER=virpipe
        export MESA_GL_VERSION_OVERRIDE=4.1COMPAT
        export MESA_GLES_VERSION_OVERRIDE=3.1
        export MESA_NO_ERROR=1
        export MESA_BACK_BUFFER=pixmap
        rm -f /tmp/dbus-* 2>/dev/null
        dbus-launch --exit-with-session xfce4-session
    "
else
    echo "  • CPU mode"
    proot-distro login arinanox --shared-tmp -- su - admin -c "
        export DISPLAY=:0
        export PULSE_SERVER=tcp:127.0.0.1:4713
        export NO_AT_BRIDGE=1
        export LIBGL_ALWAYS_SOFTWARE=1
        rm -f /tmp/dbus-* 2>/dev/null
        dbus-launch --exit-with-session xfce4-session
    "
fi

echo ">>> arinanoX desktop ended."
