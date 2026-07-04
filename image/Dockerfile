FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# Install dialog FIRST — prevents freeze on keyboard-configuration/tzdata
RUN apt-get update && \
    apt-get install -y --no-install-recommends dialog && \
    rm -rf /var/lib/apt/lists/*

# Upgrade existing packages
RUN apt-get update && \
    apt-get upgrade -y -o Dpkg::Options::='--force-confold' && \
    rm -rf /var/lib/apt/lists/*

# XFCE + DroidDesk packages (minimal, no recommends)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        sudo \
        dbus-x11 \
        xfce4-session \
        xfwm4 \
        xfce4-panel \
        xfce4-terminal \
        xfce4-settings \
        xfconf \
        thunar \
        xfdesktop4 \
        fonts-noto \
        pulseaudio-utils \
        gnome-themes-extra-data \
        libgl1 \
        mesa-utils \
        netcat-openbsd \
        python3-tk \
        curl \
        wget \
        zip \
        unzip \
        jq \
        tree \
        sqlite3 \
        less \
        locales && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create admin user with passwordless sudo
RUN useradd -m -s /bin/bash admin && \
    echo "admin:admin" | chpasswd && \
    echo "admin ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/admin && \
    chmod 0440 /etc/sudoers.d/admin

# Copy configs (image layer defaults)
COPY configs/bashrc /home/admin/.bashrc
COPY configs/client.conf /home/admin/.pulse/client.conf
COPY configs/xfce4-panel.xml /home/admin/.config/xfce4/xfconf/xfce-perchannel-xml/
COPY configs/xfwm4.xml /home/admin/.config/xfce4/xfconf/xfce-perchannel-xml/
COPY configs/xsettings.xml /home/admin/.config/xfce4/xfconf/xfce-perchannel-xml/
COPY configs/xfce4-desktop.xml /home/admin/.config/xfce4/xfconf/xfce-perchannel-xml/

# Dark theme overrides
RUN mkdir -p /home/admin/.config/gtk-3.0 /home/admin/.config/xfce4/terminal
COPY configs/gtk.css /home/admin/.config/gtk-3.0/gtk.css
COPY configs/terminalrc /home/admin/.config/xfce4/terminal/terminalrc

# Fix ownership
RUN chown -R admin:admin /home/admin

# Set locale
RUN sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && locale-gen
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Default shell
CMD ["/bin/bash"]
