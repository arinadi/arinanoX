#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

echo ">>> Setting up MOTD..."

cat > /data/data/com.termux/files/usr/etc/motd << 'MOTDEOF'

==========================================
 📱 arinanoX Proot XFCE
==========================================

 Start:
    bash ~/start.sh
 Stop:
    bash ~/stop.sh

 ⚠ Update (fresh install, wipes config):
    curl -sL URL/bootstrap.sh | bash
    See README for details.

 User: admin / Pass: admin
==========================================
MOTDEOF

echo ">>> MOTD updated."
