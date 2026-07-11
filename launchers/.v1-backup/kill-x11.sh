#!/data/data/com.termux/files/usr/bin/bash
echo ">>> Stopping X11 and PulseAudio..."

# Kill X11 server
if pkill -f "termux-x11" 2>/dev/null || pkill -f "termux.x11" 2>/dev/null; then
    echo "  [x] termux-x11 killed"
else
    echo "  [-] termux-x11 not running"
fi

# Force kill X11 if still running
pkill -9 -f "termux-x11" 2>/dev/null || true
pkill -9 -f "termux.x11" 2>/dev/null || true

# Kill PulseAudio
if pulseaudio --kill 2>/dev/null; then
    echo "  [x] pulseaudio killed"
else
    pkill -9 "pulseaudio" 2>/dev/null && echo "  [x] pulseaudio force-killed" || echo "  [-] pulseaudio not running"
fi

# Kill Termux:API Bridge
pkill -f run-api-bridge.sh 2>/dev/null && echo "  [x] termux-api bridge killed"

# Release wake lock
termux-wake-unlock 2>/dev/null && echo "  [x] wake lock released"

# Cleanup stale files (Termux tmp, not /tmp)
TERMUX_TMP="${TMPDIR:-/data/data/com.termux/files/usr/tmp}"
rm -f "${TERMUX_TMP}/.X0-lock" 2>/dev/null
rm -rf "${TERMUX_TMP}/.X11-unix" 2>/dev/null
rm -f "${TERMUX_TMP}/pulse-socket" 2>/dev/null

echo ">>> X11 and PulseAudio stopped."
