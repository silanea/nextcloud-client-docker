FROM jlesage/baseimage-gui:debian-12

LABEL maintainer="you@example.com"
LABEL description="Nextcloud Desktop Client (AppImage) with GUI via browser"

# Install dependencies for AppImage
RUN apt-get update && apt-get install -y \
    wget \
    fuse3 \
    && rm -rf /var/lib/apt/lists/*

# Download latest Nextcloud Desktop AppImage
RUN wget -O /usr/local/bin/Nextcloud.AppImage \
    https://github.com/nextcloud/desktop/releases/latest/download/Nextcloud-3.17.2-x86_64.AppImage && \
    chmod +x /usr/local/bin/Nextcloud.AppImage

# Create a launch script
RUN echo '#!/bin/bash\n/usr/local/bin/Nextcloud.AppImage' > /usr/local/bin/start-nextcloud.sh && \
    chmod +x /usr/local/bin/start-nextcloud.sh

# Set default command for GUI
CMD ["/usr/local/bin/start-nextcloud.sh"]
