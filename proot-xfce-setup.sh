#!/data/data/com.termux/files/usr/bin/bash
# =============================================================
#  proot-xfce-setup.sh  —  v2.0
#
#  Install XFCE4 di Ubuntu 22.04 (proot-distro) lalu
#  jalankan via Termux-X11.
#
#  ARSITEKTUR:
#  ┌─────────────────────────────────────────────────────┐
#  │  TERMUX (Android)                                   │
#  │  • proot-distro  → mengelola Ubuntu rootfs          │
#  │  • termux-x11    → X display server (:0)            │
#  │  • pulseaudio    → audio bridge ke Android          │
#  │  • mesa-zink     → GPU driver (di-bind ke Ubuntu)   │
#  │                                                     │
#  │  UBUNTU 22.04 (proot, shared kernel Android)        │
#  │  • XFCE4 + semua app  ← apt install bebas           │
#  │  • user: admin  (pass: admin, sudo NOPASSWD)        │
#  │  • dbus-run-session → startxfce4                    │
#  └─────────────────────────────────────────────────────┘
#
#  Launcher yang dihasilkan (di ~/):
#    start-xfce.sh    — jalankan XFCE4 via Termux-X11
#    shell-ubuntu.sh  — masuk shell Ubuntu sebagai admin
#    stop-xfce.sh     — hentikan semua sesi
#    start-vnc.sh     — (opsional) VNC remote desktop
# =============================================================

# Tidak pakai set -e: satu paket gagal tidak boleh
# menghentikan seluruh instalasi
set -uo pipefail

# ══════════════════════════════════════════════════════════
#  KONSTANTA — Ubuntu only, user admin hardcoded
# ══════════════════════════════════════════════════════════
readonly PROOT_DISTRO="ubuntu"
readonly PROOT_LABEL="Ubuntu 22.04 LTS"
readonly ADMIN_USER="admin"
readonly ADMIN_PASS="admin"

readonly TERMUX_PREFIX="/data/data/com.termux/files/usr"
readonly TERMUX_BIN="${TERMUX_PREFIX}/bin"
TERMUX_TMP="${TMPDIR:-${TERMUX_PREFIX}/tmp}"
readonly TERMUX_VK_ICD="${TERMUX_PREFIX}/share/vulkan/icd.d"
readonly TERMUX_LIB="${TERMUX_PREFIX}/lib"
readonly PROOT_ROOTFS="${TERMUX_PREFIX}/var/lib/proot-distro/installed-rootfs/${PROOT_DISTRO}"
readonly PROOT_HOME="${PROOT_ROOTFS}/home/${ADMIN_USER}"

TOTAL_STEPS=9
CURRENT_STEP=0
GPU_MODE="zink"      # diupdate oleh detect_device()
VNC_ENABLED=false
VNC_PASS="admin123"
VNC_GEO="1280x720"

# ══════════════════════════════════════════════════════════
#  WARNA
# ══════════════════════════════════════════════════════════
R='\033[0;31m'   # red
G='\033[0;32m'   # green
Y='\033[1;33m'   # yellow
C='\033[0;36m'   # cyan
W='\033[1;37m'   # white bold
D='\033[0;90m'   # dark gray
P='\033[0;35m'   # purple
N='\033[0m'      # reset

# ══════════════════════════════════════════════════════════
#  PROGRESS BAR
# ══════════════════════════════════════════════════════════
progress() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    local pct=$((CURRENT_STEP * 100 / TOTAL_STEPS))
    local filled=$((pct / 5))
    local empty=$((20 - filled))
    local bar="${G}" i
    for ((i=0; i<filled; i++)); do bar+="█"; done
    bar+="${D}"
    for ((i=0; i<empty; i++)); do bar+="░"; done
    bar+="${N}"
    echo ""
    echo -e "${W}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}"
    echo -e "${C}  STEP ${CURRENT_STEP}/${TOTAL_STEPS}  ${bar}  ${W}${pct}%${N}"
    echo -e "${W}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}"
    echo ""
}

# ══════════════════════════════════════════════════════════
#  SPINNER — tampilkan animasi selagi background job berjalan
# ══════════════════════════════════════════════════════════
spinner() {
    local pid=$1 msg=$2
    local sp='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    while kill -0 "${pid}" 2>/dev/null; do
        printf "\r  ${C}[%s]${N} %s " "${sp:$((i % ${#sp})):1}" "${msg}"
        i=$((i+1)); sleep 0.1
    done
    wait "${pid}"; local rc=$?
    if [ $rc -eq 0 ]; then
        printf "\r  ${G}[✓]${N} %-55s\n" "${msg}"
    else
        printf "\r  ${R}[✗]${N} %-55s ${R}(error ${rc})${N}\n" "${msg}"
    fi
    return $rc
}

# ══════════════════════════════════════════════════════════
#  HELPER: install paket di TERMUX
#
#  Gunakan `pkg` (bukan apt-get langsung) karena:
#  - pkg menangani repo x11-repo & tur-repo dengan benar
#  - pkg otomatis resolve dependency Termux-spesifik
# ══════════════════════════════════════════════════════════
tpkg() {
    local pkg=$1
    ("${TERMUX_BIN}/pkg" install -y "${pkg}" >/dev/null 2>&1) &
    spinner $! "[Termux] pkg install ${pkg}"
}

# ══════════════════════════════════════════════════════════
#  HELPER: jalankan perintah DI DALAM Ubuntu
#
#  proot-distro login default = masuk sebagai root.
#  Ini yang kita pakai untuk setup (apt install, useradd, dll).
#  Untuk menjalankan sebagai admin, gunakan su - admin di dalam.
#
#  TIDAK pakai --shared-tmp karena kita bind X11 socket
#  secara eksplisit di launcher. Untuk fase setup (tanpa X11)
#  cukup tanpa bind apapun.
# ══════════════════════════════════════════════════════════
ubuntu_run() {
    # Jalankan sebagai root di dalam Ubuntu, output tampil
    proot-distro login "${PROOT_DISTRO}" -- bash -c "$1"
}

ubuntu_run_quiet() {
    # Sama seperti ubuntu_run tapi output disupres
    proot-distro login "${PROOT_DISTRO}" -- bash -c "$1" >/dev/null 2>&1
}

