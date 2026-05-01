# 📱 Termux:API Guide for DroidDesk

Termux:API allows DroidDesk to interact with Android hardware and system features directly from the Linux command line.

## 🛠️ Essential Commands

### 🔋 System Info
- `termux-battery-status`: Get battery level, health, and temperature.
- `termux-wifi-connectioninfo`: View current WiFi network details.
- `termux-telephony-deviceinfo`: Get device information (IMEI, signal, etc).

### 🔔 User Interaction
- `termux-toast [-c color] [-b bgcolor] "message"`: Show a small popup notification.
- `termux-notification -t "Title" -c "Content"`: Show a system notification.
- `termux-vibrate -d [duration]`: Vibrate the device.
- `termux-tts-speak "text"`: Text-to-speech engine.

### 📷 Hardware Control
- `termux-torch [on|off]`: Toggle camera flashlight.
- `termux-brightness [0-255]`: Adjust screen brightness.
- `termux-volume [stream] [volume]`: Adjust system audio volumes.

### 📍 Sensors & Data
- `termux-location`: Get GPS coordinates.
- `termux-sensor -l`: List all available sensors (Accelerometer, Proximity, etc).
- `termux-clipboard-set "text"`: Copy text to Android clipboard.
- `termux-clipboard-get`: Read text from Android clipboard.

---

## 🚀 Practical Examples

### 1. Battery Alert Script
Keep this running in a background tab to get a notification when battery is low:
```bash
while true; do
  LEVEL=$(termux-battery-status | jq .percentage)
  if [ "$LEVEL" -lt 20 ]; then
    termux-notification -t "Battery Low" -c "Level: $LEVEL%. Please charge."
    termux-vibrate -d 500
  fi
  sleep 300
done
```

### 2. Quick Flashlight Toggle (Shortcut)
```bash
alias light="termux-torch on"
alias dark="termux-torch off"
```

### 3. Sync Clipboard to Proot
```bash
# Inside Proot
alias getclip="termux-clipboard-get"
```

---

## ⚠️ Requirements
1.  **Termux:API Package**: `pkg install termux-api`
2.  **Termux:API App**: Must be installed from F-Droid.
3.  **Permissions**: Android will prompt for permissions (Camera, Location, etc) on first run of specific commands.
