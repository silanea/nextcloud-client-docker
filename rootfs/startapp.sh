#!/bin/bash
# Entry point for the GUI app (executed by baseimage-gui after X11 is up)

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
export QT_QUICK_BACKEND=software
export QT_XCB_GL_INTEGRATION=none
export QT_AUTO_SCREEN_SCALE_FACTOR=0
export DISPLAY=:1

# Initialize D-Bus if not running
if ! pgrep -x dbus-daemon > /dev/null; then
    echo "[startapp] Starting dbus-daemon..."
    dbus-daemon --system &
fi

# Wait a moment for the display server to be ready
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
