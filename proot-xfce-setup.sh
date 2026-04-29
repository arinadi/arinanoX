#!/data/data/com.termux/files/usr/bin/bash
# proot-xfce-setup.sh v2.1
# Install XFCE4 di Ubuntu 22.04 (proot-distro) via Termux-X11
set -uo pipefail

readonly PROOT_DISTRO="ubuntu"
readonly ADMIN_USER="admin"
readonly ADMIN_PASS="admin"
readonly TERMUX_PREFIX="/data/data/com.termux/files/usr"
readonly TERMUX_BIN="${TERMUX_PREFIX}/bin"
TERMUX_TMP="${TMPDIR:-${TERMUX_PREFIX}/tmp}"
readonly TERMUX_VK_ICD="${TERMUX_PREFIX}/share/vulkan/icd.d"
readonly TERMUX_LIB="${TERMUX_PREFIX}/lib"
readonly PROOT_ROOTFS="${TERMUX_PREFIX}/var/lib/proot-distro/installed-rootfs/${PROOT_DISTRO}"
readonly PROOT_HOME="${PROOT_ROOTFS}/home/${ADMIN_USER}"

TOTAL_STEPS=8
CURRENT_STEP=0
GPU_MODE="zink"

R='\033[0;31m' G='\033[0;32m' Y='\033[1;33m'
C='\033[0;36m' W='\033[1;37m' D='\033[0;90m'
P='\033[0;35m' N='\033[0m'

# ── Progress ───────────────────────────────────────────────
progress() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    local pct=$((CURRENT_STEP * 100 / TOTAL_STEPS))
    local filled=$((pct / 5)) empty=$((20 - pct / 5)) bar="${G}" i
    for ((i=0; i<filled; i++)); do bar+="█"; done
    bar+="${D}"; for ((i=0; i<empty; i++)); do bar+="░"; done; bar+="${N}"
    echo -e "\n${W}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}"
    echo -e "${C}  STEP ${CURRENT_STEP}/${TOTAL_STEPS}  ${bar}  ${W}${pct}%${N}"
    echo -e "${W}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}\n"
}

# ── Spinner ────────────────────────────────────────────────
spinner() {
    local pid=$1 msg=$2 sp='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏' i=0
    while kill -0 "${pid}" 2>/dev/null; do
        printf "\r  ${C}[%s]${N} %s " "${sp:$((i % ${#sp})):1}" "${msg}"
        i=$((i+1)); sleep 0.1
    done
    wait "${pid}"; local rc=$?
    [ $rc -eq 0 ] \
        && printf "\r  ${G}[✓]${N} %-55s\n" "${msg}" \
        || printf "\r  ${R}[✗]${N} %-55s ${R}(error ${rc})${N}\n" "${msg}"
    return $rc
}

# ── Termux pkg install ─────────────────────────────────────
tpkg() {
    ("${TERMUX_BIN}/pkg" install -y "$1" >/dev/null 2>&1) &
    spinner $! "[Termux] pkg install $1"
}

# ── Ubuntu: jalankan perintah (output tersembunyi) ─────────
ubuntu_run_quiet() {
    proot-distro login "${PROOT_DISTRO}" -- bash -c "$1" >/dev/null 2>&1
}

# ── Ubuntu: jalankan perintah (output RAW ke terminal) ────
# Dipakai saat debug / langkah yang sering stuck
ubuntu_run() {
    proot-distro login "${PROOT_DISTRO}" -- bash -c "$1"
}

