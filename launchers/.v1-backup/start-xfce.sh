#!/data/data/com.termux/files/usr/bin/bash
echo ">>> Starting XFCE Desktop..."
proot-distro login arinanox --shared-tmp -- su - admin -c '
    export DISPLAY=:0
    export PULSE_SERVER=tcp:127.0.0.1:4713
    export LIBGL_ALWAYS_SOFTWARE=1
    export NO_AT_BRIDGE=1
    rm -f /tmp/dbus-* 2>/dev/null
    dbus-launch --exit-with-session xfce4-session
'
