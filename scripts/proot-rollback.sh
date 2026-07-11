#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
# ═══════════════════════════════════════════
#  arinanoX Rollback — restore previous image
#  Silverblue-style: keep deployment 0 (current) and deployment 1 (previous)
# ═══════════════════════════════════════════

CONTAINER="arinanox"
PREV_CONTAINER="arinanox-prev"
CONTAINERS_DIR="/data/data/com.termux/files/usr/var/lib/proot-distro/containers"

if [ ! -d "${CONTAINERS_DIR}/${PREV_CONTAINER}" ]; then
    echo ">>> No previous deployment found."
    echo ">>> Nothing to rollback."
    exit 1
fi

echo ">>> Rolling back to previous deployment..."

# Remove current (broken) container
if [ -d "${CONTAINERS_DIR}/${CONTAINER}" ]; then
    proot-distro remove "$CONTAINER" 2>/dev/null || true
fi

# Rename previous → current
mv "${CONTAINERS_DIR}/${PREV_CONTAINER}" "${CONTAINERS_DIR}/${CONTAINER}"

echo ">>> Rollback complete. Previous deployment restored."
echo ">>> Run: bash ~/start.sh"