# ── Ubuntu apt install (quiet + spinner) ──────────────────
ubuntu_pkg() {
    local pkgs="$1" label="${2:-$1}"
    (ubuntu_run_quiet "
        DEBIAN_FRONTEND=noninteractive apt-get install -y -q \
            -o Dpkg::Options::='--force-confold' \
            -o APT::Get::Assume-Yes=true \
            ${pkgs}
    ") &
    spinner $! "[Ubuntu] apt install ${label}"
}

# ── Ubuntu apt install RAW (output langsung ke terminal) ──
# Pakai ini untuk paket yang diketahui lambat/macet agar
# progress apt terlihat dan error tidak tersembunyi
ubuntu_pkg_verbose() {
    local pkgs="$1" label="${2:-$1}"
    echo -e "  ${Y}[Ubuntu] apt install ${label} — output RAW:${N}"
    echo -e "  ${D}──────────────────────────────────────────────────${N}"
    ubuntu_run "
        DEBIAN_FRONTEND=noninteractive apt-get install -y \
            -o Dpkg::Options::='--force-confold' \
            -o APT::Get::Assume-Yes=true \
            --no-install-recommends \
            ${pkgs}
    "
    local rc=$?
    echo -e "  ${D}──────────────────────────────────────────────────${N}"
    [ $rc -eq 0 ] \
        && echo -e "  ${G}[✓] ${label} OK${N}" \
        || echo -e "  ${R}[✗] ${label} GAGAL (rc=${rc})${N}"
    return $rc
}

# ══════════════════════════════════════════════════════════
banner() {
    clear
    echo -e "${C}"
    cat << 'EOF'
  ╔════════════════════════════════════════════════════╗
  ║   proot-xfce-setup.sh  v2.1                       ║
  ║   Ubuntu 22.04  →  XFCE4  →  Termux-X11           ║
  ╚════════════════════════════════════════════════════╝
EOF
    echo -e "${N}"
    echo -e "  ${W}Distro :${N} Ubuntu 22.04 LTS"
    echo -e "  ${W}User   :${N} ${ADMIN_USER}  (pass: ${ADMIN_PASS})"
    echo ""
}

# ══════════════════════════════════════════════════════════
detect_device() {
    echo -e "${P}[*] Mendeteksi GPU...${N}"
    local brand gpu_egl
    brand=$(getprop ro.product.brand 2>/dev/null || echo "")
    gpu_egl=$(getprop ro.hardware.egl 2>/dev/null || echo "")
    echo -e "  Brand: ${W}${brand}${N}  EGL: ${D}${gpu_egl:-?}${N}"

    local is_adreno=false
    [[ "${gpu_egl,,}" == *"adreno"* || "${gpu_egl,,}" == *"freedreno"* ]] && is_adreno=true
    [ -e "/dev/kgsl-3d0" ] && is_adreno=true
    [[ "${brand,,}" =~ ^(xiaomi|redmi|poco|oneplus|motorola|moto|realme|oppo|vivo)$ ]] && is_adreno=true

    if [ "${is_adreno}" = "true" ]; then
        GPU_MODE="turnip"
        echo -e "  GPU: ${G}Adreno → Turnip/Vulkan HW accel${N}\n"
    else
        echo -e "  GPU: ${Y}Non-Adreno → Zink/software fallback${N}\n"
    fi
}

# ══════════════════════════════════════════════════════════
confirm_start() {
    echo -e "${Y}Yang akan diinstall:${N}"
    echo    "  [Termux] termux-x11-nightly, proot-distro, pulseaudio, mesa-zink"
    echo    "  [Ubuntu] XFCE4, Firefox, LibreOffice, GIMP, VLC, Python3, NodeJS"
    echo    "  [User]   admin / admin (sudo NOPASSWD)"
    echo    "  Estimasi: ~1.5-2 GB, 10-30 menit\n"
    read -rp "  Lanjutkan? [Y/n]: " _ans
    [[ "${_ans:-Y}" =~ ^[Nn]$ ]] && echo "Dibatalkan." && exit 0
    echo ""
}

# ══════════════════════════════════════════════════════════
# STEP 1 — Paket Termux
# ══════════════════════════════════════════════════════════
step1_termux_packages() {
    progress
    echo -e "${P}[Step ${CURRENT_STEP}] Install paket Termux...${N}\n"

    ("${TERMUX_BIN}/pkg" update -y >/dev/null 2>&1) & spinner $! "[Termux] pkg update"
    tpkg "x11-repo"
    tpkg "tur-repo"
    ("${TERMUX_BIN}/pkg" update -y >/dev/null 2>&1) & spinner $! "[Termux] pkg update (post-repo)"
    tpkg "termux-x11-nightly"
    tpkg "xorg-xrandr"
    tpkg "proot-distro"
    tpkg "proot"
    tpkg "pulseaudio"
    tpkg "mesa-zink"
    [ "${GPU_MODE}" = "turnip" ] && tpkg "mesa-vulkan-icd-freedreno"
    tpkg "vulkan-loader-android"
    tpkg "imagemagick"
    echo ""
}

# ══════════════════════════════════════════════════════════
# STEP 2 — Install rootfs Ubuntu 22.04
# ══════════════════════════════════════════════════════════
step2_install_ubuntu() {
    progress
    echo -e "${P}[Step ${CURRENT_STEP}] Install Ubuntu 22.04 rootfs...${N}\n"

    if [ -f "${PROOT_ROOTFS}/bin/bash" ]; then
        echo -e "  ${Y}[!] Ubuntu sudah ada, melewati download.${N}\n"
        return 0
    fi
    echo -e "  ${D}Download ~400MB...${N}\n"
    (proot-distro install "${PROOT_DISTRO}" >/dev/null 2>&1) &
    spinner $! "[Ubuntu] Download & extract rootfs"

    [ ! -f "${PROOT_ROOTFS}/bin/bash" ] && \
        echo -e "\n  ${R}[✗] GAGAL: rootfs tidak terbentuk. Cek koneksi.${N}" && exit 1
    echo -e "  ${G}[✓] Ubuntu rootfs siap.${N}\n"
}

# ══════════════════════════════════════════════════════════
# STEP 3 — Update Ubuntu & dependensi dasar
# ══════════════════════════════════════════════════════════
step3_ubuntu_base() {
    progress
    echo -e "${P}[Step ${CURRENT_STEP}] Update Ubuntu & install base deps...${N}\n"

    (ubuntu_run_quiet "
        DEBIAN_FRONTEND=noninteractive
        apt-get update -y -q
        apt-get upgrade -y -q -o Dpkg::Options::='--force-confold'
    ") & spinner $! "[Ubuntu] apt update & upgrade"

    ubuntu_pkg "sudo" "sudo"
    ubuntu_pkg "curl wget git nano htop unzip ca-certificates" "system utils"
    ubuntu_pkg "dbus dbus-x11" "dbus"
    ubuntu_pkg "x11-apps x11-utils x11-xserver-utils" "X11 utils"
    ubuntu_pkg "libx11-6 libxext6 libxrender1 libxrandr2 libxi6" "X11 libs"
    ubuntu_pkg "libgl1 libgles2 libvulkan1 mesa-utils" "Mesa stubs"
    ubuntu_pkg "pulseaudio-utils" "PulseAudio client"

    # Font: RAW output karena sering stuck/lambat — error langsung kelihatan
    ubuntu_pkg_verbose \
        "fonts-noto fonts-noto-color-emoji fonts-liberation" \
        "fonts (noto + emoji)"

    echo ""
}

# ══════════════════════════════════════════════════════════
# STEP 4 — Install XFCE4
# ══════════════════════════════════════════════════════════
step4_ubuntu_xfce() {
    progress
    echo -e "${P}[Step ${CURRENT_STEP}] Install XFCE4...${N}"
    echo -e "  ${Y}⚠  Proses terlama (~1GB). Harap tunggu...${N}\n"

    ubuntu_pkg \
        "xfce4 xfce4-terminal xfce4-whiskermenu-plugin
         xfce4-notifyd xfce4-screenshooter xfce4-taskmanager" \
        "XFCE4 core"

    ubuntu_pkg \
        "thunar thunar-archive-plugin mousepad ristretto xarchiver" \
        "Thunar + tools"

    ubuntu_pkg "firefox" "Firefox"

    ubuntu_pkg \
        "libreoffice-writer libreoffice-calc libreoffice-impress" \
        "LibreOffice"

    ubuntu_pkg "gimp vlc" "GIMP & VLC"

    ubuntu_pkg \
        "python3 python3-pip python3-venv nodejs npm build-essential git" \
        "Python3, Node.js, build tools"

    echo ""
}

# ══════════════════════════════════════════════════════════
# STEP 5 — Buat user admin
# ══════════════════════════════════════════════════════════
step5_create_admin() {
    progress
    echo -e "${P}[Step ${CURRENT_STEP}] Buat user '${ADMIN_USER}'...${N}\n"

    ubuntu_run "
        DEBIAN_FRONTEND=noninteractive
        apt-get install -y -q sudo >/dev/null 2>&1

        if id '${ADMIN_USER}' >/dev/null 2>&1; then
            echo '[skip] User sudah ada'
        else
            useradd -m -s /bin/bash -c 'Administrator' '${ADMIN_USER}'
            echo '[✓] User dibuat'
        fi

        echo '${ADMIN_USER}:${ADMIN_PASS}' | chpasswd
        usermod -aG sudo '${ADMIN_USER}' 2>/dev/null || true
        groupadd -f adm 2>/dev/null || true
        usermod -aG adm  '${ADMIN_USER}' 2>/dev/null || true

        mkdir -p /etc/sudoers.d
        cat > /etc/sudoers.d/admin-nopasswd << 'SUDO_EOF'
Defaults !requiretty
Defaults !env_reset
admin ALL=(ALL:ALL) NOPASSWD: ALL
SUDO_EOF
        chmod 0440 /etc/sudoers.d/admin-nopasswd
        chmod u+s  /usr/bin/sudo 2>/dev/null || true
        mkdir -p '/home/${ADMIN_USER}'
        chown -R '${ADMIN_USER}:${ADMIN_USER}' '/home/${ADMIN_USER}'

        cat > '/home/${ADMIN_USER}/.bashrc' << 'BASH_EOF'
case \$- in *i*) ;; *) return;; esac
export PS1='\[\033[01;32m\]admin@ubuntu\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
export DISPLAY=:0
export PULSE_SERVER=127.0.0.1
export XDG_RUNTIME_DIR=/tmp
alias ll='ls -la --color=auto'
alias update='sudo apt update && sudo apt upgrade -y'
alias install='sudo apt install -y'
[ -f ~/.gpu-env.sh ] && source ~/.gpu-env.sh
BASH_EOF
        chown '${ADMIN_USER}:${ADMIN_USER}' '/home/${ADMIN_USER}/.bashrc'
        id '${ADMIN_USER}'
    "
    echo -e "\n  ${G}[✓] User admin siap — sudo NOPASSWD${N}\n"
}