ubuntu_pkg() {
    # Install paket di Ubuntu (foreground dengan spinner)
    local pkgs="$1" label="${2:-$1}"
    (ubuntu_run_quiet "
        export DEBIAN_FRONTEND=noninteractive
        apt-get install -y -q \
            -o Dpkg::Options::='--force-confold' \
            -o APT::Get::Assume-Yes=true \
            ${pkgs}
    ") &
    spinner $! "[Ubuntu] apt install ${label}"
}

# ══════════════════════════════════════════════════════════
#  BANNER
# ══════════════════════════════════════════════════════════
banner() {
    clear
    echo -e "${C}"
    cat << 'EOF'
  ╔════════════════════════════════════════════════════╗
  ║                                                    ║
  ║   proot-xfce-setup.sh  v2.0                       ║
  ║                                                    ║
  ║   Ubuntu 22.04  →  XFCE4  →  Termux-X11           ║
  ║   Full apt support  ·  GPU Accel  ·  Audio         ║
  ║                                                    ║
  ╚════════════════════════════════════════════════════╝
EOF
    echo -e "${N}"
    echo -e "  ${W}Distro :${N} Ubuntu 22.04 LTS (hardcoded)"
    echo -e "  ${W}User   :${N} ${ADMIN_USER}  (pass: ${ADMIN_PASS})"
    echo ""
}

# ══════════════════════════════════════════════════════════
#  DETEKSI GPU
# ══════════════════════════════════════════════════════════
detect_device() {
    echo -e "${P}[*] Mendeteksi perangkat & GPU...${N}"
    local brand model aver gpu_egl
    brand=$(getprop ro.product.brand 2>/dev/null || echo "Unknown")
    model=$(getprop ro.product.model 2>/dev/null || echo "Unknown")
    aver=$(getprop ro.build.version.release 2>/dev/null || echo "?")
    gpu_egl=$(getprop ro.hardware.egl 2>/dev/null || echo "")

    echo -e "  Perangkat : ${W}${brand} ${model}${N}"
    echo -e "  Android   : ${W}${aver}${N}"
    echo -e "  EGL prop  : ${D}${gpu_egl:-tidak terdeteksi}${N}"

    # Adreno: cek EGL property, lalu fallback ke /dev/kgsl-3d0
    local is_adreno=false
    [[ "${gpu_egl,,}" == *"adreno"* ]]    && is_adreno=true
    [[ "${gpu_egl,,}" == *"freedreno"* ]] && is_adreno=true
    [ -e "/dev/kgsl-3d0" ]                && is_adreno=true

    # Brand Snapdragon umum (bukan Samsung — Samsung bisa Mali)
    if [[ "${brand,,}" =~ ^(xiaomi|redmi|poco|oneplus|motorola|moto|realme|oppo|vivo)$ ]]; then
        is_adreno=true
    fi

    if [ "${is_adreno}" = "true" ]; then
        GPU_MODE="turnip"
        echo -e "  GPU       : ${G}Adreno terdeteksi — Turnip/Vulkan HW accel${N}"
    else
        GPU_MODE="zink"
        echo -e "  GPU       : ${Y}Non-Adreno — Zink/LLVMpipe software fallback${N}"
    fi
    echo ""
}

# ══════════════════════════════════════════════════════════
#  KONFIRMASI
# ══════════════════════════════════════════════════════════
confirm_start() {
    echo -e "${Y}Yang akan diinstall:${N}"
    echo    "  [Termux]  x11-repo, tur-repo, termux-x11-nightly,"
    echo    "            proot-distro, pulseaudio, mesa-zink,"
    if [ "${GPU_MODE}" = "turnip" ]; then
    echo    "            mesa-vulkan-icd-freedreno (Adreno GPU)"
    fi
    echo    "  [Ubuntu]  XFCE4, xfce4-terminal, thunar, mousepad,"
    echo    "            firefox, libreoffice, gimp, vlc,"
    echo    "            python3, nodejs, build-essential"
    echo    "  [User]    admin / admin  (sudo NOPASSWD)"
    echo    ""
    echo    "  Estimasi: ~1.5–2 GB download, 10–30 menit"
    echo    ""
    read -rp "  Lanjutkan instalasi? [Y/n]: " _ans
    _ans="${_ans:-Y}"
    [[ "${_ans}" =~ ^[Nn]$ ]] && echo "Dibatalkan." && exit 0
    echo ""
}

# ══════════════════════════════════════════════════════════
#  STEP 1: Paket Termux
#
#  Semua di bawah ini BERJALAN DI TERMUX, bukan di Ubuntu.
#  Termux adalah environment Android yang menjalankan:
#    - termux-x11 : X display server (native Android)
#    - proot-distro: manager rootfs Ubuntu
#    - pulseaudio  : audio server (Android-side)
#    - mesa-zink   : GPU driver yang akan di-bind ke Ubuntu
# ══════════════════════════════════════════════════════════
step1_termux_packages() {
    progress
    echo -e "${P}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Install paket Termux...${N}"
    echo -e "  ${D}▸ Berjalan di Termux/Android${N}\n"

    # Update index paket
    ("${TERMUX_BIN}/pkg" update -y >/dev/null 2>&1) &
    spinner $! "[Termux] pkg update"

    # x11-repo: repository tambahan untuk paket X11 Termux
    # Harus diinstall sebelum termux-x11-nightly & mesa
    tpkg "x11-repo"

    # tur-repo: repository Termux User Repository
    # Berisi paket extra seperti beberapa mesa variant
    tpkg "tur-repo"

    # Update ulang setelah repo baru aktif
    ("${TERMUX_BIN}/pkg" update -y >/dev/null 2>&1) &
    spinner $! "[Termux] pkg update (setelah repo baru)"

    # termux-x11-nightly: companion package untuk app Termux:X11
    # Menyediakan binary `termux-x11` yang dijalankan dari Termux
    # untuk memulai X display server di Android
    tpkg "termux-x11-nightly"

    # xorg-xrandr: tool untuk set resolusi X display
    tpkg "xorg-xrandr"

    # proot-distro: manager untuk install, login, remove distro Linux
    tpkg "proot-distro"

    # proot: engine chroot-like tanpa root Android
    # Ubuntu berjalan di atas ini dengan shared kernel Android
    tpkg "proot"

    # pulseaudio: audio server berjalan di Termux (Android-side)
    # Ubuntu konek via TCP ke 127.0.0.1 (bukan via socket /tmp)
    tpkg "pulseaudio"

    # mesa-zink: OpenGL-over-Vulkan driver
    # Di-bind dari Termux ke Ubuntu agar Ubuntu pakai driver terbaru
    tpkg "mesa-zink"

    # Turnip: open-source Vulkan driver untuk Adreno GPU
    # Hanya install jika terdeteksi GPU Adreno
    if [ "${GPU_MODE}" = "turnip" ]; then
        tpkg "mesa-vulkan-icd-freedreno"
        echo -e "  ${G}[✓] Turnip Vulkan driver (Adreno) installed${N}"
    fi

    # vulkan-loader-android: loader Vulkan untuk Android
    tpkg "vulkan-loader-android"

    # imagemagick: generate wallpaper gradient (tidak ada di Ubuntu apt
    # Ubuntu punya imagemagick sendiri, ini untuk generate dari Termux
    # sebelum Ubuntu selesai install)
    tpkg "imagemagick"

    echo ""
}

# ══════════════════════════════════════════════════════════
#  STEP 2: Download rootfs Ubuntu 22.04
# ══════════════════════════════════════════════════════════
step2_install_ubuntu() {
    progress
    echo -e "${P}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Install Ubuntu 22.04 rootfs...${N}\n"

    # Cek sudah terinstall — cek apakah /bin ada di rootfs
    if [ -f "${PROOT_ROOTFS}/bin/bash" ]; then
        echo -e "  ${Y}[!] Ubuntu sudah ada di:${N}"
        echo -e "      ${D}${PROOT_ROOTFS}${N}"
        echo -e "  ${Y}    Melewati download.${N}\n"
        return 0
    fi

    echo -e "  ${D}Download ~400MB, tergantung kecepatan internet...${N}\n"

    (proot-distro install "${PROOT_DISTRO}" >/dev/null 2>&1) &
    spinner $! "[Ubuntu] Download & extract rootfs"

    if [ ! -f "${PROOT_ROOTFS}/bin/bash" ]; then
        echo -e "\n  ${R}[✗] GAGAL: Ubuntu rootfs tidak terbentuk.${N}"
        echo -e "      Cek koneksi internet lalu jalankan ulang."
        exit 1
    fi
    echo -e "  ${G}[✓] Ubuntu rootfs siap.${N}\n"
}

# ══════════════════════════════════════════════════════════
#  STEP 3: Update Ubuntu & install dependensi dasar
#
#  Semua perintah di step ini BERJALAN DI DALAM Ubuntu,
#  dieksekusi oleh proot-distro login -- bash -c "..."
# ══════════════════════════════════════════════════════════
step3_ubuntu_base() {
    progress
    echo -e "${P}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Update Ubuntu & install base deps...${N}"
    echo -e "  ${D}▸ Berjalan di dalam Ubuntu (proot)${N}\n"

    # Update & upgrade Ubuntu packages
    (ubuntu_run_quiet "
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -y -q
        apt-get upgrade -y -q -o Dpkg::Options::='--force-confold'
    ") &
    spinner $! "[Ubuntu] apt update & upgrade"

    # sudo — WAJIB, diinstall eksplisit di step ini
    # (beberapa Ubuntu minimal image tidak menyertakan sudo)
    ubuntu_pkg "sudo" "sudo"

    # Tool dasar sistem
    ubuntu_pkg "curl wget git nano htop unzip ca-certificates" "system utils"

    # dbus-x11 — WAJIB untuk XFCE di proot
    # proot tidak punya systemd/logind, sehingga dbus-run-session
    # adalah satu-satunya cara menjalankan dbus session yang benar.
    # Tanpa ini, XFCE4 plugin akan crash / tidak load
    ubuntu_pkg "dbus dbus-x11" "dbus (wajib untuk XFCE session)"

    # X11 client libs — Ubuntu konek ke Termux-X11 display server
    # TIDAK install xserver-xorg (server ada di Termux, bukan Ubuntu!)
    ubuntu_pkg "x11-apps x11-utils x11-xserver-utils" "X11 client utils"
    ubuntu_pkg "libx11-6 libxext6 libxrender1 libxrandr2 libxi6" "X11 libraries"

    # Mesa stubs di Ubuntu
    # Driver aslinya (mesa-zink dari Termux) akan di-bind masuk via
    # --bind saat launcher dijalankan. Ubuntu perlu stub ini agar
    # binary XFCE tidak crash saat load library
    ubuntu_pkg "libgl1 libgles2 libvulkan1 mesa-utils" "Mesa & Vulkan stubs"

    # PulseAudio client — Ubuntu pakai ini untuk konek ke
    # pulseaudio yang berjalan di Termux via PULSE_SERVER=127.0.0.1
    ubuntu_pkg "pulseaudio-utils" "PulseAudio client"

    # Font lengkap (termasuk emoji)
    ubuntu_pkg "fonts-noto fonts-noto-color-emoji fonts-liberation" "fonts"

    echo ""
}

# ══════════════════════════════════════════════════════════
#  STEP 4: Install XFCE4 di dalam Ubuntu
#
#  Ini berjalan di dalam Ubuntu via proot.
#  Karena apt Ubuntu — semua binary tersedia tanpa batasan!
# ══════════════════════════════════════════════════════════
step4_ubuntu_xfce() {
    progress
    echo -e "${P}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Install XFCE4 di Ubuntu...${N}"
    echo -e "  ${Y}⚠  Proses terlama (~800MB - 1GB download). Harap tunggu...${N}\n"

    # XFCE4 desktop + plugin-plugin penting
    ubuntu_pkg \
        "xfce4 xfce4-terminal xfce4-whiskermenu-plugin
         xfce4-notifyd xfce4-screenshooter xfce4-taskmanager" \
        "XFCE4 core + plugins"

    # File manager & tools
    ubuntu_pkg \
        "thunar thunar-archive-plugin thunar-media-tags-plugin
         mousepad ristretto xarchiver" \
        "Thunar + tools"

    # Browser
    ubuntu_pkg "firefox" "Firefox"

    # Office suite
    ubuntu_pkg \
        "libreoffice-writer libreoffice-calc libreoffice-impress" \
        "LibreOffice"

    # Media & grafis
    ubuntu_pkg "gimp vlc" "GIMP & VLC"

    # Development tools — apt Ubuntu bebas install ini semua!
    ubuntu_pkg \
        "python3 python3-pip python3-venv
         nodejs npm build-essential git" \
        "Python3, Node.js, build tools"

    echo ""
}

# ══════════════════════════════════════════════════════════
#  STEP 5: Buat user admin di Ubuntu
#
#  Berjalan di dalam Ubuntu.
#  Admin dibuat dengan:
#  - username: admin, password: admin
#  - group: sudo + adm
#  - sudoers drop-in: NOPASSWD + !requiretty (wajib untuk proot)
# ══════════════════════════════════════════════════════════
step5_create_admin() {
    progress
    echo -e "${P}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Buat user '${ADMIN_USER}' di Ubuntu...${N}"
    echo -e "  ${D}▸ Berjalan di dalam Ubuntu (proot)${N}\n"

    ubuntu_run "
        export DEBIAN_FRONTEND=noninteractive

        echo '[*] Memastikan sudo terinstall...'
        apt-get install -y -q sudo >/dev/null 2>&1
        echo '[✓] sudo OK'

        # Buat user jika belum ada
        if id '${ADMIN_USER}' >/dev/null 2>&1; then
            echo '[skip] User ${ADMIN_USER} sudah ada, update password saja'
        else
            useradd -m -s /bin/bash -c 'Administrator' '${ADMIN_USER}'
            echo '[✓] User ${ADMIN_USER} dibuat'
        fi

        # Set password
        echo '${ADMIN_USER}:${ADMIN_PASS}' | chpasswd
        echo '[✓] Password set: ${ADMIN_PASS}'

        # Tambah ke group sudo (dan adm jika ada)
        usermod -aG sudo '${ADMIN_USER}' 2>/dev/null || true
        groupadd -f adm 2>/dev/null || true
        usermod -aG adm '${ADMIN_USER}' 2>/dev/null || true

        # Sudoers drop-in
        # !requiretty — wajib di proot: sudo tidak punya tty sungguhan
        # !env_reset  — jaga environment variable (DISPLAY, PULSE_SERVER, dll)
        # NOPASSWD    — tidak tanya password (proot tidak bisa pam_tty_audit)
        mkdir -p /etc/sudoers.d
        cat > /etc/sudoers.d/admin-nopasswd << 'SUDO_EOF'
# proot sudoers — jangan edit manual
Defaults !requiretty
Defaults !env_reset
admin ALL=(ALL:ALL) NOPASSWD: ALL
SUDO_EOF
        chmod 0440 /etc/sudoers.d/admin-nopasswd
        echo '[✓] Sudoers drop-in: /etc/sudoers.d/admin-nopasswd'

        # Pastikan sudo binary punya SUID bit
        # (meski proot mount nosuid, ini tetap dibutuhkan)
        chmod u+s /usr/bin/sudo 2>/dev/null || true

        # Pastikan /home/admin ada dan milik admin
        mkdir -p '/home/${ADMIN_USER}'
        chown -R '${ADMIN_USER}:${ADMIN_USER}' '/home/${ADMIN_USER}'
        echo '[✓] /home/${ADMIN_USER} ownership OK'

        # .bashrc untuk user admin
        cat > '/home/${ADMIN_USER}/.bashrc' << 'BASH_EOF'
# ~/.bashrc — Ubuntu proot (admin)
case \$- in *i*) ;; *) return;; esac

export PS1='\[\033[01;32m\]admin@ubuntu\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
export DISPLAY=:0
export PULSE_SERVER=127.0.0.1
export XDG_RUNTIME_DIR=/tmp
export HISTSIZE=1000
export HISTFILESIZE=2000
shopt -s histappend checkwinsize

alias ll='ls -la --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
alias cls='clear'
alias update='sudo apt update && sudo apt upgrade -y'
alias install='sudo apt install -y'
alias remove='sudo apt remove -y'

# Source GPU env jika ada
[ -f ~/.gpu-env.sh ] && source ~/.gpu-env.sh
BASH_EOF
        chown '${ADMIN_USER}:${ADMIN_USER}' '/home/${ADMIN_USER}/.bashrc'
        echo '[✓] .bashrc dibuat'

        echo ''
        echo '=== Verifikasi user admin ==='
        id '${ADMIN_USER}'
        echo ''
        grep -i 'admin' /etc/sudoers.d/admin-nopasswd || true
        echo ''
    "

    echo -e "\n  ${G}[✓] User admin siap  —  pass: ${ADMIN_PASS}  —  sudo NOPASSWD${N}\n"
}

