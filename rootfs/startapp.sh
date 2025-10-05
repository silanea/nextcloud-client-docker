#!/bin/bash
# Entry point for the GUI app (executed by baseimage-gui after X11 is up)
export DISPLAY=:0
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

# Force software rendering & disable sandbox for WebEngine
export QTWEBENGINE_DISABLE_SANDBOX=1
export QTWEBENGINE_CHROMIUM_FLAGS="--no-sandbox --disable-gpu --disable-software-rasterizer"
export LIBGL_ALWAYS_SOFTWARE=1
export LIBGL_ALWAYS_INDIRECT=1
export QT_QUICK_BACKEND=software
export QT_XCB_GL_INTEGRATION=none
export MESA_LOADER_DRIVER_OVERRIDE=llvmpipe
export QT_QPA_PLATFORM=xcb
export QT_AUTO_SCREEN_SCALE_FACTOR=0

echo "[startapp] Starting dbus-daemon (session)..."
dbus-daemon --session --fork

sleep 2

# Wait for X server to be ready
echo "[startapp] Waiting for X server..."
for i in $(seq 1 10); do
    if xdpyinfo -display :0 >/dev/null 2>&1; then
        echo "[startapp] X server is ready."
        break
    fi
    echo "[startapp] X server not ready yet ($i)..."
    sleep 1
done

# Run Nextcloud client inside loop for crash recovery
while true; do
    echo "[startapp] Starting nextcloud..."
    nextcloud &
    APP_PID=$!

    wait $APP_PID
    echo "[startapp] Nextcloud exited. Restarting in 10 seconds..."
    sleep 10
done
