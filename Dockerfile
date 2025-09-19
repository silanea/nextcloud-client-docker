FROM jlesage/baseimage-gui:debian-12

LABEL maintainer="https://github.com/silanea/" \
      app="Nextcloud Desktop Client"

# Install Nextcloud desktop client
RUN apt-get update && \
    apt-get install -y --no-install-recommends wget gnupg2 ca-certificates && \
    wget -qO - https://download.opensuse.org/repositories/home:nextcloud/Debian_12/Release.key \
      | gpg --dearmor > /usr/share/keyrings/nextcloud.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/nextcloud.gpg] https://download.opensuse.org/repositories/home:/nextcloud/Debian_12/ /" \
      > /etc/apt/sources.list.d/nextcloud.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends nextcloud-desktop adwaita-icon-theme && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Add startup script
COPY startapp.sh /etc/my_init.d/10_nextcloud.sh
RUN chmod +x /etc/my_init.d/10_nextcloud.sh
