# 1. Base GUI image (working Debian tag)
FROM jlesage/baseimage-gui:debian-12-v4

# 2. Install dependencies for AppImage execution and cron
RUN apt-get update && \
    apt-get install -y wget fuse cron && \
    rm -rf /var/lib/apt/lists/*

# 3. Create directory for Nextcloud AppImage and config
ENV NEXTCLOUD_DIR=/opt/nextcloud
ENV NEXTCLOUD_CONFIG=/config
RUN mkdir -p $NEXTCLOUD_DIR

# 4. Script to download latest AppImage
RUN echo '#!/bin/bash\n' \
         'set -e\n' \
         'APPIMAGE_URL=$(curl -s https://api.github.com/repos/nextcloud/desktop/releases/latest | grep browser_download_url | grep AppImage | cut -d '"' -f 4)\n' \
         'wget -O /opt/nextcloud/Nextcloud.AppImage "$APPIMAGE_URL"\n' \
         'chmod +x /opt/nextcloud/Nextcloud.AppImage\n' \
         > /usr/local/bin/update-nextcloud.sh && chmod +x /usr/local/bin/update-nextcloud.sh

# 5. Initial download
RUN /usr/local/bin/update-nextcloud.sh

# 6. Add cron job for daily auto-update
RUN echo "0 3 * * * root /usr/local/bin/update-nextcloud.sh >/dev/null 2>&1" > /etc/cron.d/nextcloud-update
RUN chmod 0644 /etc/cron.d/nextcloud-update && crontab /etc/cron.d/nextcloud-update

# 7. Wrapper script to start Nextcloud automatically
RUN echo '#!/bin/bash\n' \
         'set -e\n' \
         '# Start cron\n' \
         'service cron start\n' \
         '# Launch Nextcloud AppImage\n' \
         'exec /opt/nextcloud/Nextcloud.AppImage --no-sandbox\n' \
         > /usr/local/bin/start-nextcloud.sh && chmod +x /usr/local/bin/start-nextcloud.sh

# 8. Expose GUI via noVNC / container GUI
ENV APPIMAGE_PATH=$NEXTCLOUD_DIR/Nextcloud.AppImage
CMD ["/usr/local/bin/start-nextcloud.sh"]
