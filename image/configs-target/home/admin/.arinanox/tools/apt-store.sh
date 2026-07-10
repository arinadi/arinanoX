#!/bin/bash
# arinanoX — APT Store (lightweight GUI package manager)
# Dependencies: yad, apt, sudo

TMP="/tmp/arinanox-store"
mkdir -p "$TMP"

die() { yad --error --title="arinanoX Store" --text="$1" --width=300; exit 0; }

# Check dependencies
command -v yad >/dev/null || die "yad not installed: apt install yad"

# Refresh cache if needed
if [ ! -f "$TMP/packages" ] || [ "$1" = "--refresh" ]; then
    apt-cache search . > "$TMP/packages" 2>/dev/null || die "apt-cache failed"
fi

# Main menu
while true; do
    CHOICE=$(yad --title="arinanoX Store" \
        --width=380 --height=400 --center \
        --window-icon=system-software-install \
        --list --column="Action" --column="Description" \
        --text="<b>APT Package Manager</b>" \
        --button="Close":1 \
        "🔍 Search" "Search and install packages" \
        "📦 Installed" "List installed packages" \
        "🔄 Refresh" "Update package cache" \
        "⬆️ Upgrade" "Upgrade all packages" 2>/dev/null)

    RET=$?
    [ $RET -ne 0 ] && exit 0
    ACT=$(echo "$CHOICE" | cut -d'|' -f1)

    case "$ACT" in
        "🔍 Search")
            QUERY=$(yad --title="Search Packages" --width=400 \
                --entry --text="Package name or keyword:" \
                --button="Search":0 --button="Cancel":1 2>/dev/null)
            [ $? -ne 0 ] && continue

            RESULTS=$(grep -i "$QUERY" "$TMP/packages" | \
                awk -F' - ' '{print "FALSE", $1, substr($2,1,60)}' | head -100)

            if [ -z "$RESULTS" ]; then
                yad --info --text="No results for '$QUERY'" --width=300
                continue
            fi

            SELECTED=$(yad --title="Results: $QUERY" \
                --width=600 --height=500 --center \
                --list --checklist \
                --column="Install" --column="Package" --column="Description" \
                --text="<b>Search results for: $QUERY</b>\nCheck packages to install:" \
                --button="Install Selected":0 --button="Back":1 \
                $RESULTS 2>/dev/null)

            [ $? -ne 0 ] && continue
            PKGS=$(echo "$SELECTED" | awk -F'|' '{print $2}' | tr '\n' ' ')
            [ -z "$PKGS" ] && continue

            # Confirm
            yad --title="Confirm Install" --width=450 \
                --text="<b>Install these packages?</b>\n\n$PKGS" \
                --button="Yes":0 --button="Cancel":1 2>/dev/null
            [ $? -ne 0 ] && continue

            # Install (show progress)
            OUTPUT=$(DEBIAN_FRONTEND=noninteractive sudo apt-get install -y $PKGS 2>&1)
            RET=$?
            echo "$OUTPUT" | tail -20 | yad --title="Install Result" --width=550 --height=400 \
                --text-info --button="OK" --text="$([ $RET -eq 0 ] && echo '✅ Done' || echo '❌ Failed')" 2>/dev/null
            ;;

        "📦 Installed")
            INSTALLED=$(dpkg -l | grep "^ii" | awk '{print $2, "-", $3}' | \
                awk '{print $1}' | sort | \
                awk '{print NR, $0}' | head -200 | \
                awk '{print $0, ""}')

            yad --title="Installed Packages" --width=500 --height=500 --center \
                --list --column="#" --column="Package" \
                --text="<b>Installed packages</b> ($(dpkg -l | grep -c '^ii') total)" \
                --button="OK" $INSTALLED 2>/dev/null
            ;;

        "🔄 Refresh")
            yad --info --title="Refreshing..." --text="Updating package cache..." \
                --width=300 --timeout=1 --no-buttons 2>/dev/null &
            apt-cache search . > "$TMP/packages" 2>/dev/null
            yad --info --text="✅ Cache refreshed" --width=250 2>/dev/null
            ;;

        "⬆️ Upgrade")
            COUNT=$(apt-get -s upgrade 2>/dev/null | grep "^Inst" | wc -l)
            if [ "$COUNT" -eq 0 ]; then
                yad --info --text="System is up to date." --width=250
                continue
            fi
            yad --title="Upgrade" --width=400 \
                --text="<b>$COUNT packages to upgrade.</b>\nProceed?" \
                --button="Upgrade":0 --button="Cancel":1 2>/dev/null
            [ $? -ne 0 ] && continue

            OUTPUT=$(DEBIAN_FRONTEND=noninteractive sudo apt-get upgrade -y 2>&1)
            echo "$OUTPUT" | tail -20 | yad --title="Upgrade Result" --width=550 --height=400 \
                --text-info --button="OK" 2>/dev/null
            ;;
    esac
done
