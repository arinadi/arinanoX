#!/bin/bash
# ═══════════════════════════════════════════
#  XFCE Genmon — Battery Monitor
#  Panel plugin that shows 🔋 percentage
# ===========================================
#  Setup: xfce4-panel → Add → Generic Monitor
#  Command: bash ~/.droiddesk/tools/genmon-battery.sh
#  Interval: 30s
# ═══════════════════════════════════════════

DATA=$(tapi termux-battery-status 2>/dev/null)
if [ -z "$DATA" ]; then
    echo "<txt>🔌</txt><tool>Bridge offline</tool>"
    exit 0
fi

PCT=$(echo "$DATA"   | jq -r .percentage)
STATUS=$(echo "$DATA" | jq -r .status)
TEMP=$(echo "$DATA"   | jq -r .temperature)

# Icon based on level
if   [ "$PCT" -ge 90 ]; then ICON="🔋"
elif [ "$PCT" -ge 60 ]; then ICON="🔋"
elif [ "$PCT" -ge 30 ]; then ICON="🔋"
elif [ "$PCT" -ge 15 ]; then ICON="🪫"
else                          ICON="🪫"; fi

# Charging indicator
[ "$STATUS" = "CHARGING" ] && ICON="⚡"

echo "<txt>${ICON} ${PCT}%</txt>"
echo "<tool>Battery: ${PCT}% (${STATUS}) | Temp: ${TEMP}°C</tool>"
echo "<txtclick>bash ~/.droiddesk/tools/tapi-utils.sh battery</txtclick>"