# ══════════════════════════════════════════════════════════
#  STEP 6: Konfigurasi XFCE4 theme
#
#  Config ditulis langsung ke rootfs dari Termux
#  (path: PROOT_ROOTFS/home/admin/.config/...)
#  Lebih cepat dari menjalankan xfconf-query di dalam proot.
# ══════════════════════════════════════════════════════════
step6_xfce_theme() {
    progress
    echo -e "${P}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Konfigurasi XFCE4 theme...${N}\n"

    # Pastikan direktori config ada di rootfs
    mkdir -p \
        "${PROOT_HOME}/.config/xfce4/xfconf/xfce-perchannel-xml" \
        "${PROOT_HOME}/.config/autostart" \
        "${PROOT_HOME}/Desktop" \
        "${PROOT_HOME}/Pictures"

    # ── GTK theme: Adwaita-dark ────────────────────────────
    cat > "${PROOT_HOME}/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xsettings" version="1.0">
  <property name="Net" type="empty">
    <property name="ThemeName" type="string" value="Adwaita-dark"/>
    <property name="IconThemeName" type="string" value="Adwaita"/>
  </property>
  <property name="Xft" type="empty">
    <property name="DPI" type="int" value="96"/>
    <property name="Antialias" type="int" value="1"/>
    <property name="Hinting" type="int" value="1"/>
    <property name="HintStyle" type="string" value="hintslight"/>
    <property name="RGBA" type="string" value="rgb"/>
  </property>
  <property name="Gtk" type="empty">
    <property name="FontName" type="string" value="Noto Sans 11"/>
    <property name="MonospaceFontName" type="string" value="Liberation Mono 10"/>
    <property name="DecorationLayout" type="string" value="menu:minimize,maximize,close"/>
    <property name="MenuImages" type="bool" value="true"/>
    <property name="ButtonImages" type="bool" value="true"/>
  </property>
</channel>
EOF

    # ── Window manager: compositing ON ────────────────────
    cat > "${PROOT_HOME}/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="theme" type="string" value="Default-xhdpi"/>
    <property name="title_font" type="string" value="Noto Sans Bold 10"/>
    <property name="use_compositing" type="bool" value="true"/>
    <property name="frame_opacity" type="int" value="95"/>
    <property name="inactive_opacity" type="int" value="88"/>
    <property name="show_frame_shadow" type="bool" value="true"/>
    <property name="snap_to_border" type="bool" value="true"/>
    <property name="snap_to_windows" type="bool" value="true"/>
    <property name="tile_on_move" type="bool" value="true"/>
    <property name="wrap_workspaces" type="bool" value="false"/>
    <property name="button_layout" type="string" value="O|SHMC"/>
    <property name="shadow_opacity" type="int" value="50"/>
  </property>
</channel>
EOF

    # ── Terminal: Dracula color scheme ────────────────────
    cat > "${PROOT_HOME}/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-terminal.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-terminal" version="1.0">
  <property name="color-foreground"   type="string" value="#f8f8f2"/>
  <property name="color-background"   type="string" value="#282a36"/>
  <property name="color-cursor"       type="string" value="#f8f8f2"/>
  <property name="color-selection"    type="string" value="#44475a"/>
  <property name="color-palette"      type="string"
    value="#21222c;#ff5555;#50fa7b;#f1fa8c;#bd93f9;#ff79c6;#8be9fd;#f8f8f2;#6272a4;#ff6e6e;#69ff94;#ffffa5;#d6acff;#ff92df;#a4ffff;#ffffff"/>
  <property name="font-name"          type="string" value="Liberation Mono 11"/>
  <property name="misc-cursor-blinks" type="bool"   value="true"/>
  <property name="misc-cursor-shape"  type="uint"   value="1"/>
  <property name="scrolling-bar"      type="uint"   value="0"/>
  <property name="scrolling-lines"    type="uint"   value="5000"/>
</channel>
EOF

    # ── Keyboard shortcuts ─────────────────────────────────
    cat > "${PROOT_HOME}/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-keyboard-shortcuts" version="1.0">
  <property name="commands" type="empty">
    <property name="custom" type="empty">
      <property name="&lt;Super&gt;e"     type="string" value="thunar"/>
      <property name="&lt;Super&gt;t"     type="string" value="xfce4-terminal"/>
      <property name="&lt;Super&gt;r"     type="string" value="xfce4-appfinder --collapsed"/>
      <property name="&lt;Alt&gt;F2"      type="string" value="xfce4-appfinder --collapsed"/>
      <property name="Print"              type="string" value="xfce4-screenshooter"/>
    </property>
  </property>
  <property name="xfwm4" type="empty">
    <property name="custom" type="empty">
      <property name="&lt;Alt&gt;F4"      type="string" value="close_window_key"/>
      <property name="&lt;Alt&gt;F10"     type="string" value="maximize_window_key"/>
      <property name="&lt;Super&gt;d"     type="string" value="show_desktop_key"/>
      <property name="&lt;Super&gt;Left"  type="string" value="tile_left_key"/>
      <property name="&lt;Super&gt;Right" type="string" value="tile_right_key"/>
      <property name="&lt;Super&gt;Up"    type="string" value="maximize_window_key"/>
    </property>
  </property>
</channel>
EOF

    # ── Desktop icons ──────────────────────────────────────
    cat > "${PROOT_HOME}/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-desktop" version="1.0">
  <property name="desktop-icons" type="empty">
    <property name="file-icons" type="empty">
      <property name="show-filesystem" type="bool" value="false"/>
      <property name="show-home"       type="bool" value="true"/>
      <property name="show-trash"      type="bool" value="true"/>
      <property name="show-removable"  type="bool" value="true"/>
    </property>
    <property name="icon-size"    type="uint"   value="48"/>
    <property name="tooltip-size" type="double" value="64"/>
  </property>
</channel>
EOF

    # ── Desktop shortcuts (.desktop files) ─────────────────
    cat > "${PROOT_HOME}/Desktop/Terminal.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Terminal
Exec=xfce4-terminal
Icon=utilities-terminal
Categories=System;TerminalEmulator;
EOF

    cat > "${PROOT_HOME}/Desktop/Files.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=File Manager
Exec=thunar
Icon=folder
Categories=System;FileManager;
EOF

    cat > "${PROOT_HOME}/Desktop/Firefox.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Firefox
Exec=firefox %u
Icon=firefox
Categories=Network;WebBrowser;
EOF

    # ── Wallpaper gradient (generate dari Termux ImageMagick) ─
    local wp_dst="${PROOT_HOME}/Pictures/wallpaper.jpg"
    if command -v convert >/dev/null 2>&1; then
        (convert -size 1920x1080 \
            gradient:"#1a1b2e"-"#16213e" \
            "${wp_dst}" 2>/dev/null) &
        spinner $! "Generate gradient wallpaper (1920x1080)"
    fi

    # Fix ownership — jalankan dari dalam Ubuntu agar uid mapping benar
    ubuntu_run_quiet \
        "chown -R ${ADMIN_USER}:${ADMIN_USER} /home/${ADMIN_USER}" \
    || true

    echo -e "  ${G}[✓] XFCE4 theme: Adwaita-dark + Dracula terminal${N}\n"
}

