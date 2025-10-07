#!/bin/bash
# Entry point for the GUI app (executed by baseimage-gui after X11 is up)

CONFIG_DIR="/config"
APP_HOME="/home/app"

APP_NAME="Nextcloud Client"
# Ensure display variable is set by jlesage baseimage
# export DISPLAY=${DISPLAY:-:0}

echo "[startapp] Launching ${APP_NAME}..."

set -Eeuo pipefail

# Run update script at startup
if [ -x /usr/local/bin/update-nextcloud.sh ]; then
    /usr/local/bin/update-nextcloud.sh || true
fi


echo "[startapp] Preparing environment..."

mkdir -p "$CONFIG_DIR/.config/Nextcloud" "$CONFIG_DIR/.local/share"
chown -R $(id -u app):$(id -g app) /config

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

# --- Detect X display -------------------------------------------------
if [ -z "${DISPLAY:-}" ]; then
    if [ -S /tmp/.X11-unix/X1 ]; then
        export DISPLAY=:1
    elif [ -S /tmp/.X11-unix/X0 ]; then
        export DISPLAY=:0
    else
        echo "[startapp] WARNING: No X socket found, assuming :0"
        export DISPLAY=:0
    fi
fi
echo "[startapp] Using DISPLAY=$DISPLAY"

# --- Wait for X server to become available ----------------------------
echo "[startapp] Waiting for X server on $DISPLAY..."
for i in $(seq 1 100); do
    if xdpyinfo -display "$DISPLAY" >/dev/null 2>&1; then
        echo "[startapp] X server is ready (after $i checks)."
        break
    fi
    sleep 1
done

if ! xdpyinfo -display "$DISPLAY" >/dev/null 2>&1; then
    echo "[startapp] ERROR: X server not ready after timeout. Debug info follows:"
    ls -l /tmp/.X11-unix || true
    ps aux | grep -E "Xvnc|Xorg" || true
    exit 1
fi

export HOME="${APP_HOME}"

# ======================
echo "[startapp] Forcing software rendering for QtQuick..."
unset LIBGL_ALWAYS_INDIRECT
unset QT_XCB_GL_INTEGRATION
export LIBGL_ALWAYS_SOFTWARE=1
export LIBGL_ALWAYS_INDIRECT=1
export QT_QPA_PLATFORM=xcb
export QT_OPENGL=software
export QT_QUICK_BACKEND=software
export QT_XCB_GL_INTEGRATION=none
export QT_XCB_FORCE_SOFTWARE_OPENGL=1
export DISABLE_XCOMPMGR=1
export QT_STYLE_OVERRIDE=Windows
export QT_QPA_PLATFORMTHEME=
export MESA_LOADER_DRIVER_OVERRIDE=llvmpipe
# ======================


# Run Nextcloud client inside loop for crash recovery
while true; do
    echo "[startapp] Starting nextcloud..."
    nextcloud &
    APP_PID=$!

    wait $APP_PID
    echo "[startapp] Nextcloud exited. Restarting in 10 seconds..."
    sleep 10
done
