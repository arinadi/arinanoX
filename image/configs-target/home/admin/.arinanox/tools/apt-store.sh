#!/bin/bash
# arinanoX — APT Store (lightweight GUI package manager)
# Dependencies: yad, apt, sudo, curl, gpg

TMP="/tmp/arinanox-store"
mkdir -p "$TMP"
YAD="yad --center --borders=12"
command -v yad >/dev/null || { $YAD --error --text="yad not installed: apt install yad"; exit 1; }

# ═══ Helpers ═══
pkg_info() {
    local pkg="$1" maint size desc
    maint=$(apt-cache show "$pkg" 2>/dev/null | grep "^Maintainer:" | head -1 | sed 's/^Maintainer: //')
    [ -z "$maint" ] && maint="—"
    size=$(apt-cache show "$pkg" 2>/dev/null | grep "^Installed-Size:" | head -1 | awk '{printf "%.1f MB", $2/1024}')
    [ -z "$size" ] && size="—"
    desc=$(apt-cache show "$pkg" 2>/dev/null | grep "^Description-en:" | head -1 | sed 's/^Description-en: //')
    [ -z "$desc" ] && desc="—"
    echo "$maint|$size|$desc"
}

# ═══ Search ═══
do_search() {
    local query="$1"
    [ -z "$query" ] && { $YAD --info --text="Enter a search query." --width=280; return; }

    local results
    results=$(apt-cache search "$query" 2>/dev/null | head -80 || true)

    if [ -z "$results" ]; then
        $YAD --info --text="No results for '$query'\nTry 'Add Repository' to add more sources." --width=350
        return
    fi

    # Build args via temp file (avoids eval + quote issues)
    local tmpfile="$TMP/search-args"
    > "$tmpfile"
    while IFS=' - ' read -r pkg desc; do
        pkg="${pkg%% *}"
        desc="${desc:0:70}"
        desc="${desc//|/ }"  # sanitize pipes
        if dpkg -s "$pkg" &>/dev/null; then
            echo "FALSE" "$pkg" "${desc} ✓" >> "$tmpfile"
        else
            echo "FALSE" "$pkg" "$desc" >> "$tmpfile"
        fi
    done <<< "$results"

    local selected installed_list
    mapfile -t selected < <(
        $YAD --title="Search: $query" \
            --width=650 --height=500 \
            --list --checklist --separator=$'\n' \
            --column="✓" --column="Package" --column="Description" \
            --text="<b>Results for: $query</b>\n▸ ✓ = already installed" \
            --print-column=2 \
            --button="<b>Install</b>":0 --button="Back":1 \
            --file="$tmpfile" 2>/dev/null || true
    )

    [ ${#selected[@]} -eq 0 ] && return

    # Confirm with details
    local info_list="" p
    for p in "${selected[@]}"; do
        [ -z "$p" ] && continue
        IFS='|' read -r maint size desc <<< "$(pkg_info "$p")"
        info_list+=$'\n'"<b>$p</b>  $size"
        info_list+=$'\n'"   by: $maint"
        info_list+=$'\n'"   $desc"
        info_list+=$'\n'
    done

    $YAD --title="Confirm Install" --width=520 --height=250 \
        --text="<b>Install these packages?</b>$info_list" \
        --button="<b>Install</b>":0 --button="Cancel":1 2>/dev/null || return

    # Install
    local pkgs="${selected[*]}"
    DEBIAN_FRONTEND=noninteractive sudo apt-get install -y $pkgs 2>&1 | \
        tail -15 | \
        $YAD --title="Installing..." --width=550 --height=350 \
            --text-info --button="OK" \
            --text="Installing: $pkgs" 2>/dev/null || true
}

# ═══ Installed ═══
do_installed() {
    local count
    count=$(dpkg -l 2>/dev/null | grep -c '^ii' || true)

    local tmpfile="$TMP/installed-args"
    > "$tmpfile"
    dpkg -l 2>/dev/null | grep '^ii' | awk '{print $2, $3, $5}' | sort | head -500 | \
        while read -r pkg ver sz; do
            echo "$pkg" "$ver" "$sz" >> "$tmpfile"
        done

    $YAD --title="Installed Packages" --width=580 --height=520 \
        --list --column="Package" --column="Version" --column="Size" \
        --text="<b>$count packages installed</b>" \
        --button="OK":0 \
        --file="$tmpfile" 2>/dev/null || true
}

# ═══ Upgrade ═══
do_upgrade() {
    local count
    count=$(apt-get -s upgrade 2>/dev/null | grep "^Inst " | wc -l || true)

    if [ "$count" -eq 0 ]; then
        $YAD --info --text="✅ System is up to date." --width=280
        return
    fi

    local tmpfile="$TMP/upgrade-args"
    > "$tmpfile"
    apt-get -s upgrade 2>/dev/null | grep "^Inst " | awk '{print $2, $4}' | \
        while read -r pkg ver; do
            echo "$pkg" "$ver" >> "$tmpfile"
        done

    $YAD --title="Upgrade" --width=480 --height=380 \
        --text="<b>$count packages can be upgraded</b>" \
        --list --column="Package" --column="New Version" \
        --button="<b>Upgrade All</b>":0 --button="Cancel":1 \
        --file="$tmpfile" 2>/dev/null || return

    DEBIAN_FRONTEND=noninteractive sudo apt-get upgrade -y 2>&1 | \
        tail -15 | \
        $YAD --title="Upgrade complete" --width=550 --height=350 \
            --text-info --button="OK" 2>/dev/null || true
}

# ═══ Sources ═══
do_sources() {
    local txt
    txt=$( (grep -v '^#\|^$' /etc/apt/sources.list 2>/dev/null
           grep -vh '^#\|^$' /etc/apt/sources.list.d/*.list 2>/dev/null) | \
           sed 's/^/  /' | head -40 || true)

    [ -z "$txt" ] && txt="(no sources found)"

    $YAD --title="APT Sources" --width=700 --height=380 \
        --text="<b>Repository Sources</b>" \
        --text-info --button="OK":0 \
        --margins=10 <<< "$txt" 2>/dev/null || true
}

# ═══ Add Repository ═══
do_add_repo() {
    local tmpfile="$TMP/addrepo-args"
    > "$tmpfile"
    echo "📖 VS Code|Microsoft Visual Studio Code (ARM64)" >> "$tmpfile"
    echo "🦊 Firefox|Mozilla Firefox latest (non-ESR)" >> "$tmpfile"
    echo "🐳 Docker|Docker Engine (ARM64)" >> "$tmpfile"
    echo "☕ OpenJDK|Temurin JDK (Eclipse Adoptium)" >> "$tmpfile"
    echo "✏️ Custom|Add APT repository manually" >> "$tmpfile"

    local choice
    choice=$($YAD --title="Add Repository" \
        --width=420 --height=420 \
        --list --column="Option" --column="Description" \
        --text="<b>Add software source</b>" \
        --button="<b>Add</b>":0 --button="Cancel":1 \
        --file="$tmpfile" 2>/dev/null || true)

    [ -z "$choice" ] && return

    local opt
    opt=$(echo "$choice" | cut -d'|' -f1)

    local repo key_url key_name

    case "$opt" in
        "📖 VS Code")
            repo="deb [arch=arm64] https://packages.microsoft.com/repos/code stable main"
            key_url="https://packages.microsoft.com/keys/microsoft.asc"
            key_name="microsoft"
            ;;
        "🦊 Firefox")
            repo="deb [arch=arm64] http://packages.mozilla.org/apt mozilla main"
            key_url="https://packages.mozilla.org/apt/repo-signing-key.gpg"
            key_name="mozilla"
            ;;
        "🐳 Docker")
            repo="deb [arch=arm64] https://download.docker.com/linux/debian trixie stable"
            key_url="https://download.docker.com/linux/debian/gpg"
            key_name="docker"
            ;;
        "☕ OpenJDK")
            repo="deb [arch=arm64] https://packages.adoptium.net/artifactory/deb trixie main"
            key_url="https://packages.adoptium.net/artifactory/api/gpg/key/public"
            key_name="adoptium"
            ;;
        "✏️ Custom")
            add_custom_repo
            return
            ;;
        *) return ;;
    esac

    # Progress
    $YAD --title="Adding $key_name..." --text="Downloading key and updating..." \
        --width=350 --progress --pulsate --auto-close --no-buttons &
    local progress_pid=$!

    # Download + add key
    if curl -fsSL "$key_url" 2>/dev/null | \
       sudo gpg --dearmor -o "/usr/share/keyrings/${key_name}.gpg" 2>/dev/null; then
        
        # Build signed repo line
        local url_part="${repo#deb*\] }"
        echo "deb [arch=arm64 signed-by=/usr/share/keyrings/${key_name}.gpg] ${url_part}" | \
            sudo tee "/etc/apt/sources.list.d/${key_name}.list" > /dev/null

        sudo apt-get update -qq 2>/dev/null || true
        
        kill $progress_pid 2>/dev/null || true
        $YAD --info --text="✅ Repository added\n\nSource: ${key_name}\nRun Search to find new packages." --width=350
    else
        kill $progress_pid 2>/dev/null || true
        $YAD --error --text="❌ Failed to download key" --width=300
    fi
}

add_custom_repo() {
    local form
    form=$($YAD --title="Custom Repository" --width=480 \
        --form \
        --field="Repo Line": "deb [arch=arm64] " \
        --field="Key URL (optional)": "" \
        --field="Name": "" \
        --button="<b>Add</b>":0 --button="Cancel":1 2>/dev/null || true)
    [ -z "$form" ] && return

    local repo key_url key_name
    repo=$(echo "$form" | cut -d'|' -f1)
    key_url=$(echo "$form" | cut -d'|' -f2)
    key_name=$(echo "$form" | cut -d'|' -f3 | tr ' ' '_')
    [ -z "$key_name" ] && key_name="custom-$(date +%s)"

    if [ -n "$key_url" ]; then
        curl -fsSL "$key_url" 2>/dev/null | \
            sudo gpg --dearmor -o "/usr/share/keyrings/${key_name}.gpg" 2>/dev/null || {
                $YAD --error --text="❌ Failed to download key" --width=300
                return
            }
        local url_part="${repo#deb*\] }"
        echo "deb [arch=arm64 signed-by=/usr/share/keyrings/${key_name}.gpg] ${url_part}" | \
            sudo tee "/etc/apt/sources.list.d/${key_name}.list" > /dev/null
    else
        echo "$repo" | sudo tee "/etc/apt/sources.list.d/${key_name}.list" > /dev/null
    fi

    sudo apt-get update -qq 2>/dev/null || true
    $YAD --info --text="✅ Custom repository added." --width=300
}

# ═══ Main ═══
while true; do
    choice=$($YAD --title="arinanoX Store" \
        --width=380 --height=340 \
        --form \
        --field="":LBL "<b>APT Package Manager</b>" \
        --field="Search": "" \
        --button="<b>Search</b>":0 \
        --button="<b>Installed</b>":2 \
        --button="<b>Add Repo</b>":3 \
        --button="<b>Sources</b>":5 \
        --button="<b>Upgrade</b>":4 \
        --button="✕":1 2>/dev/null || true)

    ret=$?
    query=$(echo "$choice" | cut -d'|' -f2 | tr -d '\n' 2>/dev/null || true)

    case $ret in
        0) do_search "$query" ;;
        2) do_installed ;;
        3) do_add_repo ;;
        4) do_upgrade ;;
        5) do_sources ;;
        *) exit 0 ;;
    esac
done
