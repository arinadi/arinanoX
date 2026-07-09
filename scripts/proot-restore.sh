#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

# proot-restore.sh — Restore user layer on top of fresh image
# Restores: home directory + user-installed packages

CONTAINER="droiddesk"
BACKUP_DIR="$HOME/.droiddesk/backups"
ROOTFS="/data/data/com.termux/files/usr/var/lib/proot-distro/containers/${CONTAINER}/rootfs"

LATEST_PKG="${BACKUP_DIR}/packages-latest.txt"
LATEST_HOME="${BACKUP_DIR}/home-latest.tar.gz"

if [ ! -f "$LATEST_PKG" ] || [ ! -f "$LATEST_HOME" ]; then
    echo ">>> No backup found. Using image defaults."
    exit 0
fi

echo ">>> Restoring user layer..."
echo ">>> Home: $LATEST_HOME"
echo ">>> Packages: $LATEST_PKG"

# 1. Restore home directory (user's configs override image defaults)
cp "$LATEST_HOME" "${ROOTFS}/tmp/proot-home.tar.gz"
proot-distro login "$CONTAINER" -- bash -c "
    tar xzf /tmp/proot-home.tar.gz -C /home/ 2>/dev/null || true
    chown -R admin:admin /home/admin
"
rm -f "${ROOTFS}/tmp/proot-home.tar.gz"

# 2. Reinstall user packages (on top of image base)
cp "$LATEST_PKG" "${ROOTFS}/tmp/packages.txt"
proot-distro login "$CONTAINER" -- bash -c "
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -q
    xargs -a /tmp/packages.txt apt-get install -y -q 2>/dev/null || true
    apt-get clean
    rm -f /tmp/packages.txt
"

# 3. Re-apply storage symlinks (not in image, not in backup)
proot-distro login "$CONTAINER" -- su - admin -c "
    ln -sf /sdcard/Download ~/Downloads 2>/dev/null || true
    ln -sf /sdcard/DCIM/Camera ~/Pictures 2>/dev/null || true
    ln -sf /sdcard ~/Android_Internal 2>/dev/null || true
"

echo ">>> User layer restored."
