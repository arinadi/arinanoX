#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

# ══════════════════════════════════════════
#  arinanoX Bootstrap — curl | bash
#  https://github.com/arinadi/arinanoX
# ══════════════════════════════════════════

REPO="https://raw.githubusercontent.com/arinadi/arinanoX/main"
ARINANOX_DIR="$HOME/.arinanox"
SCRIPTS_DIR="${ARINANOX_DIR}/scripts"
LAUNCHERS_DIR="${ARINANOX_DIR}/launchers"

# --- Detect state ---
INSTALLED=false
if [ -f "$ARINANOX_DIR/version.txt" ]; then
    INSTALLED=true
    LOCAL_VER=$(cat "$ARINANOX_DIR/version.txt" | tr -d '[:space:]')
fi

REMOTE_VER=$(curl -sL --retry 2 "${REPO}/version.txt" 2>/dev/null | tr -d '[:space:]')
if [ -z "$REMOTE_VER" ]; then
    REMOTE_VER="unknown"
fi

# --- Detect if stdin is terminal ---
if [ -t 0 ]; then
    INTERACTIVE=true
else
    INTERACTIVE=false
fi

# --- Menu (only when interactive) ---
if $INTERACTIVE; then
    echo ""
    echo "╔═══════════════════════════════════════╗"
    echo "║  📱 arinanoX — Linux on Android      ║"
    echo "╠═══════════════════════════════════════╣"

    if $INSTALLED; then
        echo "║  Installed: v${LOCAL_VER}                       ║"
        echo "║  Available: v${REMOTE_VER}                       ║"
        echo "╠═══════════════════════════════════════╣"
        echo "║                                       ║"
        echo "║  [1] Update                           ║"
        echo "║  [2] Reinstall (fresh)                ║"
        echo "║  [3] Uninstall                        ║"
        echo "║  [4] Exit                             ║"
        echo "║                                       ║"
    else
        echo "║  Available: v${REMOTE_VER}                       ║"
        echo "╠═══════════════════════════════════════╣"
        echo "║                                       ║"
        echo "║  [1] Install                          ║"
        echo "║  [2] Exit                             ║"
        echo "║                                       ║"
    fi
    echo "╚═══════════════════════════════════════╝"
    echo ""

    read -rp "  Choose: " CHOICE

    if $INSTALLED; then
        case "$CHOICE" in
            1) ACTION="update" ;;
            2) ACTION="install" ;;
            3) ACTION="uninstall" ;;
            4|*) echo ">>> Bye!"; exit 0 ;;
        esac
    else
        case "$CHOICE" in
            2|4) echo ">>> Bye!"; exit 0 ;;
            *) ACTION="install" ;;
        esac
    fi
else
    # Non-interactive (curl | bash): auto-detect action
    if $INSTALLED; then
        if [ "$REMOTE_VER" = "$LOCAL_VER" ]; then
            echo ">>> arinanoX v${LOCAL_VER} — already up to date."
            exit 0
        fi
        echo ">>> arinanoX v${LOCAL_VER} → updating to v${REMOTE_VER}..."
        ACTION="update"
    else
        echo ">>> Installing arinanoX v${REMOTE_VER}..."
        ACTION="install"
    fi
fi

# --- Uninstall ---
if [ "$ACTION" = "uninstall" ]; then
    echo ""
    echo ">>> Downloading uninstall script..."
    curl -sL --retry 2 "${REPO}/uninstall.sh" | bash
    exit 0
fi

# --- Install / Update ---
if [ "$ACTION" = "install" ]; then
    echo ">>> Installing arinanoX v${REMOTE_VER}..."
    rm -rf "$ARINANOX_DIR"
    mkdir -p "$SCRIPTS_DIR" "$LAUNCHERS_DIR"
elif [ "$ACTION" = "update" ]; then
    echo ">>> Updating: v${LOCAL_VER} → v${REMOTE_VER}"
fi

# --- Download Scripts ---
echo ">>> Downloading scripts..."
mkdir -p "$SCRIPTS_DIR" "$LAUNCHERS_DIR"
for f in host-setup.sh proot-setup.sh api-bridge-setup.sh xfce-config.sh \
         launcher-gen.sh motd-setup.sh \
         proot-backup.sh proot-restore.sh \
         patch.sh; do
    curl -sL --retry 2 "${REPO}/scripts/${f}" -o "${SCRIPTS_DIR}/${f}"
    chmod +x "${SCRIPTS_DIR}/${f}"
done

# --- Download Launchers ---
echo ">>> Downloading launchers..."
for f in start-x11.sh start-xfce.sh kill-x11.sh kill-proot.sh kill-all.sh update.sh; do
    curl -sL --retry 2 "${REPO}/launchers/${f}" -o "${LAUNCHERS_DIR}/${f}"
    chmod +x "${LAUNCHERS_DIR}/${f}"
done

# --- Download hardened API bridge ---
echo ">>> Downloading API bridge..."
curl -sL --retry 2 "${REPO}/run-api-bridge.sh" -o "${ARINANOX_DIR}/run-api-bridge.sh"
chmod +x "${ARINANOX_DIR}/run-api-bridge.sh"

# --- Execute Setup ---
echo ""
echo ">>> Running host setup..."
bash "${SCRIPTS_DIR}/host-setup.sh"

echo ""
echo ">>> Setting up Debian proot..."
bash "${SCRIPTS_DIR}/proot-setup.sh"

echo ""
echo ">>> Setting up Termux:API bridge..."
bash "${SCRIPTS_DIR}/api-bridge-setup.sh"

echo ""
echo ">>> Installing launchers..."
bash "${SCRIPTS_DIR}/launcher-gen.sh"

echo ""
echo ">>> Setting up MOTD..."
bash "${SCRIPTS_DIR}/motd-setup.sh"

# --- Save Version ---
echo "$REMOTE_VER" > "$ARINANOX_DIR/version.txt"

echo ""
echo "╔═══════════════════════════════════════╗"
echo "║  ✅ arinanoX v${REMOTE_VER} complete!        ║"
echo "╠═══════════════════════════════════════╣"
echo "║                                       ║"
echo "║  Start:                               ║"
echo "║    bash ~/start-x11.sh                ║"
echo "║    bash ~/start-xfce.sh               ║"
echo "║                                       ║"
echo "║  Stop:                                ║"
echo "║    bash ~/kill-all.sh                 ║"
echo "║                                       ║"
echo "║  Built-in: Firefox ESR, Node 22, Go,  ║"
echo "║  Python, Git, GCC/CMake, Mousepad...  ║"
echo "║  More: ~/.arinanox/scripts/patch.sh  ║"
echo "║                                       ║"
echo "║  Uninstall:                           ║"
echo "║    bash ~/arinanoX/uninstall.sh      ║"
echo "╚═══════════════════════════════════════╝"
