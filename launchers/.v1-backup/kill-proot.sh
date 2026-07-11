#!/data/data/com.termux/files/usr/bin/bash
echo ">>> Stopping XFCE and proot sessions..."

# Kill desktop processes — leaf apps first, session managers last
XFCE_PROCS="thunar xfdesktop4 xfce4-panel xfce4-terminal xfwm4 xfce4-session"
for proc in $XFCE_PROCS; do
    if pkill -f "$proc" 2>/dev/null; then
        echo "  [x] $proc killed"
    fi
done

# Kill dbus session daemon (spawned by dbus-run-session)
pkill -f "dbus-daemon --nofork --session" 2>/dev/null && echo "  [x] dbus-daemon killed" || true

# Kill proot-distro login session (specific match to avoid killing other proot jobs)
pkill -f "proot-distro login arinanox" 2>/dev/null && echo "  [x] proot-distro killed" || true

# Kill orphan proot processes tied to the distro rootfs
pkill -f "proot.*installed-rootfs/arinanox" 2>/dev/null && echo "  [x] orphan proot killed" || true

# Short wait to let processes terminate cleanly
sleep 1

# Force-kill anything that survived graceful shutdown
for proc in $XFCE_PROCS; do
    pkill -9 -f "$proc" 2>/dev/null || true
done
pkill -9 -f "proot.*installed-rootfs/arinanox" 2>/dev/null || true

# Aggressive Inner Cleanup (Handles residues even if host cleanup fails)
echo "  [*] Performing deep residue cleanup inside proot..."
proot-distro login arinanox -- bash -c "rm -rf /tmp/xdg-* /tmp/dbus-* /tmp/.xfsm-ICE-* /tmp/.X11-unix/* /home/admin/.cache/sessions/* /home/admin/.ICEauthority /home/admin/.Xauthority 2>/dev/null"

# Clean temp and session cache inside rootfs from host side (Double Layer)
ROOTFS="/data/data/com.termux/files/usr/var/lib/proot-distro/containers/arinanox/rootfs"
if [ -d "$ROOTFS" ]; then
    echo "  [*] Cleaning host-side mounts and temp files..."
    rm -rf "$ROOTFS/tmp/.X"* 2>/dev/null
    rm -rf "$ROOTFS/tmp/.xfsm-ICE-"* 2>/dev/null
    rm -rf "$ROOTFS/tmp/dbus-"* 2>/dev/null
    rm -rf "$ROOTFS/tmp/ssh-"* 2>/dev/null
    rm -f "$ROOTFS/tmp/.dbus"* 2>/dev/null
    rm -rf "$ROOTFS/tmp/xdg-"* 2>/dev/null

    # Clean corrupt XFCE sessions and authority files
    rm -rf "$ROOTFS/home/admin/.cache/sessions/"* 2>/dev/null
    rm -f "$ROOTFS/home/admin/.ICEauthority" 2>/dev/null
    rm -f "$ROOTFS/home/admin/.Xauthority" 2>/dev/null
fi

echo ">>> Proot sessions stopped, temp and cache cleaned."
