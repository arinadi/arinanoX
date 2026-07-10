#!/bin/bash
# ═══════════════════════════════════════════
#  DroidDesk — Termux:API Bridge Utilities
#  Source this in .bashrc: source ~/.droiddesk/tools/tapi-utils.sh
# ═══════════════════════════════════════════

# --- API bridge (tapi command already in /usr/local/bin/tapi) ---
# All Termux:API commands are available as: tapi termux-<command>

# --- Clipboard: copy from Android to proot ---
clipget() {
    tapi termux-clipboard-get
}

# --- Clipboard: copy from proot to Android ---
clipset() {
    local text="${*:-$(cat)}"
    echo "$text" | tapi termux-clipboard-set
}

# --- Toast notification ---
toast() {
    tapi termux-toast "$*"
}

# --- Battery info ---
battery() {
    tapi termux-battery-status | jq -r '
        "🔋 \(.percentage)%  |  \(.status)  |  \(.health)  |  \(.temperature)°C"
    '
}

# --- Volume controls ---
vol-up()   { tapi termux-volume music "$(($(tapi termux-volume music 2>/dev/null | jq -r .volume // 5) + 1))" 2>/dev/null; }
vol-down() { tapi termux-volume music "$(($(tapi termux-volume music 2>/dev/null | jq -r .volume // 5) - 1))" 2>/dev/null; }
vol-get()  { tapi termux-volume music 2>/dev/null | jq -r .volume; }

# --- Brightness ---
bright() { tapi termux-brightness "$1"; }

# --- Torch ---
flash()  { tapi termux-torch on; }
flash-off() { tapi termux-torch off; }

# --- Notifications ---
notify() {
    local title="$1"
    local body="$2"
    tapi termux-notification -t "$title" -c "$body"
}

# --- Open URL/File in Android ---
openurl()  { tapi termux-open-url "$1"; }
share()    { tapi termux-share "$1"; }

# --- Voice ---
speak()    { tapi termux-tts-speak "$*"; }
listen()   { tapi termux-speech-to-text; }

# --- Vibration feedback ---
buzz()     { tapi termux-vibrate -d 200; }

# --- WiFi ---
wifi()     { tapi termux-wifi-connectioninfo | jq; }

# --- Location ---
whereami() { tapi termux-location | jq; }

# --- Camera ---
photo()    { tapi termux-camera-photo -c 0 "$1"; }

# --- SMS ---
sms()      { tapi termux-sms-send -n "$1" "$2"; }

# --- Auto-start clipboard sync (call once in session) ---
clipboard-watch() {
    if pgrep -f "clipboard-sync.sh" > /dev/null; then
        echo "Clipboard sync already running."
        return
    fi
    nohup bash ~/.droiddesk/tools/clipboard-sync.sh > /dev/null 2>&1 &
    echo "Clipboard sync started (Android ↔ proot)."
}

echo "📱 DroidDesk TAPI utils loaded. Try: battery, clipget, clipset, bright 50, buzz"
