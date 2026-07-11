#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

echo ">>> Setting up MOTD..."

cat > /data/data/com.termux/files/usr/etc/motd << 'MOTDEOF'

==========================================
 📱 arinanoX Proot XFCE
==========================================

 Start:
    bash ~/start.sh

 Stop/Update:
    bash ~/stop.sh
    bash ~/update.sh

 User: admin / Pass: admin
==========================================
MOTDEOF

echo ">>> MOTD updated."
