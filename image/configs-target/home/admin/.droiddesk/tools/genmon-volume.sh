#!/bin/bash
# ═══════════════════════════════════════════
#  XFCE Genmon — Volume Monitor
#  Panel plugin that shows 🔊 volume level
# ===========================================
#  Setup: xfce4-panel → Add → Generic Monitor
#  Command: bash ~/.droiddesk/tools/genmon-volume.sh
#  Interval: 5s
# ═══════════════════════════════════════════

VOL=$(tapi termux-volume music 2>/dev/null | jq -r .volume 2>/dev/null)

if [ -z "$VOL" ] || [ "$VOL" = "null" ]; then
    echo "<txt>🔇</txt><tool>Audio bridge offline</tool>"
    exit 0
fi

if   [ "$VOL" -eq 0 ]; then ICON="🔇"
elif [ "$VOL" -le 3 ]; then ICON="🔈"
elif [ "$VOL" -le 7 ]; then ICON="🔉"
else                          ICON="🔊"; fi

BAR=$(printf '%*s' "$VOL" '' | tr ' ' '━')
echo "<txt>${ICON} ${BAR}</txt>"
echo "<tool>Volume: ${VOL}/15</tool>"
echo "<txtclick>pavucontrol</txtclick>"
