#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# arinanoX — AI VibeCoding Stack Installer
# Install: Pi, lean-ctx, ddg_search, playwright-cli + Firefox
# Semua tool diinstal NATIVE di proot (bukan via Termux bind-mount)
# ═══════════════════════════════════════════════════════════════
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err()  { echo -e "${RED}[✗]${NC} $1"; }

echo ""
echo "╔═══════════════════════════════════════╗"
echo "║  🤖 arinanoX AI Stack Installer      ║"
echo "╚═══════════════════════════════════════╝"
echo ""

# ── Prerequisites ──────────────────────────────────────────
log "Checking prerequisites..."
command -v node   >/dev/null 2>&1 || { err "Node.js not found — install via arinanoX image first"; exit 1; }
command -v npm    >/dev/null 2>&1 || { err "npm not found"; exit 1; }

NODE_VER=$(node -v 2>/dev/null)
log "Node.js ${NODE_VER}"

# ── [1] Pi Coding Agent ────────────────────────────────────
log "Installing Pi Coding Agent..."
npm install -g --ignore-scripts @earendil-works/pi-coding-agent@latest 2>/dev/null
log "Pi $(pi --version 2>/dev/null || node /usr/lib/node_modules/@earendil-works/pi-coding-agent/dist/cli.js --version 2>/dev/null) installed"

# ── [2] lean-ctx ────────────────────────────────────────────
log "Installing lean-ctx..."
LEAN_CTX_VER="v3.9.8"
ARCH="aarch64-unknown-linux-musl"
cd /tmp
curl -fsSL "https://github.com/yvgude/lean-ctx/releases/download/${LEAN_CTX_VER}/lean-ctx-${ARCH}.tar.gz" \
  -o lean-ctx.tar.gz
tar xzf lean-ctx.tar.gz
sudo cp lean-ctx /usr/local/bin/ 2>/dev/null || cp lean-ctx /usr/local/bin/
rm -f lean-ctx lean-ctx.tar.gz
/usr/local/bin/lean-ctx init --global 2>/dev/null
/usr/local/bin/lean-ctx init --agent pi 2>/dev/null || true
log "lean-ctx $(/usr/local/bin/lean-ctx --version 2>/dev/null) installed"

# ── [3] DeepSeek models.json ───────────────────────────────
log "Configuring DeepSeek provider..."
mkdir -p ~/.pi/agent
cat > ~/.pi/agent/models.json << 'MODELS_EOF'
{
  "providers": {
    "deepseek": {
      "baseUrl": "https://api.deepseek.com",
      "api": "openai-completions",
      "apiKey": "$DEEPSEEK_API_KEY",
      "models": [
        {
          "id": "deepseek-chat",
          "name": "DeepSeek V4 Chat",
          "contextWindow": 1000000,
          "maxTokens": 384000,
          "input": ["text"],
          "reasoning": false,
          "compat": {
            "requiresReasoningContentOnAssistantMessages": false,
            "thinkingFormat": "deepseek"
          }
        }
      ]
    }
  }
}
MODELS_EOF
log "DeepSeek models.json created"

# ── [4] ddg_search ──────────────────────────────────────────
log "Installing ddg_search..."
npm install -g @oevortex/ddg_search@latest 2>/dev/null
log "ddg_search $(ddg --version 2>/dev/null) installed"

# ── [5] playwright-cli + Firefox ───────────────────────────
log "Installing playwright-cli..."
npm install -g @playwright/cli@latest 2>/dev/null
log "playwright-cli $(playwright-cli --version 2>/dev/null) installed"

echo ""
log "Downloading Playwright Firefox (~97MB)..."
playwright-cli install-browser firefox 2>/dev/null
log "Playwright Firefox ready"

# ── [6] MCP Config ──────────────────────────────────────────
log "Setting up MCP config..."
mkdir -p ~/.pi/agent
cat > ~/.pi/agent/mcp.json << 'MCP_EOF'
{
  "mcpServers": {
    "ddg-search": {
      "command": "node",
      "args": [
        "/usr/lib/node_modules/@oevortex/ddg_search/bin/cli.js",
        "--server"
      ],
      "env": {
        "NODE_TLS_REJECT_UNAUTHORIZED": "0"
      }
    }
  }
}
MCP_EOF
log "MCP config created"

# ── [7] Firefox user.js ────────────────────────────────────
log "Deploying Firefox user.js..."
FF_DIR=$(ls -d ~/.mozilla/firefox/*.default-esr 2>/dev/null || echo "")
if [ -n "$FF_DIR" ] && [ -d "$FF_DIR" ]; then
    cp /home/admin/.arinanox/configs/user.js "$FF_DIR/user.js" 2>/dev/null || true
    log "Firefox user.js deployed"
else
    warn "Firefox profile not found — run Firefox once first, then re-run this script"
fi

# ── Summary ────────────────────────────────────────────────
echo ""
echo "╔═══════════════════════════════════════╗"
echo "║  ✅ AI Stack Installation Complete   ║"
echo "╠═══════════════════════════════════════╣"
echo "║                                       ║"
echo "║  Pi          $(pi --version 2>/dev/null || echo '?')                  ║"
echo "║  lean-ctx    $(/usr/local/bin/lean-ctx --version 2>/dev/null || echo '?')               ║"
echo "║  ddg_search  $(ddg --version 2>/dev/null || echo '?')                   ║"
echo "║  playwright  $(playwright-cli --version 2>/dev/null || echo '?')                   ║"
echo "║  DeepSeek    configured               ║"
echo "║                                       ║"
echo "║  Set API key:                         ║"
echo "║    export DEEPSEEK_API_KEY=\"sk-...\"   ║"
echo "║                                       ║"
echo "║  Run: pi                              ║"
echo "╚═══════════════════════════════════════╝"
echo ""
