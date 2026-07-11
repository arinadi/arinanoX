#!/data/data/com.termux/files/usr/bin/bash
# ═══════════════════════════════════════════════════════════════
# arinanoX — Stop (unified kill)
#  XFCE → proot → virgl → X11 → PulseAudio → cleanup
# ═══════════════════════════════════════════════════════════════

echo ">>> Stopping arinanoX..."

# ── XFCE (graceful first, then force) ───────────────────────
echo "  [*] Killing XFCE processes..."
for proc in thunar xfdesktop xfce4-panel xfce4-terminal xfwm4 xfce4-session; do
    pkill -f "$proc" 2>/dev/null && echo "  [x] $proc" || true
done
sleep 1
for proc in thunar xfdesktop xfce4-panel xfce4-terminal xfwm4 xfce4-session; do
    pkill -9 -f "$proc" 2>/dev/null || true
done

# ── Proot sessions ──────────────────────────────────────────
echo "  [*] Killing proot sessions..."
pkill -f "dbus-daemon --nofork --session" 2>/dev/null && echo "  [x] dbus-daemon" || true
pkill -f "proot-distro login arinanox" 2>/dev/null && echo "  [x] proot login" || true
pkill -f "proot.*installed-rootfs/arinanox" 2>/dev/null && echo "  [x] orphan proot" || true
sleep 0.5
pkill -9 -f "proot.*installed-rootfs/arinanox" 2>/dev/null || true

# ── Clean temp files (inside proot + from host) ────────────
ROOTFS="/data/data/com.termux/files/usr/var/lib/proot-distro/containers/arinanox/rootfs"
if [ -d "$ROOTFS" ]; then
    echo "  [*] Cleaning temp files..."
    rm -rf "$ROOTFS/tmp/"{.X*,dbus-*,ssh-*,xdg-*,xfsm-*} 2>/dev/null || true
    rm -f "$ROOTFS/tmp/.dbus"* 2>/dev/null || true
    rm -rf "$ROOTFS/home/admin/.cache/sessions/"* 2>/dev/null || true
    rm -f "$ROOTFS/home/admin/"{.ICEauthority,.Xauthority} 2>/dev/null || true
fi

# ── virgl server ────────────────────────────────────────────
pkill -f "virgl_test_server" 2>/dev/null && echo "  [x] virgl server" || true

# ── X11 ─────────────────────────────────────────────────────
echo "  [*] Stopping X11..."
pkill -f "termux-x11" 2>/dev/null && echo "  [x] termux-x11" || echo "  [-] X11 not running"
pkill -9 -f "termux-x11" 2>/dev/null || true
rm -f "${TMPDIR:-/data/data/com.termux/files/usr/tmp}/.X0-lock" 2>/dev/null || true
rm -rf "${TMPDIR:-/data/data/com.termux/files/usr/tmp}/.X11-unix" 2>/dev/null || true

# ── PulseAudio ──────────────────────────────────────────────
echo "  [*] Stopping PulseAudio..."
pulseaudio --kill 2>/dev/null && echo "  [x] pulseaudio" || pkill -9 pulseaudio 2>/dev/null || true

# ── API Bridge ──────────────────────────────────────────────
pkill -f run-api-bridge.sh 2>/dev/null && echo "  [x] API bridge" || true

# ── Wake lock ───────────────────────────────────────────────
termux-wake-unlock 2>/dev/null || true

echo ">>> arinanoX stopped. ✓"
