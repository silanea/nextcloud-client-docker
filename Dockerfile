# Base image with GUI support
FROM jlesage/baseimage-gui:debian-12-v4

USER root

# ----------------------------------------------------
# 1️⃣ System setup and dependencies
# ----------------------------------------------------

# Install Nextcloud client and required libraries
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        nextcloud-desktop \
        libxcb-xinerama0 \
        libxcb-xinput0 \
        libxcb-icccm4 \
        libxcb-image0 \
        libxcb-keysyms1 \
        libxcb-render-util0 \
        libxcb-util1 \
        dbus-x11 \
        libgl1-mesa-glx \
        libgl1-mesa-dri \
        mesa-utils \
        libnss3 \
        libxcomposite1 \
        libxcursor1 \
        libxdamage1 \
        libxi6 \
        libxtst6 \
        libxrandr2 \
        libasound2 \
        libxkbcommon-x11-0 \
        libxshmfence1 \
        libnss3-tools \
        libx11-xcb1 \
        libatk-bridge2.0-0 \
        libxss1 \
        libgtk-3-0 \
        libdbus-1-3 \
        lsof \
        psmisc \
        procps \
        file \
        locales && \
    rm -rf /var/lib/apt/lists/*

# Set locale (avoids Qt warnings)
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && locale-gen

# ----------------------------------------------------
# 2️⃣ Configuration directories (persistent)
# ----------------------------------------------------
RUN mkdir -p /config/.config /config/.local/share && \
    chown -R app:app /config

# RUN mkdir -p "/config/.config" "/config/.local/share"
# RUN ln -snf "/config/.config" /root/.config
# RUN ln -snf "/config/.local/share" /root/.local/share    

# Add rootfs (cron + startup script)
COPY rootfs/ /

# Make scripts executable
RUN chmod +x /usr/local/bin/update-nextcloud.sh /startapp.sh

# Disable compositor to prevent GUI crashes
# RUN rm -f /etc/services.d/xcompmgr/run || true

# Expose GUI ports
EXPOSE 5800 5900

USER app