# ══════════════════════════════════════════════════════════
#  STEP 7: GPU environment script
#
#  File ini disimpan di home admin Ubuntu:
#    /home/admin/.gpu-env.sh
#  Di-source oleh .bashrc, dijalankan DI DALAM Ubuntu
#  sebelum startxfce4.
# ══════════════════════════════════════════════════════════
step7_gpu_env() {
    progress
    echo -e "${P}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Setup GPU environment script...${N}\n"

    cat > "${PROOT_HOME}/.gpu-env.sh" << GPUEOF
#!/bin/bash
# ~/.gpu-env.sh — GPU environment untuk XFCE4 di Ubuntu proot
# Di-source oleh ~/.bashrc dan oleh start-xfce.sh (via su - admin)

# ── Mesa / Zink ────────────────────────────────────────────
# Zink: OpenGL diimplementasikan di atas Vulkan
# Driver mesa (libGL, libEGL) dari Termux di-bind ke dalam Ubuntu
export MESA_NO_ERROR=1
export MESA_GL_VERSION_OVERRIDE=4.6
export MESA_GLES_VERSION_OVERRIDE=3.2
export MESA_LOADER_DRIVER_OVERRIDE=zink
export GALLIUM_DRIVER=zink
export MESA_VK_WSI_PRESENT_MODE=immediate
export ZINK_DESCRIPTORS=lazy
export TU_DEBUG=noconform

# ── Vulkan ICD ─────────────────────────────────────────────
# ICD file di-bind dari Termux ke /usr/share/vulkan/icd.d.termux
# oleh start-xfce.sh. Script ini hanya set VK_ICD_FILENAMES.
_VK_TERMUX_DIR="/usr/share/vulkan/icd.d.termux"
if [ -f "\${_VK_TERMUX_DIR}/freedreno_icd.aarch64.json" ]; then
    # Turnip: GPU Adreno (Qualcomm)
    export VK_ICD_FILENAMES="\${_VK_TERMUX_DIR}/freedreno_icd.aarch64.json"
fi

# ── X Display ──────────────────────────────────────────────
# Termux-X11 display server berjalan di Termux sebagai :0
# Ubuntu konek ke display ini via socket X11 yang di-bind
export DISPLAY=:0

# ── Audio ──────────────────────────────────────────────────
# PulseAudio berjalan di Termux, Ubuntu konek via TCP
export PULSE_SERVER=127.0.0.1

# ── XDG ───────────────────────────────────────────────────
export XDG_RUNTIME_DIR=/tmp
export XDG_DATA_DIRS=/usr/share:/usr/local/share
export XDG_CONFIG_DIRS=/etc/xdg
GPUEOF
    chmod +x "${PROOT_HOME}/.gpu-env.sh"

    # Fix ownership
    ubuntu_run_quiet \
        "chown ${ADMIN_USER}:${ADMIN_USER} /home/${ADMIN_USER}/.gpu-env.sh" \
    || true

    echo -e "  ${G}[✓] ~/.gpu-env.sh — mode: ${GPU_MODE}${N}\n"
}

