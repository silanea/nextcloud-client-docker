# Base GUI image
FROM jlesage/baseimage-gui:debian-12-v4

# Install dependencies for Nextcloud client
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        git \
        cmake \
        build-essential \
        pkg-config \
        qt6-base-dev \
        qt6-tools-dev \
        qt6-tools-dev-tools \
        qt6-webengine-dev \
        qt6-svg-dev \
        libssl-dev \
        libsqlite3-dev \
        cron \
        curl \
    && rm -rf /var/lib/apt/lists/*

# Clone and build the latest Nextcloud client
RUN git clone --depth 1 https://github.com/nextcloud/desktop.git /tmp/nextcloud && \
    cd /tmp/nextcloud && \
    mkdir build && cd build && \
    cmake .. && \
    make -j$(nproc) && \
    make install

# Set up auto-update script
COPY nextcloud-auto-update.sh /usr/local/bin/nextcloud-auto-update.sh
RUN chmod +x /usr/local/bin/nextcloud-auto-update.sh

# Configure cron to run auto-update every day at 3:00 AM
RUN echo "0 3 * * * /usr/local/bin/nextcloud-auto-update.sh >> /var/log/nextcloud-update.log 2>&1" > /etc/cron.d/nextcloud-cron && \
    chmod 0644 /etc/cron.d/nextcloud-cron && \
    crontab /etc/cron.d/nextcloud-cron

# Expose GUI via web
ENV USER_UID=1000 \
    USER_GID=1000 \
    DISPLAY=:0 \
    ENABLE_VNC=true

# Start baseimage-gui init system
CMD ["/usr/local/bin/start.sh"]
