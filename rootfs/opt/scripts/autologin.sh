#!/bin/bash
set -e

CONFIG_DIR="/config"
SYNC_ROOT="/sync"

# Update system and restart
if [[ "$1" == "--update" ]]; then
    echo "=== Running nightly system update ==="
    apt-get update -qq && apt-get -y -qq upgrade
    echo "Restarting Nextcloud client..."
    pkill nextcloud || true
    nextcloud --confdir "$CONFIG_DIR" &
    disown
    exit 0
fi

# Prepare persistent dirs
mkdir -p "$CONFIG_DIR" "$SYNC_ROOT"

# Only set up accounts on first start or missing configs
if [ ! -f "${CONFIG_DIR}/.accounts-initialized" ]; then
    echo "Initializing accounts from environment variables..."
    /opt/scripts/init-accounts.sh
    touch "${CONFIG_DIR}/.accounts-initialized"
else
    echo "Accounts already configured. Skipping autologin setup."
fi
