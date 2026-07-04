#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

# uninstall.sh — Clean uninstall of DroidDesk
# Removes: proot container, generated scripts, symlinks, configs

echo "╔═══════════════════════════════════╗"
echo "║  🗑️  DroidDesk Uninstaller        ║"
echo "╠═══════════════════════════════════╣"
echo ""
echo "This will remove:"
echo "  • proot container (droiddesk)"
echo "  • launcher scripts (~/.shortcuts/)"
echo "  • home symlinks (start-*, kill-*, update*)"
echo "  • ~/.droiddesk/ cache"
echo ""
echo "This will NOT remove:"
echo "  • ~/DroidDesk/ (git repo)"
echo "  • ~/storage/ (Android storage)"
echo "  • ~/.bashrc (Termux config)"
echo ""

read -rp "Proceed? [y/N] " confirm < /dev/tty
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

echo ""

# 1. Stop any running sessions
echo ">>> Stopping running sessions..."
pkill -f "startxfce4" 2>/dev/null && echo "  [x] XFCE stopped" || true
pkill -f "proot-distro login" 2>/dev/null && echo "  [x] proot login stopped" || true
pkill -f "termux-x11" 2>/dev/null && echo "  [x] X11 stopped" || true
pulseaudio --kill 2>/dev/null && echo "  [x] PulseAudio stopped" || true
pkill -f run-api-bridge 2>/dev/null && echo "  [x] API bridge stopped" || true
termux-wake-unlock 2>/dev/null && echo "  [x] Wake lock released" || true
sleep 1

# 2. Remove proot container
echo ""
echo ">>> Removing proot container..."
if proot-distro list 2>/dev/null | grep -q "droiddesk"; then
    proot-distro remove droiddesk 2>&1 && echo "  [x] droiddesk removed" || echo "  [-] Failed to remove (manual cleanup needed)"
elif proot-distro list 2>/dev/null | grep -q "ubuntu"; then
    proot-distro remove ubuntu 2>&1 && echo "  [x] ubuntu removed" || echo "  [-] Failed to remove (manual cleanup needed)"
else
    echo "  [-] No proot container found"
fi

# 3. Remove launcher scripts
echo ""
echo ">>> Removing launcher scripts..."
rm -f ~/.shortcuts/start-x11.sh \
      ~/.shortcuts/start-xfce.sh \
      ~/.shortcuts/kill-x11.sh \
      ~/.shortcuts/kill-proot.sh \
      ~/.shortcuts/kill-all.sh \
      ~/.shortcuts/update.sh \
      ~/.shortcuts/update-droiddesk.sh
echo "  [x] ~/.shortcuts/ cleaned"

# 4. Remove home symlinks
echo ""
echo ">>> Removing home symlinks..."
rm -f ~/start-x11.sh \
      ~/start-xfce.sh \
      ~/kill-x11.sh \
      ~/kill-proot.sh \
      ~/kill-all.sh \
      ~/update.sh \
      ~/update-droiddesk.sh
echo "  [x] Home symlinks removed"

# 5. Remove ~/.droiddesk cache
echo ""
echo ">>> Removing ~/.droiddesk cache..."
rm -rf ~/.droiddesk
echo "  [x] ~/.droiddesk removed"

# 6. Clean Termux tmp
echo ""
echo ">>> Cleaning Termux tmp..."
TERMUX_TMP="${TMPDIR:-/data/data/com.termux/files/usr/tmp}"
rm -f "${TERMUX_TMP}/.X0-lock" 2>/dev/null
rm -rf "${TERMUX_TMP}/.X11-unix" 2>/dev/null
rm -f "${TERMUX_TMP}/pulse-socket" 2>/dev/null
echo "  [x] Temp files cleaned"

# 7. Remove run-api-bridge.sh from home
echo ""
echo ">>> Removing API bridge..."
rm -f ~/run-api-bridge.sh
echo "  [x] run-api-bridge.sh removed"

echo ""
echo "╔═══════════════════════════════════╗"
echo "║  ✅ DroidDesk uninstalled         ║"
echo "╠═══════════════════════════════════╣"
echo "║                                   ║"
echo "║  To reinstall:                    ║"
echo "║  curl -sL URL/bootstrap.sh | bash ║"
echo "║                                   ║"
echo "║  To remove ~/DroidDesk repo:      ║"
echo "║  rm -rf ~/DroidDesk               ║"
echo "╚═══════════════════════════════════╝"
