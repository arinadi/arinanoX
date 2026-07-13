FROM debian:13

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# ═══════════════════════════════════════════════
# Layer 1  BASE + CORE PACKAGES
# ═══════════════════════════════════════════════
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        dialog locales ca-certificates sudo \
        curl wget zip unzip jq tree less && \
    apt-get upgrade -y -o Dpkg::Options::='--force-confold' && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# ═══════════════════════════════════════════════
# Layer 2  XFCE + GUI + BROWSER + THEMES
# ═══════════════════════════════════════════════
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        dbus-x11 xfce4-session xfwm4 xfce4-panel xfce4-terminal \
        xfce4-settings xfconf thunar xfdesktop4 libgl1 librsvg2-common \
        pulseaudio-utils netcat-openbsd x11-xserver-utils \
        xfce4-whiskermenu-plugin xfce4-pulseaudio-plugin xfce4-genmon-plugin \
        mousepad ristretto tumbler adwaita-icon-theme \
        orchis-gtk-theme elementary-xfce-icon-theme \
        firefox-esr \
        mesa-utils glmark2 \
        xdotool \
        gnupg \
        yad && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# ═══════════════════════════════════════════════
# Layer 3  DEV TOOLS + SYSTEM + NODE.JS
# ═══════════════════════════════════════════════
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git python3-pip python3-venv python3-dev \
        build-essential cmake pkg-config \
        htop tmux openssh-client && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y nodejs && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# ═══════════════════════════════════════════════
# Layer 4  CONFIGS + USER + CLEANUP
# ═══════════════════════════════════════════════
RUN printf '#!/bin/sh\nexit 1\n' > /usr/bin/pm-is-supported && chmod +x /usr/bin/pm-is-supported && \
    dpkg --purge libupower-glib3 2>/dev/null || true && \
    useradd -m -s /bin/bash admin && \
    echo "admin:admin" | chpasswd && \
    echo "admin ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/admin && \
    chmod 0440 /etc/sudoers.d/admin

COPY configs-target/home/ /home/

RUN chown -R admin:admin /home/admin && \
    chmod +x /home/admin/.arinanox/tools/*.sh && \
    sed -i 's|.droiddesk/|.arinanox/|g' /home/admin/.bashrc && \
    sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && locale-gen

ENV LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

# ═══════════════════════════════════════════════
# Layer 5  AI VIBECODING STACK — pre-installed in image
# Pi, lean-ctx, ddg_search, playwright-cli + Firefox
# ═══════════════════════════════════════════════

# ── Install npm global packages (as root) ──────────────────
RUN npm install -g --ignore-scripts @earendil-works/pi-coding-agent@latest && \
    npm install -g @oevortex/ddg_search@latest && \
    npm install -g @playwright/cli@latest

# ── Install lean-ctx binary (musl ARM64, statically linked) ─
RUN LEAN_CTX_VER="v3.9.8" && \
    ARCH="aarch64-unknown-linux-musl" && \
    cd /tmp && \
    curl -fsSL "https://github.com/yvgude/lean-ctx/releases/download/${LEAN_CTX_VER}/lean-ctx-${ARCH}.tar.gz" -o lean-ctx.tar.gz && \
    tar xzf lean-ctx.tar.gz && \
    cp lean-ctx /usr/local/bin/ && \
    rm -f lean-ctx lean-ctx.tar.gz

# ── Download Playwright Firefox browser (as admin) ─────────
RUN sudo -u admin playwright-cli install-browser firefox 2>/dev/null || true

# ── lean-ctx init for admin user ───────────────────────────
RUN sudo -u admin /usr/local/bin/lean-ctx init --global 2>/dev/null || true && \
    sudo -u admin /usr/local/bin/lean-ctx init --agent pi 2>/dev/null || true

# ── Setup config files for admin ───────────────────────────
COPY configs/ai-stack /home/admin/.arinanox/ai-stack/

# Generate Firefox profile by running briefly headless, then deploy user.js
RUN sudo -u admin MOZ_HEADLESS=1 firefox --headless --first-startup & \
    FF_PID=$! && \
    sleep 8 && \
    kill $FF_PID 2>/dev/null; \
    sleep 1 && \
    FF_DIR=$(ls -d /home/admin/.mozilla/firefox/*.default-esr 2>/dev/null || echo "") && \
    if [ -n "$FF_DIR" ] && [ -d "$FF_DIR" ]; then \
        cp /home/admin/.arinanox/ai-stack/user.js "$FF_DIR/user.js" && \
        echo "user.js deployed to $FF_DIR"; \
    else \
        echo "Firefox profile not created — user.js will be deployed on first run"; \
    fi

# DeepSeek models.json
RUN echo '{
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
}' > /home/admin/.pi/agent/models.json

# MCP config (ddg-search via node — avoid shebang issue in proot)
RUN echo '{
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
}' > /home/admin/.pi/agent/mcp.json

# ── Permissions ────────────────────────────────────────────
RUN chown -R admin:admin /home/admin/.pi /home/admin/.local /home/admin/.config 2>/dev/null || true && \
    chown -R admin:admin /home/admin/.arinanox/ai-stack && \
    chmod +x /home/admin/.arinanox/ai-stack/*.sh

# ── Copy setup script to system location as well ───────────
RUN cp /home/admin/.arinanox/ai-stack/setup-ai-stack.sh /usr/local/bin/arinanox-ai-setup && \
    chmod +x /usr/local/bin/arinanox-ai-setup

CMD ["/bin/bash"]
