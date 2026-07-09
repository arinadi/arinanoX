#!/data/data/com.termux/files/usr/bin/bash
TERMUX_TMP="${TMPDIR:-/data/data/com.termux/files/usr/tmp}"
export XDG_RUNTIME_DIR="$TERMUX_TMP"

# Start PulseAudio
echo ">>> Starting PulseAudio..."
pulseaudio --start --exit-idle-time=-1

# Load Audio Sinks (Try AAudio then SLES)
pactl load-module module-aaudio-sink 2>/dev/null || pactl load-module module-sles-sink 2>/dev/null

# Load TCP Protocol for Proot Access
pactl load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1 port=4713 2>/dev/null

# Start Termux:API Bridge
echo ">>> Starting Termux:API Bridge..."
termux-wake-lock
pkill -f run-api-bridge.sh 2>/dev/null
bash ~/run-api-bridge.sh > /dev/null 2>&1 &

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
