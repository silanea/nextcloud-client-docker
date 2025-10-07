#!/bin/bash
set -e

echo "[Nextcloud GUI] Starting autologin setup..."
/opt/scripts/autologin.sh

echo "[Nextcloud GUI] Launching client..."
exec nextcloud --confdir /config
