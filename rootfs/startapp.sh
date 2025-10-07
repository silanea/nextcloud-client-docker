#!/bin/bash
# Entry point for the GUI app (executed by baseimage-gui after X11 is up)

CONFIG_DIR="/config"
APP_HOME="/home/app"

APP_NAME="Nextcloud Client"
# Ensure display variable is set by jlesage baseimage
export DISPLAY=${DISPLAY:-:0}

echo "[startapp] Launching ${APP_NAME}..."

set -Eeuo pipefail

# Run update script at startup
if [ -x /usr/local/bin/update-nextcloud.sh ]; then
    /usr/local/bin/update-nextcloud.sh || true
fi


echo "[startapp] Preparing environment..."

mkdir -p "$HOME/.config/Nextcloud" "$HOME/.local/share"
chmod 700 "$HOME/.config" "$HOME/.local" "$HOME/.local/share"

# --- Start D-Bus session ---

# Create writable runtime dirs for dbus and XDG stuff
export XDG_RUNTIME_DIR="/tmp/runtime-app"
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

# If dbus is needed, run session bus only
if ! pgrep -x dbus-daemon >/dev/null 2>&1; then
    echo "[startapp] Starting user dbus-daemon..."
    dbus-daemon --session --address=unix:path=$XDG_RUNTIME_DIR/bus &
fi

# Wait for X server readiness
echo "[startapp] Waiting for X server..."
for i in $(seq 1 50); do
    if xdpyinfo -display "$DISPLAY" >/dev/null 2>&1; then
        echo "[startapp] X server is ready."
        break
    fi
    echo "[startapp] X server not ready yet ($i)..."
    sleep 1
done

# Give up if X server never came up
if ! xdpyinfo -display "$DISPLAY" >/dev/null 2>&1; then
    echo "[startapp] ERROR: X server not ready after timeout."
    exit 1
fi

export HOME="${APP_HOME}"

# Run Nextcloud client inside loop for crash recovery
while true; do
    echo "[startapp] Starting nextcloud..."
    nextcloud &
    APP_PID=$!

    wait $APP_PID
    echo "[startapp] Nextcloud exited. Restarting in 10 seconds..."
    sleep 10
done
