#!/usr/bin/env bash
set -e

TARGET="/config/Nextcloud-latest-x86_64.AppImage"
URL="https://download.nextcloud.com/desktop/releases/Linux/latest/Nextcloud-latest-x86_64.AppImage"

echo "[INFO] Downloading latest Nextcloud AppImage..."
wget -q -O "$TARGET" "$URL"
chmod +x "$TARGET"
echo "[INFO] Installed/updated: $TARGET"