# ══════════════════════════════════════════════════════════
# STEP 6 — XFCE4 theme config
# ══════════════════════════════════════════════════════════
step6_xfce_theme() {
    progress
    echo -e "${P}[Step ${CURRENT_STEP}] Konfigurasi XFCE4 theme...${N}\n"

    mkdir -p \
        "${PROOT_HOME}/.config/xfce4/xfconf/xfce-perchannel-xml" \
        "${PROOT_HOME}/.config/autostart" \
        "${PROOT_HOME}/Desktop" \
        "${PROOT_HOME}/Pictures"

    cat > "${PROOT_HOME}/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xsettings" version="1.0">
  <property name="Net" type="empty">
    <property name="ThemeName"     type="string" value="Adwaita-dark"/>
    <property name="IconThemeName" type="string" value="Adwaita"/>
  </property>
  <property name="Xft" type="empty">
    <property name="DPI"       type="int"    value="96"/>
    <property name="Antialias" type="int"    value="1"/>
    <property name="Hinting"   type="int"    value="1"/>
    <property name="HintStyle" type="string" value="hintslight"/>
    <property name="RGBA"      type="string" value="rgb"/>
  </property>
  <property name="Gtk" type="empty">
    <property name="FontName"          type="string" value="Noto Sans 11"/>
    <property name="MonospaceFontName" type="string" value="Liberation Mono 10"/>
  </property>
</channel>
EOF

    cat > "${PROOT_HOME}/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="theme"             type="string" value="Default-xhdpi"/>
    <property name="use_compositing"   type="bool"   value="true"/>
    <property name="frame_opacity"     type="int"    value="95"/>
    <property name="show_frame_shadow" type="bool"   value="true"/>
    <property name="snap_to_border"    type="bool"   value="true"/>
    <property name="tile_on_move"      type="bool"   value="true"/>
    <property name="button_layout"     type="string" value="O|SHMC"/>
  </property>
</channel>
EOF

    cat > "${PROOT_HOME}/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-terminal.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-terminal" version="1.0">
  <property name="color-foreground" type="string" value="#f8f8f2"/>
  <property name="color-background" type="string" value="#282a36"/>
  <property name="color-palette"    type="string"
    value="#21222c;#ff5555;#50fa7b;#f1fa8c;#bd93f9;#ff79c6;#8be9fd;#f8f8f2;#6272a4;#ff6e6e;#69ff94;#ffffa5;#d6acff;#ff92df;#a4ffff;#ffffff"/>
  <property name="font-name"        type="string" value="Liberation Mono 11"/>
  <property name="scrolling-lines"  type="uint"   value="5000"/>
</channel>
EOF

    cat > "${PROOT_HOME}/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-keyboard-shortcuts" version="1.0">
  <property name="commands" type="empty">
    <property name="custom" type="empty">
      <property name="&lt;Super&gt;e" type="string" value="thunar"/>
      <property name="&lt;Super&gt;t" type="string" value="xfce4-terminal"/>
      <property name="Print"          type="string" value="xfce4-screenshooter"/>
    </property>
  </property>
  <property name="xfwm4" type="empty">
    <property name="custom" type="empty">
      <property name="&lt;Alt&gt;F4"      type="string" value="close_window_key"/>
      <property name="&lt;Super&gt;d"     type="string" value="show_desktop_key"/>
      <property name="&lt;Super&gt;Left"  type="string" value="tile_left_key"/>
      <property name="&lt;Super&gt;Right" type="string" value="tile_right_key"/>
      <property name="&lt;Super&gt;Up"    type="string" value="maximize_window_key"/>
    </property>
  </property>
</channel>
EOF

    for f in Terminal Files Firefox; do
        case $f in
            Terminal) exec_="xfce4-terminal"; icon_="utilities-terminal" ;;
            Files)    exec_="thunar";         icon_="folder" ;;
            Firefox)  exec_="firefox %u";    icon_="firefox" ;;
        esac
        cat > "${PROOT_HOME}/Desktop/${f}.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=${f}
