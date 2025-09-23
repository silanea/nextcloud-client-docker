#!/bin/bash
set -e

# Run update immediately on container start
/usr/local/bin/update.sh

# Start cron in background
cron

# Start the AppImage
exec "$APPIMAGE_PATH"
