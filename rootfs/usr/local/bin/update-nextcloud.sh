#!/bin/bash
set -e

echo "[update-nextcloud] Starting update check..."

apt-get update -qq

# Check if nextcloud-desktop has an available upgrade
if apt-get --just-print dist-upgrade | grep -q "nextcloud-desktop"; then
    echo "[update-nextcloud] Updating Nextcloud client..."
    apt-get -y dist-upgrade

    echo "[update-nextcloud] Restarting client..."
    sv restart nextcloud
else
    echo "[update-nextcloud] No update available."
fi