Exec=${exec_}
Icon=${icon_}
EOF
    done

    local wp_dst="${PROOT_HOME}/Pictures/wallpaper.jpg"
    command -v convert >/dev/null 2>&1 && \
        (convert -size 1920x1080 gradient:"#1a1b2e"-"#16213e" "${wp_dst}" 2>/dev/null) &
        spinner $! "Generate wallpaper"

    ubuntu_run_quiet "chown -R ${ADMIN_USER}:${ADMIN_USER} /home/${ADMIN_USER}" || true
    echo -e "  ${G}[✓] XFCE4 theme: Adwaita-dark + Dracula terminal${N}\n"
}

# ══════════════════════════════════════════════════════════
# STEP 7 — GPU env script
# ══════════════════════════════════════════════════════════
step7_gpu_env() {
    progress
    echo -e "${P}[Step ${CURRENT_STEP}] Setup GPU env...${N}\n"

    cat > "${PROOT_HOME}/.gpu-env.sh" << GPUEOF
#!/bin/bash
# ~/.gpu-env.sh — GPU environment untuk XFCE4

export MESA_NO_ERROR=1
export MESA_GL_VERSION_OVERRIDE=4.6
export MESA_GLES_VERSION_OVERRIDE=3.2
export MESA_LOADER_DRIVER_OVERRIDE=zink
export GALLIUM_DRIVER=zink
export MESA_VK_WSI_PRESENT_MODE=immediate
export ZINK_DESCRIPTORS=lazy
export TU_DEBUG=noconform

_VK_TERMUX_DIR="/usr/share/vulkan/icd.d.termux"
if [ -f "\${_VK_TERMUX_DIR}/freedreno_icd.aarch64.json" ]; then
    export VK_ICD_FILENAMES="\${_VK_TERMUX_DIR}/freedreno_icd.aarch64.json"
fi

export DISPLAY=:0
export PULSE_SERVER=127.0.0.1
export XDG_RUNTIME_DIR=/tmp
export XDG_DATA_DIRS=/usr/share:/usr/local/share
GPUEOF

    chmod +x "${PROOT_HOME}/.gpu-env.sh"
    ubuntu_run_quiet "chown ${ADMIN_USER}:${ADMIN_USER} /home/${ADMIN_USER}/.gpu-env.sh" || true
    echo -e "  ${G}[✓] ~/.gpu-env.sh — mode: ${GPU_MODE}${N}\n"
}

