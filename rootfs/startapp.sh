#!/bin/bash
# Entry point for the GUI app (executed by baseimage-gui after X11 is up)
export XDG_RUNTIME_DIR=/tmp/runtime-root
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

CONFIG_DIR="/config"
APP_HOME="/home/app"

APP_NAME="Nextcloud Client"

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
DBUS_RUN_DIR="/run/dbus"
mkdir -p "${DBUS_RUN_DIR}"
chmod 777 "${DBUS_RUN_DIR}"
if ! pgrep -u app dbus-daemon >/dev/null 2>&1; then
    echo "[startapp] Starting dbus-daemon..."
    mkdir -p /run/dbus
    dbus-daemon --session --address=unix:path=/run/dbus/session_bus_socket --nofork &
    sleep 1
fi

# --- Wait for X server (Openbox/Xvnc) ---
echo "[startapp] Waiting for X server..."
for i in {1..30}; do
    if xdpyinfo -display :1 >/dev/null 2>&1; then
        echo "[startapp] X server ready."
        break
    fi
    echo "[startapp] X server not ready yet (${i})..."
    sleep 1
done

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
