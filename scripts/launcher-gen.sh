#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

echo ">>> Installing launchers..."
DROIDDESK_DIR="$HOME/.arinanox"
mkdir -p ~/.shortcuts

# Remove old launchers
rm -f ~/.shortcuts/start-x11.sh ~/.shortcuts/start-xfce.sh
rm -f ~/.shortcuts/kill-x11.sh ~/.shortcuts/kill-proot.sh ~/.shortcuts/kill-all.sh
rm -f ~/start-x11.sh ~/start-xfce.sh ~/kill-x11.sh ~/kill-proot.sh ~/kill-all.sh

# Install new unified launchers
for f in start.sh stop.sh update.sh; do
    cp "${DROIDDESK_DIR}/launchers/${f}" ~/.shortcuts/"${f}"
    chmod +x ~/.shortcuts/"${f}"
    ln -sf ~/.shortcuts/"${f}" ~/"${f}"
done

# Legacy shortcut
ln -sf update.sh ~/.shortcuts/update-arinanox.sh 2>/dev/null || true
ln -sf ~/update.sh ~/update-arinanox.sh 2>/dev/null || true

echo ">>> Launchers installed."
