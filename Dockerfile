# Base image with GUI support
FROM jlesage/baseimage-gui:debian-12-v4

ENV QTWEBENGINE_DISABLE_SANDBOX=1 \
    QTWEBENGINE_CHROMIUM_FLAGS="--no-sandbox --disable-gpu --disable-software-rasterizer" \
    LIBGL_ALWAYS_SOFTWARE=1 \
    QT_QUICK_BACKEND=software \
    QT_XCB_GL_INTEGRATION=none \
    QT_AUTO_SCREEN_SCALE_FACTOR=0 \
    DISPLAY=:1

# Install packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        nextcloud-desktop \
        cron \
        dbus dbus-x11 \
        procps \
        mesa-utils \
        libgl1 \
        libegl1 \
        libglx-mesa0 \
        libgl1-mesa-dri \
        libxcb-glx0 \       
        && apt-get clean && rm -rf /var/lib/apt/lists/*

# Persist Nextcloud configuration
RUN mkdir -p /config/.config /config/.local/share && \
    rm -rf /root/.config /root/.local && \
    ln -s /config/.config /root/.config && \
    ln -s /config/.local /root/.local

# Add rootfs (cron + startup script)
COPY rootfs/ /

# Make scripts executable
RUN chmod +x /usr/local/bin/update-nextcloud.sh /startapp.sh

# Disable compositor to prevent GUI crashes
RUN rm -f /etc/services.d/xcompmgr/run || true

# Expose GUI ports
EXPOSE 5800 5900
