# arinanoX AI Stack — Usage Reference for Pi

## Invocation Patterns (proot)

In proot, `#!/usr/bin/env node` shebang is broken with `PROOT_NO_SECCOMP=1`.
Always call Node.js tools via `node` directly:

```bash
# ❌ Don't (shebang broken):
pi --help
ddg "query"
playwright-cli open

# ✅ Do (node direct):
node /usr/lib/node_modules/@earendil-works/pi-coding-agent/dist/cli.js --help
node /usr/lib/node_modules/@oevortex/ddg_search/bin/cli.js "query"
node /usr/lib/node_modules/@playwright/cli/playwright-cli.js open <url> --browser firefox
```

---

## 1. lean-ctx

```bash
# Check health
lean-ctx doctor

# Init (run once)
lean-ctx init --global
lean-ctx init --agent pi

# View token savings
lean-ctx gain --deep

# Shell hooks (after init)
ctx_shell <command>     # compressed shell output
ctx_read <file>         # compressed file read
```

---

## 2. ddg_search

Note: DuckDuckGo is blocked in Indonesia (DNS → ::1). Use `--mode ai`.

```bash
# AI mode (IAsk backend — works in Indonesia)
NODE_TLS_REJECT_UNAUTHORIZED=0 node \
  /usr/lib/node_modules/@oevortex/ddg_search/bin/cli.js \
  --mode ai --backend iask "your question here"

# Or with options
NODE_TLS_REJECT_UNAUTHORIZED=0 node \
  /usr/lib/node_modules/@oevortex/ddg_search/bin/cli.js \
  --mode ai --backend iask \
  --iask-mode thinking \
  --detail-level comprehensive \
  "your question"

# Web mode (DuckDuckGo direct — may be blocked)
node /usr/lib/node_modules/@oevortex/ddg_search/bin/cli.js \
  "query"

# MCP server (for Pi integration)
node /usr/lib/node_modules/@oevortex/ddg_search/bin/cli.js \
  --server
```

**Verified working:** ✅ AI mode (IAsk) returns ~8,000+ chars, relevant results.

---

## 3. playwright-cli

### Setup (already pre-installed in image)

```bash
# Install browser (Firefox, ~97MB)
playwright-cli install-browser firefox

# List installed browsers
playwright-cli install-browser --list
```

### Session-based automation

```bash
# Open browser (headless) with persistent session
node /usr/lib/node_modules/@playwright/cli/playwright-cli.js \
  open https://en.wikipedia.org/wiki/Indonesia \
  --browser firefox \
  -s=mysession

# Navigate to another page
node /usr/lib/node_modules/@playwright/cli/playwright-cli.js \
  -s=mysession goto https://en.wikipedia.org/wiki/API

# Get accessibility snapshot (auto-generated after each command)
# Snapshot saved to: .playwright-cli/page-<timestamp>.yml

# Close session
node /usr/lib/node_modules/@playwright/cli/playwright-cli.js \
  -s=mysession close
```

### All commands

```bash
open [url]                  # Open browser
goto <url>                  # Navigate
click <target> [button]     # Click element (use ref from snapshot)
type <text>                 # Type into focused element
fill <target> <text>        # Fill input
press <key>                 # Press key (Enter, Tab, etc.)
screenshot                  # Take screenshot
close                       # Close browser
detach                      # Detach from session
```

**Verified working:** ✅ Opened Wikipedia Indonesia, navigated to API page, got accessibility snapshots.

---

## 4. Pi Agent

```bash
# Start Pi (via node direct — avoid shebang issue)
node /usr/lib/node_modules/@earendil-works/pi-coding-agent/dist/cli.js

# Within Pi session, set model:
#   /model → deepseek → deepseek-chat

# Check Pi version
node /usr/lib/node_modules/@earendil-works/pi-coding-agent/dist/cli.js --version
```

### MCP Config (`~/.pi/agent/mcp.json`)

Pre-configured in image. Enables ddg_search as Pi tool:

```json
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
```

### DeepSeek Config (`~/.pi/agent/models.json`)

Pre-configured. Set API key before starting Pi:

```bash
export DEEPSEEK_API_KEY="sk-xxxxxxxx"
```

---

## 5. Firefox User.js

Pre-deployed to `~/.mozilla/firefox/*.default-esr/user.js`.
126 lines — optimizations for proot:
- Software WebRender (no GPU passthrough needed)
- Disk cache disabled (slow I/O via bind-mount)
- HW video decoding disabled (not available in proot)
- Network: prefetch/preconnect off
- Telemetry off
- Sandbox: level 0 (unprivileged user namespaces not available)
- Privacy: tracking protection + HTTPS-only

---

## 6. PROOT_NO_SECCOMP

Must be set BEFORE `proot-distro login` for Node.js tools to work:

```bash
export PROOT_NO_SECCOMP=1
proot-distro login arinanox --shared-tmp -u admin -- bash -l -c "..."
```

Already applied automatically in `~/.shortcuts/1-start-arinanox.sh`.

Fixes three bugs:
| Bug | Cause | Without fix |
|---|---|---|
| `uv__io_poll: EINTR` | libuv + seccomp | Node.js event loop crash |
| `fork: Function not implemented` | seccomp blocks clone/fork | Can't spawn processes |
| `futex` error | V8/libuv thread sync | Node.js startup crash |

Side effect: `su - admin` broken → use `proot-distro login -u admin` instead (already in start script).

---

## 7. Full Test Suite

Run these to verify the stack works:

```bash
# 1. lean-ctx
lean-ctx doctor | grep -c "✓"
echo "exit: $?"

# 2. ddg_search AI mode
NODE_TLS_REJECT_UNAUTHORIZED=0 node \
  /usr/lib/node_modules/@oevortex/ddg_search/bin/cli.js \
  --mode ai --backend iask "test" 2>&1 | grep -c "completed"

# 3. playwright-cli
node /usr/lib/node_modules/@playwright/cli/playwright-cli.js \
  open https://example.com --browser firefox -s=test 2>&1 | grep -c "Page URL"
node /usr/lib/node_modules/@playwright/cli/playwright-cli.js \
  -s=test close 2>&1

# 4. Pi
node /usr/lib/node_modules/@earendil-works/pi-coding-agent/dist/cli.js \
  --version

# 5. Firefox user.js
grep -c "user_pref" ~/.mozilla/firefox/*.default-esr/user.js
echo "user.js: $? prefs loaded"
```

---

## 8. Tool Paths Summary

| Tool | Binary | Path |
|---|---|---|
| Pi | `cli.js` | `/usr/lib/node_modules/@earendil-works/pi-coding-agent/dist/cli.js` |
| ddg_search | `cli.js` | `/usr/lib/node_modules/@oevortex/ddg_search/bin/cli.js` |
| playwright-cli | `playwright-cli.js` | `/usr/lib/node_modules/@playwright/cli/playwright-cli.js` |
| lean-ctx | `lean-ctx` | `/usr/local/bin/lean-ctx` |
| Firefox (ESR) | `firefox-esr` | `/usr/bin/firefox-esr` |
| Playwright Firefox | `firefox` | `~/.cache/ms-playwright/firefox-1534/firefox/firefox` |