# ══════════════════════════════════════════════════════════
# STEP 8 — Buat launcher scripts
# ══════════════════════════════════════════════════════════
step8_launchers() {
    progress
    echo -e "${P}[Step ${CURRENT_STEP}] Membuat launcher scripts...${N}\n"

    # ── start-xfce.sh ─────────────────────────────────────
    {
        cat << 'HDR'
#!/data/data/com.termux/files/usr/bin/bash
# start-xfce.sh — Jalankan XFCE4 Ubuntu via Termux-X11
HDR
        cat << VARS
PROOT_DISTRO="${PROOT_DISTRO}"
ADMIN_USER="${ADMIN_USER}"
TERMUX_TMP="\${TMPDIR:-/data/data/com.termux/files/usr/tmp}"
TERMUX_VK_ICD="/data/data/com.termux/files/usr/share/vulkan/icd.d"
TERMUX_LIB="/data/data/com.termux/files/usr/lib"
VARS
        cat << 'BODY'

echo "  [*] Membersihkan sesi lama..."
pkill -9 -f "com.termux.x11" 2>/dev/null; pkill -9 -f "termux-x11" 2>/dev/null
pkill -9 -f "xfce4-session"  2>/dev/null; pkill -9 -f "dbus-daemon" 2>/dev/null
sleep 0.5

echo "  [*] Starting PulseAudio..."
unset PULSE_SERVER
pulseaudio --kill 2>/dev/null; sleep 0.3
pulseaudio --start --exit-idle-time=-1 --daemonize=true \
    --log-target="file:${TERMUX_TMP}/pulseaudio.log" 2>/dev/null
sleep 1
pactl load-module module-native-protocol-tcp \
    auth-ip-acl=127.0.0.1 auth-anonymous=1 2>/dev/null || true
echo "  [✓] PulseAudio ready"

echo "  [*] Starting Termux-X11 (:0)..."
termux-x11 :0 -ac &
X11_PID=$!
sleep 2

X11_SOCK="${TERMUX_TMP}/.X11-unix"
if [ ! -S "${X11_SOCK}/X0" ]; then
    echo "  [!] ERROR: Socket X11 tidak ada: ${X11_SOCK}/X0"
    echo "      Buka app Termux:X11 di Android, lalu coba lagi."
    kill $X11_PID 2>/dev/null; exit 1
fi
echo "  [✓] Termux-X11 ready"

# Susun bind mounts
BINDS="--bind ${X11_SOCK}:/tmp/.X11-unix"
[ -d "/dev/dri" ]             && BINDS="${BINDS} --bind /dev/dri:/dev/dri"
[ -e "/dev/kgsl-3d0" ]        && BINDS="${BINDS} --bind /dev/kgsl-3d0:/dev/kgsl-3d0"
[ -e "/dev/mali0" ]           && BINDS="${BINDS} --bind /dev/mali0:/dev/mali0"
[ -d "${TERMUX_VK_ICD}" ]     && BINDS="${BINDS} --bind ${TERMUX_VK_ICD}:/usr/share/vulkan/icd.d.termux"
[ -f "${TERMUX_LIB}/libvulkan.so" ] && \
    BINDS="${BINDS} --bind ${TERMUX_LIB}/libvulkan.so:/usr/lib/aarch64-linux-gnu/libvulkan_termux.so"

echo "  [*] Masuk Ubuntu, login sebagai: ${ADMIN_USER}"
echo "  [*] Buka app Termux:X11 di Android untuk melihat desktop!"
echo ""

proot-distro login "${PROOT_DISTRO}" ${BINDS} -- bash -c '
    chmod 1777 /tmp 2>/dev/null || true
    mkdir -p /tmp/.X11-unix && chmod 1777 /tmp/.X11-unix 2>/dev/null || true

    if [ ! -S /tmp/.X11-unix/X0 ]; then
        echo "[!] Error: bind X11 socket gagal"; exit 1
    fi

    su - '"${ADMIN_USER}"' -c "
        [ -f ~/.gpu-env.sh ] && source ~/.gpu-env.sh
        echo \"  GPU: \${GALLIUM_DRIVER:-?}  GL: \${MESA_GL_VERSION_OVERRIDE:-?}  DISP: \${DISPLAY}\"
        exec dbus-run-session -- startxfce4
    "
'

EXIT_CODE=$?
[ ${EXIT_CODE} -eq 0 ] \
    && echo "  [✓] Sesi XFCE4 berakhir normal." \
    || echo "  [!] XFCE4 keluar (rc=${EXIT_CODE}). Log: ${TERMUX_TMP}/pulseaudio.log"
BODY
    } > ~/start-xfce.sh
    chmod +x ~/start-xfce.sh
    echo -e "  ${G}[✓] ~/start-xfce.sh${N}"

    # ── shell-ubuntu.sh ───────────────────────────────────
    {
        cat << 'HDR'
#!/data/data/com.termux/files/usr/bin/bash
# shell-ubuntu.sh — Masuk shell Ubuntu sebagai admin
HDR
        cat << VARS
PROOT_DISTRO="${PROOT_DISTRO}"
ADMIN_USER="${ADMIN_USER}"
TERMUX_TMP="\${TMPDIR:-/data/data/com.termux/files/usr/tmp}"
TERMUX_VK_ICD="/data/data/com.termux/files/usr/share/vulkan/icd.d"
VARS
        cat << 'BODY'
BINDS=""
X11_SOCK="${TERMUX_TMP}/.X11-unix"
[ -d "${X11_SOCK}" ]       && BINDS="${BINDS} --bind ${X11_SOCK}:/tmp/.X11-unix"
[ -d "/dev/dri" ]           && BINDS="${BINDS} --bind /dev/dri:/dev/dri"
[ -e "/dev/kgsl-3d0" ]      && BINDS="${BINDS} --bind /dev/kgsl-3d0:/dev/kgsl-3d0"
[ -d "${TERMUX_VK_ICD}" ]   && BINDS="${BINDS} --bind ${TERMUX_VK_ICD}:/usr/share/vulkan/icd.d.termux"
proot-distro login "${PROOT_DISTRO}" ${BINDS} -- bash -c "su - ${ADMIN_USER}"
BODY
    } > ~/shell-ubuntu.sh
    chmod +x ~/shell-ubuntu.sh
    echo -e "  ${G}[✓] ~/shell-ubuntu.sh${N}"

    # ── stop-xfce.sh ──────────────────────────────────────
    cat > ~/stop-xfce.sh << 'STOP'
#!/data/data/com.termux/files/usr/bin/bash
# stop-xfce.sh — Hentikan semua sesi
echo "  [*] Stopping..."
pkill -9 -f "com.termux.x11" 2>/dev/null; pkill -9 -f "termux-x11" 2>/dev/null
pkill -9 -f "pulseaudio"     2>/dev/null; pkill -9 -f "xfce4-session" 2>/dev/null
pkill -9 -f "xfwm4"          2>/dev/null; pkill -9 -f "dbus-daemon" 2>/dev/null
rm -f /tmp/.X0-lock 2>/dev/null
echo "  [✓] Selesai."
STOP
    chmod +x ~/stop-xfce.sh
    echo -e "  ${G}[✓] ~/stop-xfce.sh${N}\n"
}

