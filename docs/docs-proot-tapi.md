# 🌉 Proot Termux:API Bridge (tapi)

`tapi` is a specialized bridge that allows applications running inside the **Proot (Linux)** environment to access **Termux:API** commands on the Android host.

## 🧐 Why is this needed?
By default, Proot cannot access Android's native `/system/bin/app_process` due to security restrictions. `tapi` solves this by creating a lightweight TCP bridge between the Linux guest and the Termux host.

## 🚀 How to Use
Inside your Proot terminal (Ubuntu/Debian/Kali), simply prefix any Termux:API command with `tapi`.

### Examples:
```bash
# Show a notification on Android from Linux
tapi termux-toast "Hello from Ubuntu!"

# Check battery status
tapi termux-battery-status

# Vibrate the phone
tapi termux-vibrate -d 500

# Copy text to Android clipboard
echo "Copied from Linux" | tapi termux-clipboard-set
```

---

## 🐍 Python GUI Integration
You can use `tapi` within Python scripts to create desktop tools that control your phone.

### Example: `battery_alert.py`
```python
import subprocess
import json

def get_status():
    # Use tapi to fetch host data
    raw = subprocess.check_output(['tapi', 'termux-battery-status'])
    data = json.loads(raw)
    print(f"Battery: {data['percentage']}% ({data['status']})")

get_status()
```

---

## 🛠️ Technical Details
The bridge consists of two parts:
1.  **Host Listener (`run-api-bridge.sh`):** A Netcat (`nc`) loop running on Termux host (Port 8888).
2.  **Guest Client (`tapi`):** A small wrapper script in `/usr/local/bin/tapi` that sends commands to the host and waits for the response on Port 8889.

### Troubleshooting
If `tapi` hangs or fails:
1.  Ensure you started X11 via `bash ~/start-x11.sh` (which starts the bridge).
2.  Check if `netcat-openbsd` is installed on both Host and Guest.
3.  Restart the bridge: `pkill -f run-api-bridge.sh && bash ~/run-api-bridge.sh &`.

---

## 🔋 Power Management (Wake Lock)
When running long-running scripts (like Telegram Bots) using `tapi` or background browsers:
- DroidDesk automatically activates `termux-wake-lock` when starting.
- This prevents Android from killing your Proot processes when the screen is off.
