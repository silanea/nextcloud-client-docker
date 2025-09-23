#!/bin/bash
set -e

echo "[Updater] Checking for Nextcloud client updates..."

# Update package list and upgrade nextcloud-desktop + dependencies
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -y --only-upgrade nextcloud-desktop

echo "[Updater] Restarting Nextcloud client if running..."
pkill -x nextcloud || true
