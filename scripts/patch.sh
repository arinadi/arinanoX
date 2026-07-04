#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

# patch.sh — Install optional software into DroidDesk proot
# Interactive (no args) or CLI (with flags)

CONTAINER="droiddesk"

declare -A PATCHES

# Browsers
PATCHES[firefox]="Firefox ESR|apt-get install -y firefox-esr"
PATCHES[chromium]="Chromium Browser|apt-get install -y chromium-browser"

# Development
PATCHES[code]="VS Code (code-server)|curl -fsSL https://code-server.dev/install.sh | sh"
PATCHES[geany]="Geany (Lightweight IDE)|apt-get install -y geany"
PATCHES[node]="Node.js 24|curl -fsSL https://deb.nodesource.com/setup_24.x | bash - && apt-get install -y nodejs"
PATCHES[python]="Python 3 + pip + venv|apt-get install -y python3-pip python3-venv"
PATCHES[build]="Build Essential (gcc/make/g++)|apt-get install -y build-essential"
PATCHES[cmake]="CMake Build System|apt-get install -y cmake"
PATCHES[git]="Git + GitHub CLI|apt-get install -y git gh"
PATCHES[openssh]="OpenSSH Client|apt-get install -y openssh-client"

# AI
PATCHES[ollama]="Ollama (local LLM)|curl -fsSL https://ollama.com/install.sh | sh"

# System
PATCHES[htop]="htop + tmux|apt-get install -y htop tmux"
PATCHES[zsh]="Zsh + Oh My Zsh|apt-get install -y zsh && su - admin -c 'sh -c \"$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\" \"\" --unattended'"
PATCHES[neovim]="Neovim|apt-get install -y neovim"
PATCHES[nala]="Nala (Modern APT)|apt-get install -y nala"
PATCHES[docker]="Docker (rootless)|curl -fsSL https://get.docker.com | sh"

# CLI Tools (only ones NOT in image)
PATCHES[ripgrep]="Fast Grep (rg)|apt-get install -y ripgrep"

# GUI Apps
PATCHES[viewnior]="Image Viewer (Viewnior)|apt-get install -y viewnior"
PATCHES[xarchiver]="Archive Manager|apt-get install -y xarchiver"
PATCHES[galculator]="Calculator (Galculator)|apt-get install -y galculator"

# === Parse args ===
SELECTED=()
INTERACTIVE=true

if [ $# -gt 0 ]; then
    INTERACTIVE=false
    for arg in "$@"; do
        case "$arg" in
            --firefox)    SELECTED+=("firefox") ;;
            --chromium)   SELECTED+=("chromium") ;;
            --code)       SELECTED+=("code") ;;
            --geany)      SELECTED+=("geany") ;;
            --node)       SELECTED+=("node") ;;
            --python)     SELECTED+=("python") ;;
            --build)      SELECTED+=("build") ;;
            --cmake)      SELECTED+=("cmake") ;;
            --git)        SELECTED+=("git") ;;
            --openssh)    SELECTED+=("openssh") ;;
            --ollama)     SELECTED+=("ollama") ;;
            --htop)       SELECTED+=("htop") ;;
            --zsh)        SELECTED+=("zsh") ;;
            --neovim)     SELECTED+=("neovim") ;;
            --nala)       SELECTED+=("nala") ;;
            --docker)     SELECTED+=("docker") ;;
            --ripgrep)    SELECTED+=("ripgrep") ;;
            --viewnior)   SELECTED+=("viewnior") ;;
            --xarchiver)  SELECTED+=("xarchiver") ;;
            --galculator) SELECTED+=("galculator") ;;
            --all)        mapfile -t SELECTED < <(echo "${!PATCHES[@]}" | tr ' ' '\n') ;;
            --list)
                echo "Available patches:"
                for key in $(echo "${!PATCHES[@]}" | tr ' ' '\n' | sort); do
                    desc="${PATCHES[$key]%%|*}"
                    echo "  --$(echo "$key" | tr '_' '-')  $desc"
                done
                exit 0
                ;;
            *) echo "Unknown: $arg (use --list)"; exit 1 ;;
        esac
    done
fi

# === Interactive mode ===
if $INTERACTIVE; then
    echo ""
    echo "╔═══════════════════════════════════╗"
    echo "║  📦 DroidDesk Patch Installer     ║"
    echo "╠═══════════════════════════════════╣"
    echo ""

    for key in $(echo "${!PATCHES[@]}" | tr ' ' '\n' | sort); do
        IFS='|' read -r desc cmd <<< "${PATCHES[$key]}"
        printf "  %-14s %s" "[$key]" "$desc"
        read -rp " Install? [y/N] " ans
        if [[ "$ans" =~ ^[Yy]$ ]]; then
            SELECTED+=("$key")
        fi
    done

    echo ""
    if [ ${#SELECTED[@]} -eq 0 ]; then
        echo "Nothing selected. Exiting."
        exit 0
    fi

    echo "Will install: ${SELECTED[*]}"
    read -rp "Proceed? [Y/n] " confirm
    if [[ "$confirm" =~ ^[Nn]$ ]]; then
        echo "Cancelled."
        exit 0
    fi
fi

# === Install ===
echo ""
echo ">>> Installing ${#SELECTED[@]} patches..."

for key in "${SELECTED[@]}"; do
    IFS='|' read -r desc cmd <<< "${PATCHES[$key]}"
    echo ""
    echo ">>> [$key] $desc"
    proot-distro login "$CONTAINER" -- bash -c "
        export DEBIAN_FRONTEND=noninteractive
        $cmd
    " || echo "  ⚠️  Failed: $key"
done

echo ""
echo ">>> Done! ${#SELECTED[@]} patches installed."
