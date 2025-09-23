#!/bin/bash
set -e

APPIMAGE_PATH=${APPIMAGE_PATH:-/opt/nextcloud/Nextcloud.AppImage}

get_latest_version() {
    TAG=$(curl -s https://api.github.com/repos/nextcloud/desktop/releases/latest | jq -r .tag_name)
    echo "${TAG#v}"
}

get_current_version() {
    if [[ -x "$APPIMAGE_PATH" ]]; then
        CURRENT=$("$APPIMAGE_PATH" --version 2>/dev/null | grep -oP '[0-9]+\.[0-9]+\.[0-9]+')
        if [[ -n "$CURRENT" ]]; then
            echo "$CURRENT"
            return
        fi
    fi
    echo "none"
}

echo "[update] Checking for Nextcloud client updates..."
LATEST_VERSION=$(get_latest_version)
CURRENT_VERSION=$(get_current_version)

if [[ "$CURRENT_VERSION" == "none" ]] || dpkg --compare-versions "$LATEST_VERSION" gt "$CURRENT_VERSION"; then
    echo "[update] Installing Nextcloud $LATEST_VERSION (current: $CURRENT_VERSION)..."
    URL="https://download.nextcloud.com/desktop/releases/Linux/Nextcloud-${LATEST_VERSION}-x86_64.AppImage"
    wget -q -O "$APPIMAGE_PATH" "$URL"
    chmod +x "$APPIMAGE_PATH"
    echo "[update] Update complete."
else
    echo "[update] Already up-to-date (version $CURRENT_VERSION)."
fi
