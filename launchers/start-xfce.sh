#!/data/data/com.termux/files/usr/bin/bash
TERMUX_TMP="${TMPDIR:-/data/data/com.termux/files/usr/tmp}"

# Build bind mounts
BINDS=""
[ -d "/storage/emulated/0" ] && BINDS="$BINDS --bind /storage/emulated/0:/sdcard"

echo ">>> Starting XFCE Desktop..."
# shellcheck disable=SC2086,SC2016
proot-distro login droiddesk --shared-tmp $BINDS -- env \
    DISPLAY=:0 \
    PULSE_SERVER=tcp:127.0.0.1:4713 \
    LIBGL_ALWAYS_SOFTWARE=1 \
    NO_AT_BRIDGE=1 \
    bash -c '
        # Clean stale dbus sessions
        rm -f /tmp/dbus-* 2>/dev/null
        
        # Disable compositing (proot no GPU → black screen)
        xfwm4 --compositor=off --replace &
        sleep 1
        
        # Start XFCE session
        dbus-launch --exit-with-session xfce4-session
    '
