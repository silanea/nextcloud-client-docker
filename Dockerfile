########################################
# Stage 1: Temporary stage to detect Nextcloud version
########################################
FROM debian:12-slim AS nextcloud-version

# Install required tools
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends wget gnupg2 ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Add Nextcloud repository and write version to /version.txt
RUN wget -qO - https://download.opensuse.org/repositories/home:nextcloud/Debian_12/Release.key \
      | gpg --dearmor > /usr/share/keyrings/nextcloud.gpg && \
    echo 'deb [signed-by=/usr/share/keyrings/nextcloud.gpg] https://download.opensuse.org/repositories/home:/nextcloud/Debian_12/ /' \
      > /etc/apt/sources.list.d/nextcloud.list && \
    apt-get update -qq && \
    apt-get install -y --no-install-recommends nextcloud-desktop && \
    apt-cache policy nextcloud-desktop | grep Candidate | awk '{print $2}' > /version.txt && \
    apt-get purge -y nextcloud-desktop && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

########################################
# Stage 2: Final GUI container
########################################
FROM jlesage/baseimage-gui:debian-12

LABEL maintainer="you@example.com" \
      app="Nextcloud Desktop Client"

# Install Nextcloud Desktop and dependencies
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
        wget gnupg2 ca-certificates \
        adwaita-icon-theme \
        nextcloud-desktop && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Add startup script
COPY startapp.sh /etc/my_init.d/10_nextcloud.sh
RUN chmod +x /etc/my_init.d/10_nextcloud.sh

# Expose ports for noVNC/VNC
EXPOSE 5800 5900
