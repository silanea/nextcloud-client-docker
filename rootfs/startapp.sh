#!/bin/bash
# Entry point for the GUI app (executed by baseimage-gui after X11 is up)
export XDG_RUNTIME_DIR=/tmp/runtime-root
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

set -Eeuo pipefail

# Run update script at startup
if [ -x /usr/local/bin/update-nextcloud.sh ]; then
    /usr/local/bin/update-nextcloud.sh || true
fi

APP_NAME="Nextcloud Client"

echo "[startapp] Launching ${APP_NAME}..."

echo "[startapp] Starting dbus-daemon (session)..."
dbus-daemon --session --fork

sleep 2

# Run Nextcloud client inside loop for crash recovery
while true; do
    echo "[startapp] Starting nextcloud..."
    nextcloud &
    APP_PID=$!

    wait $APP_PID
    echo "[startapp] Nextcloud exited. Restarting in 10 seconds..."
    sleep 10
done
