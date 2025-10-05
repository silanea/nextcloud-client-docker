ENV QT_XCB_GL_INTEGRATION=none \
    QT_QUICK_BACKEND=software \
    LIBGL_ALWAYS_SOFTWARE=1 \
    DISPLAY=:1

# Install packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        nextcloud-desktop \
        cron \
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
