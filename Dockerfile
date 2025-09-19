FROM jlesage/baseimage-gui:debian-12

LABEL maintainer="you@example.com"
LABEL description="Nextcloud Desktop Client (AppImage) with GUI via browser and auto-update"

# Install dependencies for AppImage and GitHub API fetch
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    jq \
    fuse3 \
    && rm -rf /var/lib/apt/lists/*

# Add directories for storage and config
RUN mkdir -p /storage /config /opt/nextcloud

# Add auto-update and launch script
RUN echo '#!/bin/bash\n'\
'# Fetch latest AppImage if missing or outdated\n'\
'LATEST_URL=$(curl -s https://api.github.com/repos/nextcloud/desktop/releases/latest \\\n'\
'  | jq -r \'.assets[] | select(.name | test("x86_64.AppImage$")) | .browser_download_url\')\n'\
'APPIMAGE=/opt/nextcloud/Nextcloud.AppImage\n'\
'if [ ! -f "$APPIMAGE" ] || [ "$(curl -s -I $LATEST_URL | grep -i Location | tail -n1)" != "" ]; then\n'\
'  echo "Downloading latest Nextcloud Desktop AppImage..."\n'\
'  wget -O "$APPIMAGE" "$LATEST_URL"\n'\
'  chmod +x "$APPIMAGE"\n'\
'fi\n'\
'\n'\
'# Launch AppImage\n'\
'exec "$APPIMAGE"' > /usr/local/bin/start-nextcloud.sh

RUN chmod +x /usr/local/bin/start-nextcloud.sh

# Set default command for GUI
CMD ["/usr/local/bin/start-nextcloud.sh"]
