#!/usr/bin/env bash
set -e

# Install dependencies
apt-get update
apt-get install -y wget curl fuse libfuse2

# Make sure dirs exist
mkdir -p /config /sync

# Always update Nextcloud AppImage
/scripts/update-nextcloud.sh

# Launch Nextcloud client
/config/Nextcloud-latest-x86_64.AppImage --background
