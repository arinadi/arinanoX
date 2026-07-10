#!/bin/bash
# arinanoX — APT Store (lightweight GUI package manager)
# Dependencies: yad, apt, sudo
set -euo pipefail

TMP="/tmp/arinanox-store"
mkdir -p "$TMP"
command -v yad >/dev/null || { yad --error --text="yad not installed: apt install yad"; exit 1; }

# ═══ Helpers ═══
pkg_info() {
    local pkg="$1"
    local maint size desc installed
    maint=$(apt-cache show "$pkg" 2>/dev/null | grep "^Maintainer:" | head -1 | sed 's/^Maintainer: //')
    size=$(apt-cache show "$pkg" 2>/dev/null | grep "^Installed-Size:" | head -1 | awk '{printf "%.1f MB", $2/1024}')
    desc=$(apt-cache show "$pkg" 2>/dev/null | grep "^Description-en:" | head -1 | sed 's/^Description-en: //')
    installed=$(dpkg -s "$pkg" 2>/dev/null | grep "^Version:" | sed 's/^Version: //')
    echo "$maint|$size|$desc|$installed"
}

# ═══ Search ═══
do_search() {
    local query="$1"
    [ -z "$query" ] && { yad --info --text="Enter a search query." --width=250; return; }

    local results line pkg desc yadargs
    results=$(apt-cache search "$query" 2>/dev/null | head -80)

    if [ -z "$results" ]; then
        yad --info --text="No results for '$query'" --width=300
        return
    fi

    yadargs=""
    while IFS=' - ' read -r pkg desc; do
        pkg="${pkg%% *}"  # apt-cache search output: "pkg - desc..."
        desc="${desc:0:70}"
        if dpkg -s "$pkg" &>/dev/null; then
            yadargs="$yadargs FALSE '$pkg' '$desc ✓'"
        else
            yadargs="$yadargs FALSE '$pkg' '$desc'"
        fi
    done <<< "$results"

    eval "set -- $yadargs"
    
    SELECTED=$(yad --title="Search: $query" \
        --width=650 --height=500 --center \
        --window-icon=system-software-install \
        --list --checklist --separator=" " \
        --column="✓" --column="Package" --column="Description" \
        --text="<b>Results for: $query</b>\n▸ ✓ = already installed" \
        --print-column=2 \
        --button="Install Selected":0 --button="Back":1 \
        "$@" 2>/dev/null)

    [ $? -ne 0 ] && return
    [ -z "$SELECTED" ] && { yad --info --text="Nothing selected." --width=250; return; }

    # Confirm with details
    local info_list=""
    for p in $SELECTED; do
        IFS='|' read -r maint size desc installed <<< "$(pkg_info "$p")"
        info_list="$info_list\n<b>$p</b>  $size"
        [ -n "$maint" ] && info_list="$info_list\n   by: $maint"
        [ -n "$desc" ] && info_list="$info_list\n   $desc"
        info_list="$info_list\n"
    done

    yad --title="Confirm Install" --width=520 --height=250 \
        --window-icon=dialog-question \
        --text="<b>Install these packages?</b>$info_list" \
        --button="Install":0 --button="Cancel":1 2>/dev/null
    [ $? -ne 0 ] && return

    # Install
    DEBIAN_FRONTEND=noninteractive sudo apt-get install -y $SELECTED 2>&1 | \
        tail -15 | \
        yad --title="Installing..." --width=550 --height=350 \
            --text-info --button="OK" \
            --text="Installing: $SELECTED" 2>/dev/null
}

# ═══ Installed ═══
do_installed() {
    local count list
    count=$(dpkg -l 2>/dev/null | grep -c '^ii')
    list=$(dpkg -l 2>/dev/null | grep '^ii' | awk '{printf "%s|%s|%s\n", $2, $3, $5}' | sort | head -500 | tr '\n' ' ')

    yad --title="Installed Packages" --width=580 --height=520 --center \
        --list --column="Package" --column="Version" --column="Size" \
        --text="<b>$count packages installed</b>" \
        --button="OK" ${list} 2>/dev/null
}

# ═══ Upgrade ═══
do_upgrade() {
    local count list
    count=$(apt-get -s upgrade 2>/dev/null | grep "^Inst " | wc -l)
    
    if [ "$count" -eq 0 ]; then
        yad --info --text="✅ System is up to date." --width=250
        return
    fi

    list=$(apt-get -s upgrade 2>/dev/null | grep "^Inst " | awk '{printf "%s|%s\n", $2, $4}' | tr '\n' ' ')

    yad --title="Upgrade" --width=480 --height=380 --center \
        --text="<b>$count packages can be upgraded</b>" \
        --list --column="Package" --column="New Version" \
        --button="Upgrade All":0 --button="Cancel":1 \
        ${list} 2>/dev/null
    [ $? -ne 0 ] && return

    DEBIAN_FRONTEND=noninteractive sudo apt-get upgrade -y 2>&1 | \
        tail -15 | \
        yad --title="Upgrade complete" --width=550 --height=350 \
            --text-info --button="OK" 2>/dev/null
}

# ═══ Main ═══
while true; do
    CHOICE=$(yad --title="arinanoX Store" \
        --width=360 --height=320 --center \
        --window-icon=system-software-install \
        --form \
        --field="":LBL "<b>APT Package Manager</b>" \
        --field="Search": "" \
        --button="🔍 Search":0 \
        --button="📦 Installed":2 \
        --button="⬆️ Upgrade":4 \
        --button="✕":1 2>/dev/null)

    RET=$?
    QUERY=$(echo "$CHOICE" | cut -d'|' -f2 | tr -d '\n')

    case $RET in
        0) do_search "$QUERY" ;;
        2) do_installed ;;
        4) do_upgrade ;;
        *) exit 0 ;;
    esac
done
