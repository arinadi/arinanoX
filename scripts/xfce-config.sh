#!/bin/bash
# 📱 arinanoX — Apply Orchis Dark Material theme inside proot
# Called during bootstrap after proot setup completes.

echo ">>> Applying Orchis Dark theme..."

# Copy theme script into proot
ROOTFS="/data/data/com.termux/files/usr/var/lib/proot-distro/containers/arinanox/rootfs"
mkdir -p "${ROOTFS}/home/admin/.arinanox/scripts"
cp "$HOME/.arinanox/scripts/theme-dark.sh" "${ROOTFS}/home/admin/.arinanox/scripts/"

# Run inside proot as admin
proot-distro login arinanox -- su - admin -c 'bash ~/.arinanox/scripts/theme-dark.sh' 2>/dev/null

echo ">>> Theme applied."
