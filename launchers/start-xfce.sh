#!/data/data/com.termux/files/usr/bin/bash
echo ">>> Starting XFCE Desktop..."
proot-distro login droiddesk --shared-tmp -- env \
    DISPLAY=:0 \
    PULSE_SERVER=tcp:127.0.0.1:4713 \
    LIBGL_ALWAYS_SOFTWARE=1 \
    NO_AT_BRIDGE=1 \
    bash -c '
        rm -f /tmp/dbus-* 2>/dev/null
        dbus-launch --exit-with-session xfce4-session
    '