# ══════════════════════════════════════════════════════════
#  STEP 8: Buat launcher scripts di ~/  (Termux home)
#
#  PENTING — mana yang berjalan di mana:
#
#  start-xfce.sh  → dijalankan user di TERMUX
#    ├─ termux-x11 :0 -ac          [Termux, X server]
#    ├─ pulseaudio --start          [Termux, audio bridge]
#    └─ proot-distro login ubuntu  [Termux, masuk Ubuntu]
#         └─ bash -c "su - admin -c 'dbus-run-session -- startxfce4'"
#                                   [Ubuntu, XFCE session]
#
#  shell-ubuntu.sh → dijalankan di TERMUX, masuk Ubuntu sebagai admin
#
#  stop-xfce.sh → dijalankan di TERMUX, kill semua proses
# ══════════════════════════════════════════════════════════
step8_launchers() {
    progress
    echo -e "${P}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Membuat launcher scripts...${N}\n"

    # ──────────────────────────────────────────────────────
    # start-xfce.sh
    # Dibuat dengan dua bagian heredoc terpisah:
    # 1. Bagian variabel (di-expand saat generate)
    # 2. Bagian logika (single-quote heredoc, $ tidak di-expand)
    # ──────────────────────────────────────────────────────
    {
        # Shebang + komentar
        cat << 'HDR'
#!/data/data/com.termux/files/usr/bin/bash
# ════════════════════════════════════════════════════════════
#  start-xfce.sh  —  Jalankan XFCE4 Ubuntu via Termux-X11
#
#  Yang BERJALAN DI TERMUX (Android):
#    • termux-x11   : X display server
#    • pulseaudio   : audio bridge
#    • proot-distro : engine masuk Ubuntu
#
#  Yang BERJALAN DI DALAM UBUNTU (proot):
#    • dbus-run-session → startxfce4
# ════════════════════════════════════════════════════════════
HDR
        # Variabel di-expand saat generate script ini
        cat << VARS
PROOT_DISTRO="${PROOT_DISTRO}"
ADMIN_USER="${ADMIN_USER}"
TERMUX_TMP="\${TMPDIR:-/data/data/com.termux/files/usr/tmp}"
TERMUX_VK_ICD="/data/data/com.termux/files/usr/share/vulkan/icd.d"
TERMUX_LIB="/data/data/com.termux/files/usr/lib"
VARS
        # Logika — TIDAK di-expand (single-quote heredoc)
        cat << 'BODY'

echo ""
echo "  ╔══════════════════════════════════════════════════╗"
echo "  ║  start-xfce.sh  —  Ubuntu XFCE4 Launcher        ║"
echo "  ╚══════════════════════════════════════════════════╝"
echo ""

# ── 1. Bersihkan sesi lama ────────────────────────────────
# Hentikan proses yang mungkin masih ada dari sesi sebelumnya
pkill -9 -f "com.termux.x11" 2>/dev/null || true
pkill -9 -f "termux-x11"     2>/dev/null || true
pkill -9 -f "Xvnc"           2>/dev/null || true
pkill -9 -f "xfce4-session"  2>/dev/null || true
pkill -9 -f "dbus-daemon"    2>/dev/null || true
sleep 0.5
echo "  [✓] Sesi lama dibersihkan"

# ── 2. PulseAudio di Termux ───────────────────────────────
# PulseAudio server BERJALAN DI TERMUX (bukan di Ubuntu).
# Ubuntu hanya pakai pulseaudio-utils (pactl, dll) untuk konek
# ke server ini via PULSE_SERVER=127.0.0.1
echo "  [*] Starting PulseAudio (Termux)..."
unset PULSE_SERVER
pulseaudio --kill 2>/dev/null; sleep 0.3
pulseaudio \
    --start \
    --exit-idle-time=-1 \
    --daemonize=true \
    --log-target="file:${TERMUX_TMP}/pulseaudio.log" \
    2>/dev/null
sleep 1
# Buka TCP port agar Ubuntu bisa konek
pactl load-module module-native-protocol-tcp \
    auth-ip-acl=127.0.0.1 auth-anonymous=1 2>/dev/null || true
echo "  [✓] PulseAudio ready (TCP 127.0.0.1)"

# ── 3. Termux-X11 display :0 ─────────────────────────────
# termux-x11 BERJALAN DI TERMUX sebagai X display server.
# Ubuntu konek ke display :0 via socket /tmp/.X11-unix/X0
# yang di-bind masuk ke Ubuntu.
echo "  [*] Starting Termux-X11 (:0)..."
termux-x11 :0 -ac &
X11_PID=$!
sleep 2

# Verifikasi socket X11 ada di Termux tmp
X11_SOCK="${TERMUX_TMP}/.X11-unix"
if [ ! -S "${X11_SOCK}/X0" ]; then
    echo ""
    echo "  [!] ERROR: Socket X11 tidak ada: ${X11_SOCK}/X0"
    echo ""
    echo "  Pastikan:"
    echo "    1. App Termux:X11 sudah diinstall & dibuka di Android"
    echo "    2. Izin 'Display over other apps' sudah diberikan"
    echo "    3. Coba buka app Termux:X11 manual lalu jalankan lagi"
    echo ""
    kill $X11_PID 2>/dev/null
    exit 1
fi
echo "  [✓] Termux-X11 ready — ${X11_SOCK}/X0"

# ── 4. Susun bind mounts ──────────────────────────────────
# Bind mount: path di Termux → path di dalam Ubuntu
# Format: --bind <path-android>:<path-ubuntu>
BINDS=""

# X11 socket — WAJIB
# Dari dokumentasi Termux-X11:
# "If you plan to use the program with proot, keep in mind that you
#  need to launch proot/proot-distro with the --shared-tmp option.
#  If passing this option is not possible, set the TMPDIR environment
#  variable to point to the directory that corresponds to /tmp in
#  the target container."
# Kita bind manual karena lebih eksplisit & tidak bergantung TMPDIR
BINDS="${BINDS} --bind ${X11_SOCK}:/tmp/.X11-unix"

# GPU devices — bind hanya jika path ada di Android
[ -d "/dev/dri" ]      && BINDS="${BINDS} --bind /dev/dri:/dev/dri"
[ -e "/dev/kgsl-3d0" ] && BINDS="${BINDS} --bind /dev/kgsl-3d0:/dev/kgsl-3d0"
[ -e "/dev/mali0" ]    && BINDS="${BINDS} --bind /dev/mali0:/dev/mali0"

# Vulkan ICD Termux → Ubuntu
# ICD = Installable Client Driver (memberitahu Vulkan loader
# driver mana yang harus dipakai)
[ -d "${TERMUX_VK_ICD}" ] && \
    BINDS="${BINDS} --bind ${TERMUX_VK_ICD}:/usr/share/vulkan/icd.d.termux"

# libvulkan.so Termux → Ubuntu
# Gunakan libvulkan versi Termux yang lebih baru dari Ubuntu default
[ -f "${TERMUX_LIB}/libvulkan.so" ] && \
    BINDS="${BINDS} --bind ${TERMUX_LIB}/libvulkan.so:/usr/lib/aarch64-linux-gnu/libvulkan_termux.so"

echo "  [*] Bind mounts aktif:"
echo "${BINDS}" | tr ' ' '\n' | grep -- '--bind' | \
    sed 's/--bind /    /' | head -15
echo ""

# ── 5. Masuk Ubuntu dan jalankan XFCE4 ───────────────────
# Flow eksekusi:
#   Termux → proot-distro login ubuntu (root)
#     → bash -c "su - admin -c '...'"
#       → source ~/.gpu-env.sh
#         → dbus-run-session -- startxfce4
#
# Mengapa su - admin (bukan --user admin di proot-distro)?
#   --user flag di proot-distro tidak konsisten di semua versi.
#   su - admin memastikan login shell benar, HOME=/home/admin,
#   dan .bashrc / .gpu-env.sh ter-source.
#
# Mengapa dbus-run-session?
#   proot tidak punya systemd/logind. dbus-run-session adalah
#   cara satu-satunya start dbus session yang benar di proot.
#   Tanpa ini: XFCE plugin crash, notification daemon tidak jalan,
#   app launcher tidak bisa start aplikasi.

echo "  [*] Masuk Ubuntu proot, login sebagai: ${ADMIN_USER}"
echo "  [*] Buka app Termux:X11 di Android untuk melihat desktop!"
echo ""

proot-distro login "${PROOT_DISTRO}" \
    ${BINDS} \
    -- \
    bash -c '
        # Di dalam Ubuntu sebagai root:

        # Pastikan /tmp writable & X11 socket ada
        chmod 1777 /tmp 2>/dev/null || true
        mkdir -p /tmp/.X11-unix
        chmod 1777 /tmp/.X11-unix 2>/dev/null || true

        # Verifikasi X11 socket ada di dalam Ubuntu
        if [ ! -S /tmp/.X11-unix/X0 ]; then
            echo "[!] Error: /tmp/.X11-unix/X0 tidak ada di dalam Ubuntu"
            echo "    Bind X11 socket gagal. Cek start-xfce.sh"
            exit 1
        fi
        echo "  [✓] X11 socket OK di dalam Ubuntu: /tmp/.X11-unix/X0"

        # su - admin: login sebagai admin dengan environment lengkap
        # -c: jalankan perintah, lalu exit
        su - '"${ADMIN_USER}"' -c "
            # Source GPU environment
            [ -f ~/.gpu-env.sh ] && source ~/.gpu-env.sh

            echo \"  GPU  : GALLIUM=\${GALLIUM_DRIVER:-tidak diset}\"
            echo \"  GL   : \${MESA_GL_VERSION_OVERRIDE:-default}\"
            echo \"  VK   : \${VK_ICD_FILENAMES:-software fallback}\"
            echo \"  DISP : \${DISPLAY}\"
            echo \"  AUDIO: \${PULSE_SERVER}\"
            echo \"\"

            # Jalankan XFCE4 dengan dbus session
            exec dbus-run-session -- startxfce4
        "
    '

EXIT_CODE=$?
echo ""
if [ ${EXIT_CODE} -eq 0 ]; then
    echo "  [✓] Sesi XFCE4 berakhir normal."
else
    echo "  [!] XFCE4 keluar dengan kode: ${EXIT_CODE}"
    echo "      Log audio : ${TERMUX_TMP}/pulseaudio.log"
    echo ""
    echo "  Troubleshooting:"
    echo "    Layar hitam → edit script, ubah: termux-x11 :0 -legacy-drawing -ac"
    echo "    Warna balik  → edit script, ubah: termux-x11 :0 -force-bgra -ac"
fi
BODY
    } > ~/start-xfce.sh

    chmod +x ~/start-xfce.sh
    echo -e "  ${G}[✓] ~/start-xfce.sh${N}"

    # ──────────────────────────────────────────────────────
    # shell-ubuntu.sh — masuk shell Ubuntu sebagai admin
    # ──────────────────────────────────────────────────────
    {
        cat << 'HDR'
#!/data/data/com.termux/files/usr/bin/bash
# ════════════════════════════════════════════════════════════
#  shell-ubuntu.sh  —  Masuk shell Ubuntu sebagai admin
#  Gunakan untuk: apt install, konfigurasi, troubleshoot
# ════════════════════════════════════════════════════════════
HDR
        cat << VARS
PROOT_DISTRO="${PROOT_DISTRO}"
ADMIN_USER="${ADMIN_USER}"
TERMUX_TMP="\${TMPDIR:-/data/data/com.termux/files/usr/tmp}"
TERMUX_VK_ICD="/data/data/com.termux/files/usr/share/vulkan/icd.d"
VARS
        cat << 'BODY'

echo ""
echo "  ╔══════════════════════════════════════════════════╗"
echo "  ║  Ubuntu 22.04 Shell  —  user: admin             ║"
echo "  ║  sudo apt install <paket>  — bebas install!     ║"
echo "  ╚══════════════════════════════════════════════════╝"
echo ""

# Susun bind mounts (X11 jika tersedia, GPU)
BINDS=""
X11_SOCK="${TERMUX_TMP}/.X11-unix"
[ -d "${X11_SOCK}" ]       && BINDS="${BINDS} --bind ${X11_SOCK}:/tmp/.X11-unix"
[ -d "/dev/dri" ]           && BINDS="${BINDS} --bind /dev/dri:/dev/dri"
[ -e "/dev/kgsl-3d0" ]      && BINDS="${BINDS} --bind /dev/kgsl-3d0:/dev/kgsl-3d0"
[ -d "${TERMUX_VK_ICD}" ]   && \
    BINDS="${BINDS} --bind ${TERMUX_VK_ICD}:/usr/share/vulkan/icd.d.termux"

# Masuk Ubuntu sebagai root, lalu su ke admin
# (su - admin membaca .bashrc termasuk .gpu-env.sh)
proot-distro login "${PROOT_DISTRO}" ${BINDS} -- \
    bash -c "su - ${ADMIN_USER}"
BODY
    } > ~/shell-ubuntu.sh

    chmod +x ~/shell-ubuntu.sh
    echo -e "  ${G}[✓] ~/shell-ubuntu.sh${N}"

    # ──────────────────────────────────────────────────────
    # stop-xfce.sh
    # ──────────────────────────────────────────────────────
    cat > ~/stop-xfce.sh << 'STOP'
#!/data/data/com.termux/files/usr/bin/bash
# ════════════════════════════════════════════════════════════
#  stop-xfce.sh  —  Hentikan semua sesi
#  Jalankan dari TERMUX, bukan dari dalam Ubuntu
# ════════════════════════════════════════════════════════════

echo "  [*] Menghentikan semua sesi..."

# Proses Termux
pkill -9 -f "com.termux.x11" 2>/dev/null || true
pkill -9 -f "termux-x11"     2>/dev/null || true
pkill -9 -f "Xvnc"           2>/dev/null || true
pkill -9 -f "pulseaudio"     2>/dev/null || true

# Proses Ubuntu yang masih berjalan via proot
pkill -9 -f "xfce4-session"  2>/dev/null || true
pkill -9 -f "startxfce4"     2>/dev/null || true
pkill -9 -f "xfwm4"          2>/dev/null || true
pkill -9 -f "xfce4-panel"    2>/dev/null || true
pkill -9 -f "dbus-daemon"    2>/dev/null || true

# Hapus lock file X
rm -f /tmp/.X0-lock 2>/dev/null || true

echo "  [✓] Selesai."
STOP

    chmod +x ~/stop-xfce.sh
    echo -e "  ${G}[✓] ~/stop-xfce.sh${N}\n"
}

