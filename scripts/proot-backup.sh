#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

# proot-backup.sh — Backup user layer before proot reset
# Saves: installed packages (user-installed only) + home directory

CONTAINER="droiddesk"
BACKUP_DIR="$HOME/.droiddesk/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
ROOTFS="/data/data/com.termux/files/usr/var/lib/proot-distro/containers/${CONTAINER}/rootfs"

mkdir -p "$BACKUP_DIR"

if [ ! -d "$ROOTFS" ]; then
    echo ">>> No container found. Nothing to backup."
    exit 0
fi

echo ">>> Backing up user layer..."

# 1. Package list — only user-installed packages (not image base)
proot-distro login "$CONTAINER" -- bash -c "
    comm -23 <(dpkg --get-selections | grep 'install' | awk '{print \$1}' | sort) \
             <(dpkg --get-selections | grep 'deinstall' | awk '{print \$1}' | sort)" \
    > "${BACKUP_DIR}/packages-${TIMESTAMP}.txt" 2>/dev/null || true

# 2. Home directory (includes user's XFCE config overrides)
proot-distro login "$CONTAINER" -- bash -c "
    tar czf /tmp/proot-home.tar.gz \
        -C /home admin \
        --exclude='.cache' \
        --exclude='__pycache__' \
        --exclude='.local/share/Trash' \
        2>/dev/null || true"

cp "${ROOTFS}/tmp/proot-home.tar.gz" "${BACKUP_DIR}/home-${TIMESTAMP}.tar.gz"
rm -f "${ROOTFS}/tmp/proot-home.tar.gz"

# 3. Also save latest as symlink for easy restore
ln -sf "home-${TIMESTAMP}.tar.gz" "${BACKUP_DIR}/home-latest.tar.gz"
ln -sf "packages-${TIMESTAMP}.txt" "${BACKUP_DIR}/packages-latest.txt"

echo ">>> Backup saved: ${BACKUP_DIR}/home-${TIMESTAMP}.tar.gz"
echo ">>> Packages: ${BACKUP_DIR}/packages-${TIMESTAMP}.txt"
