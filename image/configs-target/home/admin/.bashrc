export DISPLAY=:0
export XDG_RUNTIME_DIR=/tmp
export NO_AT_BRIDGE=1
export LIBGL_ALWAYS_SOFTWARE=1
export GDK_SCALE=2
export GDK_DPI_SCALE=0.5
# Firefox: suppress sandbox video device spam in proot
export MOZ_DISABLE_CONTENT_SANDBOX=1

# Clean PATH from Termux pollution
export PATH=/home/admin/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# NVM Initialization (if exists)
export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

# Python: pip user installs
# Node: npm global installs
export PATH="$PATH:$HOME/.local/bin"

alias update='sudo apt-get update && sudo apt-get upgrade -y'
alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias cls='clear'
alias df='df -h'
alias free='free -h'
alias ports='ss -tlnp'
alias myip='curl -s ifconfig.me && echo'

# ──── DroidDesk TAPI utilities ────
TAPI_UTILS="$HOME/.droiddesk/tools/tapi-utils.sh"
if [ -f "$TAPI_UTILS" ]; then
    source "$TAPI_UTILS"
fi

# ──── Welcome ────
if [ -f "$HOME/.droiddesk/tools/tapi-utils.sh" ]; then
    echo ""
    echo "╔═══════════════════════════════════╗"
    echo "║  📱 DroidDesk — Ready             ║"
    echo "╠═══════════════════════════════════╣"
    echo "║  battery       clipget / clipset  ║"
    echo "║  vol-up/down   bright 50          ║"
    echo "║  toast 'msg'   buzz               ║"
    echo "║  speak 'text'  listen             ║"
    echo "║  whereami      wifi | photo pic   ║"
    echo "╚═══════════════════════════════════╝"
    echo ""
fi