# ══════════════════════════════════════════════════════════
#  STEP 9: VNC opsional
#  TigerVNC berjalan di TERMUX (bukan di Ubuntu).
#  VNC punya display sendiri (:1), xstartup-nya masuk
#  ke Ubuntu via proot dan jalankan XFCE.
# ══════════════════════════════════════════════════════════
step9_vnc_optional() {
    progress
    echo -e "${P}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] (Opsional) VNC Remote Desktop...${N}\n"

    echo -e "  VNC: akses XFCE desktop dari PC/tablet via WiFi."
    read -rp "  Install TigerVNC? [y/N]: " _ans
    _ans="${_ans:-N}"

    if [[ "${_ans}" =~ ^[Yy]$ ]]; then
        VNC_ENABLED=true
        read -rp "  Password VNC [default: admin123]: " VNC_PASS
        VNC_PASS="${VNC_PASS:-admin123}"
        read -rp "  Resolusi [default: 1280x720]: " VNC_GEO
        VNC_GEO="${VNC_GEO:-1280x720}"

        # TigerVNC diinstall di Termux (bukan Ubuntu)
        tpkg "tigervnc"

        mkdir -p ~/.vnc
        echo "${VNC_PASS}" | vncpasswd -f > ~/.vnc/passwd
        chmod 600 ~/.vnc/passwd

        # xstartup: dijalankan oleh vncserver (Termux) saat display :1 start
        # Masuk Ubuntu via proot, jalankan XFCE sebagai admin
        {
            cat << 'HDR'
#!/data/data/com.termux/files/usr/bin/bash
# VNC xstartup — display :1
# Dijalankan oleh TigerVNC (Termux) → masuk Ubuntu → XFCE
HDR
            cat << VARS
PROOT_DISTRO="${PROOT_DISTRO}"
ADMIN_USER="${ADMIN_USER}"
TERMUX_VK_ICD="/data/data/com.termux/files/usr/share/vulkan/icd.d"
VARS
            cat << 'BODY'

BINDS="--bind /tmp/.X11-unix:/tmp/.X11-unix"
[ -d "/dev/dri" ]      && BINDS="${BINDS} --bind /dev/dri:/dev/dri"
[ -e "/dev/kgsl-3d0" ] && BINDS="${BINDS} --bind /dev/kgsl-3d0:/dev/kgsl-3d0"
[ -d "${TERMUX_VK_ICD}" ] && \
    BINDS="${BINDS} --bind ${TERMUX_VK_ICD}:/usr/share/vulkan/icd.d.termux"

proot-distro login "${PROOT_DISTRO}" ${BINDS} -- bash -c "
    chmod 1777 /tmp 2>/dev/null || true
    su - ${ADMIN_USER} -c '
        [ -f ~/.gpu-env.sh ] && source ~/.gpu-env.sh
        export DISPLAY=:1
        exec dbus-run-session -- startxfce4
    '
"
BODY
        } > ~/.vnc/xstartup
        chmod +x ~/.vnc/xstartup

        # start-vnc.sh
        {
            cat << 'HDR'
#!/data/data/com.termux/files/usr/bin/bash
# ════════════════════════════════════════════════════════════
#  start-vnc.sh  —  TigerVNC + Ubuntu XFCE
#  Jalankan dari TERMUX, buka VNC Viewer di perangkat lain
# ════════════════════════════════════════════════════════════
HDR
            cat << VARS
VNC_GEO="${VNC_GEO}"
VNC_PASS="${VNC_PASS}"
VARS
            cat << 'BODY'

echo "  [*] Membersihkan sesi lama..."
pkill -9 -f "com.termux.x11" 2>/dev/null; true
vncserver -kill :1 2>/dev/null; true
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1 2>/dev/null; true

echo "  [*] Starting PulseAudio (Termux)..."
unset PULSE_SERVER
pulseaudio --kill 2>/dev/null; sleep 0.3
pulseaudio --start --exit-idle-time=-1 --daemonize=true
sleep 1
pactl load-module module-native-protocol-tcp \
    auth-ip-acl=127.0.0.1 auth-anonymous=1 2>/dev/null || true

echo "  [*] Starting VNC server (${VNC_GEO})..."
vncserver -localhost no -geometry "${VNC_GEO}" -depth 24 :1

IP=$(ip -4 addr show wlan0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)
echo ""
echo "  ╔════════════════════════════════════════╗"
echo "  ║  VNC Ready!                            ║"
echo "  ║  Local  : 127.0.0.1:5901               ║"
[ -n "${IP}" ] && echo "  ║  WiFi   : ${IP}:5901        ║"
echo "  ║  Pass   : ${VNC_PASS}                  ║"
echo "  ╚════════════════════════════════════════╝"
BODY
        } > ~/start-vnc.sh
        chmod +x ~/start-vnc.sh

        echo -e "  ${G}[✓] ~/start-vnc.sh (${VNC_GEO}, pass: ${VNC_PASS})${N}\n"
    else
        echo -e "  Dilewati. Install nanti: ${C}pkg install tigervnc${N}\n"
    fi
}

