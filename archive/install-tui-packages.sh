#!/data/data/com.termux/files/usr/bin/bash
# install-tui-packages.sh — Interactive Package Installer for DroidDesk
# Run from Termux host. Uses dialog for checkbox TUI.
set -euo pipefail

DISTRO="ubuntu"
ROOTFS="/data/data/com.termux/files/usr/var/lib/proot-distro/installed-rootfs/${DISTRO}"

if [ ! -d "$ROOTFS" ]; then
    echo "ERROR: Ubuntu proot not found. Run setup-proot-xfce.sh first."
    exit 1
fi

# Ensure dialog is available on Termux host
command -v dialog &>/dev/null || { echo "[*] Installing dialog..."; pkg install -y dialog; }

# Temp file for dialog output
TMPFILE=$(mktemp "${PREFIX}/tmp/droiddesk_tui.XXXXXX")
trap "rm -f '$TMPFILE' '${ROOTFS}/tmp/_tui_install.sh' 2>/dev/null" EXIT

# =============================================
#  Package Checklist (grouped by category)
# =============================================
dialog --title " 📦 DroidDesk Package Installer " \
    --checklist "\n Select packages to install into Ubuntu proot.\n Use SPACE to toggle, ENTER to confirm.\n\n ── Dev Essentials ──────────────────" \
    0 0 0 \
    "geany"           "📝  Geany (Lightweight IDE)"       ON  \
    "git"             "🔧  Git Version Control"            ON  \
    "gh"              "🐙  GitHub CLI"                     ON  \
    "nodejs"          "🟢  Node.js 24 (NodeSource)"        ON  \
    "python3-pip"     "🐍  Python Pip"                     ON  \
    "python3-venv"    "🐍  Python Virtual Env"             ON  \
    "sqlitebrowser"   "🗃️   SQLite Browser (GUI)"           OFF \
    "meld"            "🌿  Meld (Visual Diff/Merge)"       OFF \
    "build-essential" "⚙️   GCC / Make / G++"               OFF \
    "cmake"           "⚙️   CMake Build System"             OFF \
    "──1──"           "── System Tools ─────────────────"  OFF \
    "nala"            "📦  Modern APT Frontend"            ON  \
    "htop"            "📊  Process Monitor (CLI)"          ON  \
    "lxtask"          "📊  LXTask (GUI Task Manager)"      OFF \
    "tmux"            "🖥️   Terminal Multiplexer"           OFF \
    "openssh-client"  "🔑  SSH Client"                     OFF \
    "──2──"           "── GUI Utilities ────────────────"  OFF \
    "viewnior"        "🖼️   Viewnior (Light Image Viewer)"  OFF \
    "xarchiver"       "📦  Xarchiver (Archive Manager)"    OFF \
    "galculator"      "🔢  Galculator (Scientific Calc)"   OFF \
    "──3──"           "── CLI Utilities ────────────────"  OFF \
    "jq"              "📋  JSON Processor"                 ON  \
    "tree"            "🌳  Directory Tree View"            ON  \
    "ripgrep"         "🔍  Fast Grep (rg)"                 ON  \
    "curl"            "🌐  HTTP Client"                    ON  \
    "wget"            "⬇️   Download Manager"               ON  \
    "zip"             "📦  ZIP / UNZIP Tools"              ON  \
    "sqlite3"         "🗃️   SQLite CLI"                     OFF \
    "──4──"           "── Editors ──────────────────────"  OFF \
    "vim"             "📝  Vim Editor"                     OFF \
    "nano"            "📝  Nano Editor"                    OFF \
    "mousepad"        "📝  Mousepad (XFCE Notepad)"       OFF \
    "──5──"           "── Browsers ─────────────────────"  OFF \
    "firefox-esr"     "🌐  Firefox ESR (Heavy ~200MB)"    OFF \
    "netsurf-gtk"     "🌐  NetSurf (Ultra Light Browser)"  OFF \
    "──6──"           "── Fonts & Theming ──────────────"  OFF \
    "fonts-firacode"  "🔤  Fira Code (ligatures)"         OFF \
    "papirus-icon-theme" "🎨 Papirus Icons (XFCE)"        OFF \
    "arc-theme"       "🎨  Arc GTK Theme"                  OFF \
    "──7──"           "── AI & LLM Tools ─────────────────"  OFF \
    "gemini-chat"     "🤖  Gemini CLI (npm)"               OFF \
    "qwen-chat"       "🤖  Qwen CLI (npm)"                 OFF \
    "context-mode"    "🤖  Context-Mode (npm)"              OFF \
    "aichat"          "🤖  AIChat (Multi-Provider)"        OFF \
    "shell-gpt"       "🤖  Shell GPT (Python)"             OFF \
    "ollama"          "🤖  Ollama (Local LLMs)"            OFF \
    2>"$TMPFILE"

# Check if user cancelled
DIALOG_EXIT=$?
if [ $DIALOG_EXIT -ne 0 ]; then
    clear
    echo "Installation cancelled."
    exit 0
fi

