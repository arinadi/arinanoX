#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

DROIDDESK_DIR="$HOME/.droiddesk"

echo ">>> Setting up Termux:API bridge..."

# 1. Create host-side bridge (hardened version from repo)
cp "${DROIDDESK_DIR}/run-api-bridge.sh" ~/run-api-bridge.sh
chmod +x ~/run-api-bridge.sh

# 2. Create tapi client inside proot
proot-distro login droiddesk -- bash -c '
    cat > /usr/local/bin/tapi << "TAPIOF"
#!/bin/bash
# tapi (Termux-API-Bridge-Client)
echo "$@" | nc 127.0.0.1 8888 &
timeout 10 nc 127.0.0.1 8889
TAPIOF
    chmod +x /usr/local/bin/tapi
'

echo ">>> Termux:API bridge ready."