# ══════════════════════════════════════════════════════════
#  RINGKASAN AKHIR
# ══════════════════════════════════════════════════════════
show_done() {
    echo ""
    echo -e "${G}"
    cat << 'EOF'
  ╔════════════════════════════════════════════════════╗
  ║      ✓  INSTALASI SELESAI!                        ║
  ╚════════════════════════════════════════════════════╝
EOF
    echo -e "${N}"

    echo -e "  ${W}Ringkasan:${N}"
    echo    "  ──────────────────────────────────────────────────"
    echo -e "  Distro : ${C}${PROOT_LABEL}${N}"
    echo -e "  User   : ${C}${ADMIN_USER}${N}  (pass: ${C}${ADMIN_PASS}${N}  sudo NOPASSWD)"
    echo -e "  GPU    : ${C}${GPU_MODE}${N}"
    echo    ""

    echo -e "  ${Y}══ CARA PAKAI ════════════════════════════════════${N}"
    echo    ""
    echo -e "  ${G}1. Jalankan XFCE4:${N}"
    echo -e "     ${W}bash ~/start-xfce.sh${N}"
    echo -e "     ${D}→ Buka app Termux:X11 di Android${N}"
    echo    ""
    echo -e "  ${G}2. Masuk shell Ubuntu (install app):${N}"
    echo -e "     ${W}bash ~/shell-ubuntu.sh${N}"
    echo -e "     ${D}→ sudo apt install <paket-apapun>${N}"
    echo    ""
    if [ "${VNC_ENABLED}" = "true" ]; then
    echo -e "  ${G}3. VNC remote desktop:${N}"
    echo -e "     ${W}bash ~/start-vnc.sh${N}"
    echo -e "     ${D}→ VNC Viewer → 127.0.0.1:5901 (pass: ${VNC_PASS})${N}"
    echo    ""
    fi
    echo -e "  ${G}4. Stop semua:${N}"
    echo -e "     ${W}bash ~/stop-xfce.sh${N}"
    echo    ""

    echo -e "  ${Y}══ TROUBLESHOOTING ═══════════════════════════════${N}"
    echo    ""
    echo -e "  ${W}• Layar hitam:${N}"
    echo -e "    Di start-xfce.sh, ubah baris termux-x11 menjadi:"
    echo -e "    ${C}termux-x11 :0 -legacy-drawing -ac${N}"
    echo    ""
    echo -e "  ${W}• Warna terbalik:${N}"
    echo -e "    ${C}termux-x11 :0 -force-bgra -ac${N}"
    echo    ""
    echo -e "  ${W}• X11 socket error:${N}"
    echo -e "    Buka app Termux:X11 SEBELUM menjalankan start-xfce.sh"
    echo    ""
    echo -e "  ${W}• Font/UI terlalu besar:${N}"
    echo -e "    XFCE: Settings → Appearance → Fonts → DPI = 96"
    echo    ""
    echo -e "  ${W}• Audio tidak keluar:${N}"
    echo -e "    ${C}pulseaudio --start --exit-idle-time=-1${N}"
    echo -e "    ${C}pactl load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1${N}"
    echo    ""
    echo -e "  ${W}• dbus error / XFCE crash:${N}"
    echo -e "    Pastikan dbus-x11 terinstall di Ubuntu:"
    echo -e "    ${C}bash ~/shell-ubuntu.sh${N}"
    echo -e "    ${C}sudo apt install dbus dbus-x11${N}"
    echo    ""
    echo -e "  ${Y}══════════════════════════════════════════════════${N}"
    echo ""
}

# ══════════════════════════════════════════════════════════
#  MAIN
# ══════════════════════════════════════════════════════════
main() {
    # Pastikan dijalankan di Termux
    if [ ! -d "/data/data/com.termux" ] || \
       [ ! -x "${TERMUX_PREFIX}/bin/bash" ]; then
        echo "Error: Jalankan script ini di dalam Termux!"
        exit 1
    fi

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
    step9_vnc_optional

    show_done
}

main