SELECTIONS=$(cat "$TMPFILE")
if [ -z "$SELECTIONS" ]; then
    clear
    echo "No packages selected."
    exit 0
fi

# =============================================
#  Parse selections into categories
# =============================================
APT_PKGS=""
SETUP_GH=false
SETUP_NODE=false
NPM_AI_PKGS=""
PIP_AI_PKGS=""
SETUP_AICHAT=false

for pkg in $SELECTIONS; do
    pkg=$(echo "$pkg" | tr -d '"')
    case "$pkg" in
        ──*──)   ;; # skip separator items
        gh)      SETUP_GH=true ;;
        nodejs)  SETUP_NODE=true ;;
        gemini-chat|qwen-chat|context-mode) 
                 SETUP_NODE=true
                 NPM_AI_PKGS="$NPM_AI_PKGS $pkg" 
                 ;;
        shell-gpt) 
                 APT_PKGS="$APT_PKGS python3-pip"
                 PIP_AI_PKGS="$PIP_AI_PKGS shell-gpt" 
                 ;;
        aichat)  SETUP_AICHAT=true ;;
        zip)     APT_PKGS="$APT_PKGS zip unzip" ;;
        *)       APT_PKGS="$APT_PKGS $pkg" ;;
    esac
done

# Always ensure ca-certificates and gnupg for repo setup
if $SETUP_GH || $SETUP_NODE || $SETUP_AICHAT; then
    APT_PKGS="ca-certificates gnupg curl $APT_PKGS"
fi

# =============================================
#  Build install script (written to rootfs tmp
#  to avoid all shell quoting issues)
# =============================================
SCRIPT_PATH="${ROOTFS}/tmp/_tui_install.sh"

cat > "$SCRIPT_PATH" << 'HEADER'
#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive
echo ">>> Updating package lists..."
apt-get update -y -q
HEADER

# Apt packages
if [ -n "$APT_PKGS" ]; then
    APT_PKGS=$(echo "$APT_PKGS" | tr ' ' '\n' | sort -u | tr '\n' ' ')
    cat >> "$SCRIPT_PATH" << APTEOF
echo ">>> Installing apt packages..."
echo "    Packages: ${APT_PKGS}"
apt-get install -y -q --no-install-recommends ${APT_PKGS}
APTEOF
fi

# GitHub CLI (needs external repo)
if $SETUP_GH; then
    cat >> "$SCRIPT_PATH" << 'GHEOF'
echo ">>> Setting up GitHub CLI..."
if ! command -v gh &>/dev/null; then
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg 2>/dev/null
    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    ARCH=$(dpkg --print-architecture)
    echo "deb [arch=${ARCH} signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        > /etc/apt/sources.list.d/github-cli.list
    apt-get update -y -q
    apt-get install -y -q gh
else
    echo "  [-] gh already installed ($(gh --version | head -1)), skipping"
fi
GHEOF
fi

# Node.js 24 (needs NodeSource repo)
if $SETUP_NODE; then
    cat >> "$SCRIPT_PATH" << 'NODEEOF'
echo ">>> Setting up Node.js 24..."
if ! command -v node &>/dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_24.x | bash -
    apt-get install -y -q nodejs
else
    CURRENT=$(node --version)
    echo "  [-] node already installed (${CURRENT}), skipping"
fi
NODEEOF
fi

# NPM AI Tools
if [ -n "$NPM_AI_PKGS" ]; then
    for ai_pkg in $NPM_AI_PKGS; do
        real_pkg="$ai_pkg"
        [ "$ai_pkg" = "context-mode" ] && real_pkg="@context-mode/mcp-server"
        cat >> "$SCRIPT_PATH" << AINPMEOF
echo ">>> Installing ${ai_pkg} via npm..."
npm install -g ${real_pkg} || echo "  ⚠️  Failed to install ${ai_pkg}"
AINPMEOF
    done
fi

# Pip AI Tools
if [ -n "$PIP_AI_PKGS" ]; then
    for ai_pkg in $PIP_AI_PKGS; do
        cat >> "$SCRIPT_PATH" << AIPIPEOF
echo ">>> Installing ${ai_pkg} via pip..."
pip3 install --break-system-packages ${ai_pkg} || echo "  ⚠️  Failed to install ${ai_pkg}"
AIPIPEOF
    done
fi

# AIChat (Binary)
if $SETUP_AICHAT; then
    cat >> "$SCRIPT_PATH" << 'AICHATEOF'
echo ">>> Installing AIChat binary..."
ARCH=$(dpkg --print-architecture)
case "$ARCH" in
    amd64) A_ARCH="x86_64" ;;
    arm64) A_ARCH="aarch64" ;;
    armhf) A_ARCH="armv7" ;;
    *)     A_ARCH="$ARCH" ;;
