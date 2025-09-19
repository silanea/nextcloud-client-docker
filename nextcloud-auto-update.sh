#!/bin/bash
set -e

echo "Checking for Nextcloud client updates..."
cd /tmp
rm -rf nextcloud
git clone --depth 1 https://github.com/nextcloud/desktop.git nextcloud
cd nextcloud/build || mkdir build && cd build
cmake .. 
make -j$(nproc)
make install
echo "Nextcloud client updated successfully."