# ══════════════════════════════════════════════════════════
show_done() {
    echo -e "\n${G}"
    cat << 'EOF'
  ╔════════════════════════════════════════════════════╗
  ║      ✓  INSTALASI SELESAI!                        ║
  ╚════════════════════════════════════════════════════╝
EOF
    echo -e "${N}"
    echo -e "  ${W}User   :${N} ${ADMIN_USER} / ${ADMIN_PASS}  (sudo NOPASSWD)"
    echo -e "  ${W}GPU    :${N} ${GPU_MODE}"
    echo ""
    echo -e "  ${G}Jalankan XFCE4:${N}       ${W}bash ~/start-xfce.sh${N}"
    echo -e "  ${G}Shell Ubuntu  :${N}       ${W}bash ~/shell-ubuntu.sh${N}"
    echo -e "  ${G}Stop semua    :${N}       ${W}bash ~/stop-xfce.sh${N}"
    echo ""
    echo -e "  ${Y}Troubleshooting:${N}"
    echo    "  • Layar hitam   → termux-x11 :0 -legacy-drawing -ac"
    echo    "  • Warna balik   → termux-x11 :0 -force-bgra -ac"
    echo    "  • X11 error     → Buka app Termux:X11 SEBELUM start-xfce.sh"
    echo    "  • dbus crash    → sudo apt install dbus dbus-x11 (di shell-ubuntu.sh)"
    echo ""
}

# ══════════════════════════════════════════════════════════
main() {
    [ ! -d "/data/data/com.termux" ] || [ ! -x "${TERMUX_PREFIX}/bin/bash" ] && \
        echo "Error: Jalankan di dalam Termux!" && exit 1

    banner
    detect_device
    confirm_start
    step1_termux_packages
    step2_install_ubuntu
    step3_ubuntu_base
    step4_ubuntu_xfce
    step5_create_admin
    step6_xfce_theme
    step7_gpu_env
    step8_launchers
    show_done
}

main