esac
# Get latest version tag
VER=$(curl -s https://api.github.com/repos/sigoden/aichat/releases/latest | jq -r .tag_name)
URL="https://github.com/sigoden/aichat/releases/download/${VER}/aichat-${VER}-${A_ARCH}-unknown-linux-gnu.tar.gz"
curl -L "$URL" | tar xz -C /usr/local/bin || echo "  ⚠️  Failed to install aichat"
AICHATEOF
fi

# Ollama
if [[ "$SELECTIONS" == *"ollama"* ]]; then
    cat >> "$SCRIPT_PATH" << 'OLLAMAEOF'
echo ">>> Installing Ollama..."
curl -fsSL https://ollama.com/install.sh | sh || echo "  ⚠️  Failed to install ollama"
OLLAMAEOF
fi

# Cleanup and verification footer
cat >> "$SCRIPT_PATH" << 'FOOTER'

echo ""
echo ">>> Cleaning up apt cache..."
apt-get clean
rm -rf /var/lib/apt/lists/*

echo ""
echo "╔═══════════════════════════════════╗"
echo "║     Installation Summary          ║"
echo "╠═══════════════════════════════════╣"
command -v git     &>/dev/null && printf "║  ✅ %-30s║\n" "git $(git --version 2>/dev/null | sed 's/git version //')"
command -v gh      &>/dev/null && printf "║  ✅ %-30s║\n" "gh $(gh --version 2>/dev/null | head -1 | awk '{print $3}')"
command -v node    &>/dev/null && printf "║  ✅ %-30s║\n" "node $(node --version 2>/dev/null)"
command -v npm     &>/dev/null && printf "║  ✅ %-30s║\n" "npm $(npm --version 2>/dev/null)"
command -v python3 &>/dev/null && printf "║  ✅ %-30s║\n" "python3 $(python3 --version 2>/dev/null | awk '{print $2}')"
command -v geany   &>/dev/null && printf "║  ✅ %-30s║\n" "geany"
command -v jq      &>/dev/null && printf "║  ✅ %-30s║\n" "jq $(jq --version 2>/dev/null)"
command -v rg      &>/dev/null && printf "║  ✅ %-30s║\n" "ripgrep $(rg --version 2>/dev/null | head -1 | awk '{print $2}')"
command -v htop    &>/dev/null && printf "║  ✅ %-30s║\n" "htop"
command -v nala    &>/dev/null && printf "║  ✅ %-30s║\n" "nala"
command -v tmux    &>/dev/null && printf "║  ✅ %-30s║\n" "tmux"
command -v vim     &>/dev/null && printf "║  ✅ %-30s║\n" "vim"
command -v meld     &>/dev/null && printf "║  ✅ %-30s║\n" "meld"
command -v sqlitebrowser &>/dev/null && printf "║  ✅ %-30s║\n" "sqlitebrowser"
command -v viewnior  &>/dev/null && printf "║  ✅ %-30s║\n" "viewnior"
command -v galculator &>/dev/null && printf "║  ✅ %-30s║\n" "galculator"
command -v lxtask    &>/dev/null && printf "║  ✅ %-30s║\n" "lxtask"
command -v xarchiver &>/dev/null && printf "║  ✅ %-30s║\n" "xarchiver"
command -v netsurf-gtk &>/dev/null && printf "║  ✅ %-30s║\n" "netsurf-gtk"
command -v cmake   &>/dev/null && printf "║  ✅ %-30s║\n" "cmake $(cmake --version 2>/dev/null | head -1 | awk '{print $3}')"
command -v sqlite3 &>/dev/null && printf "║  ✅ %-30s║\n" "sqlite3"
command -v firefox-esr &>/dev/null && printf "║  ✅ %-30s║\n" "firefox-esr"
command -v aichat     &>/dev/null && printf "║  ✅ %-30s║\n" "aichat"
command -v gemini-chat &>/dev/null && printf "║  ✅ %-30s║\n" "gemini-chat"
command -v qwen-chat   &>/dev/null && printf "║  ✅ %-30s║\n" "qwen-chat"
command -v context-mode &>/dev/null && printf "║  ✅ %-30s║\n" "context-mode"
command -v sgpt        &>/dev/null && printf "║  ✅ %-30s║\n" "shell-gpt"
command -v ollama      &>/dev/null && printf "║  ✅ %-30s║\n" "ollama"
echo "╚═══════════════════════════════════╝"
FOOTER

# =============================================
#  Confirm & Execute
# =============================================
clear
echo "==========================================="
echo " 📦 DroidDesk Package Installer"
echo "==========================================="
echo ""
echo " Selected packages:"
for pkg in $SELECTIONS; do
    pkg=$(echo "$pkg" | tr -d '"')
    case "$pkg" in ──*──) continue ;; esac
    echo "   • $pkg"
done
echo ""
read -p " Proceed with installation? [Y/n] " -r CONFIRM
CONFIRM=${CONFIRM:-Y}

if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    rm -f "$SCRIPT_PATH"
    echo "Installation cancelled."
    exit 0
fi

echo ""
chmod +x "$SCRIPT_PATH"
proot-distro login "$DISTRO" -- bash /tmp/_tui_install.sh
rm -f "$SCRIPT_PATH"

echo ""
echo "==========================================="
echo " ✅ Installation complete!"
echo "==========================================="
