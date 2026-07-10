#!/bin/bash
# ═══════════════════════════════════════════
#  DroidDesk — Clipboard Sync (Android ↔ proot)
#  Runs in background, syncs clipboards
# ═══════════════════════════════════════════

LAST_ANDROID=""
LAST_PROOT=""

while true; do
    # Android → proot (check every 2s)
    ANDROID_CLIP=$(tapi termux-clipboard-get 2>/dev/null)
    if [ -n "$ANDROID_CLIP" ] && [ "$ANDROID_CLIP" != "$LAST_ANDROID" ]; then
        echo -n "$ANDROID_CLIP" | xclip -selection clipboard 2>/dev/null || true
        echo -n "$ANDROID_CLIP" | xclip -selection primary 2>/dev/null || true
        LAST_ANDROID="$ANDROID_CLIP"
    fi

    # proot → Android (check every 2s)
    PROOT_CLIP=$(xclip -selection clipboard -o 2>/dev/null)
    if [ -n "$PROOT_CLIP" ] && [ "$PROOT_CLIP" != "$LAST_PROOT" ] && [ "$PROOT_CLIP" != "$LAST_ANDROID" ]; then
        echo -n "$PROOT_CLIP" | tapi termux-clipboard-set 2>/dev/null
        LAST_PROOT="$PROOT_CLIP"
    fi

    sleep 2
done
