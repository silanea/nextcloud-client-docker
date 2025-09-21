#!/usr/bin/env bash
set -e

# Run updater once at container start
/scripts/update-nextcloud.sh

# Start cron in background
service cron start

# Launch Nextcloud client in background mode
exec /config/Nextcloud-latest-x86_64.AppImage --background
