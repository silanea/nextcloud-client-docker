#!/bin/bash
# Entry point for the GUI app (executed by baseimage-gui after X11 is up)

# Run update script at startup
if [ -x /usr/local/bin/update-nextcloud.sh ]; then
    /usr/local/bin/update-nextcloud.sh || true
fi

# Launch full GUI Nextcloud client
exec /usr/bin/nextcloud
