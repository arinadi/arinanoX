#!/data/data/com.termux/files/usr/bin/bash
# 🛡️ Hardened Termux:API Bridge
# Prevents large payloads from being executed as shell commands

IN_PORT=8888
OUT_PORT=8889

# Ensure dependencies
if ! command -v nc &> /dev/null; then
    pkg install netcat-openbsd -y
fi

trap "pkill -P $$; exit" SIGINT SIGTERM

echo ">>> Bridge Listening on $IN_PORT (Commands) and $OUT_PORT (Response)"

while true; do
    # Receive command, sanitize (take only first line to avoid executing payload), then run
    CMD=$(nc -l -p $IN_PORT | head -n 1)
    
    if [ -n "$CMD" ]; then
        echo "[Bridge] Executing: $CMD"
        # Execute the command and pipe output to the response port
        eval "$CMD" 2>&1 | nc -l -p $OUT_PORT
    fi
done
