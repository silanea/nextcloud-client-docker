FROM jlesage/baseimage-gui:debian-12-v4

# Install dependencies for AppImage
RUN apt-get update && \
    apt-get install -y wget curl fuse libfuse2 && \
    rm -rf /var/lib/apt/lists/*

# Copy our scripts
COPY scripts/startapp.sh /startapp.sh
COPY scripts/update-nextcloud.sh /scripts/update-nextcloud.sh

# Make scripts executable
RUN chmod +x /startapp.sh /scripts/update-nextcloud.sh
