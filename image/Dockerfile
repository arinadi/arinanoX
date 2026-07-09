FROM debian:13

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# Base system
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        dialog locales ca-certificates sudo && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Upgrade
RUN apt-get update && \
    apt-get upgrade -y -o Dpkg::Options::='--force-confold' && \
    rm -rf /var/lib/apt/lists/*

# XFCE core
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        dbus-x11 xfce4-session xfwm4 xfce4-panel xfce4-terminal \
        xfce4-settings xfconf && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# XFCE apps
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        thunar xfdesktop4 libgl1 adwaita-icon-theme librsvg2-common && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Audio + network
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        pulseaudio-utils netcat-openbsd && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# CLI tools
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl wget zip unzip jq tree less && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Firefox ESR — langsung dari repo Debian, tanpa Mozilla APT
RUN apt-get update && \
    apt-get install -y --no-install-recommends firefox-esr && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# GUI apps
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        mousepad ristretto tumbler && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Dev tools
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git python3-pip python3-venv python3-dev \
        build-essential cmake pkg-config && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# System tools
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        htop tmux openssh-client && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# XFCE plugins
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        xfce4-whiskermenu-plugin xfce4-power-manager \
        xfce4-pulseaudio-plugin xfce4-genmon-plugin && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Extra
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        x11-xserver-utils && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Node.js 22 LTS
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y nodejs && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# ──── Suppress systemd-specific errors in proot ────
# xfce4-session calls pm-is-supported repeatedly — stub it
RUN printf '#!/bin/sh\nexit 1\n' > /usr/bin/pm-is-supported && chmod +x /usr/bin/pm-is-supported

# xfce4-power-manager needs systemd — disable autostart
RUN printf '[Desktop Entry]\nHidden=true\n' > /etc/xdg/autostart/xfce4-power-manager.desktop

# ──── Create admin user ────
RUN useradd -m -s /bin/bash admin && \
    echo "admin:admin" | chpasswd && \
    echo "admin ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/admin && \
    chmod 0440 /etc/sudoers.d/admin

# ──── Configs ────
COPY configs/bashrc /home/admin/.bashrc
COPY configs/client.conf /home/admin/.pulse/client.conf

RUN mkdir -p /home/admin/.config/gtk-3.0
COPY configs/gtk.css /home/admin/.config/gtk-3.0/gtk.css

RUN mkdir -p /home/admin/.config/xfce4/xfconf/xfce-perchannel-xml
COPY configs/xfwm4.xml /home/admin/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml
COPY configs/thunar.xml /home/admin/.config/xfce4/xfconf/xfce-perchannel-xml/thunar.xml

RUN mkdir -p /home/admin/.droiddesk/tools /home/admin/.config/autostart
COPY configs/tapi-utils.sh /home/admin/.droiddesk/tools/tapi-utils.sh
COPY configs/genmon-battery.sh /home/admin/.droiddesk/tools/genmon-battery.sh
COPY configs/genmon-volume.sh /home/admin/.droiddesk/tools/genmon-volume.sh
COPY configs/clipboard-sync.sh /home/admin/.droiddesk/tools/clipboard-sync.sh
COPY configs/autostart/ /home/admin/.config/autostart/

RUN chown -R admin:admin /home/admin

# Locale
RUN sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && locale-gen
ENV LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

CMD ["/bin/bash"]
