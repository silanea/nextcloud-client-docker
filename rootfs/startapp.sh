#!/bin/bash
set -e

CONFIG_DIR="$HOME/.config/Nextcloud"
mkdir -p "$CONFIG_DIR"
SYNC_BASE="/sync"
mkdir -p "$SYNC_BASE"

CFG_FILE="$CONFIG_DIR/nextcloud.cfg"
echo "[Accounts]" > "$CFG_FILE"

# Generate nextcloud.cfg from YAML
python3 - <<'EOF'
import yaml, os, re, urllib.parse

with open("/config/accounts.yml") as f:
    data = yaml.safe_load(f)

for idx, acct in enumerate(data["accounts"]):
    url = acct["url"]
    user = acct["user"]
    password = acct["app_password"]

    # convert URL to safe path
    parsed = urllib.parse.urlparse(url)
    host = parsed.hostname
    port = parsed.port
    safe_port = f"-{port}" if port else ""
    safe_path = os.path.join(host + safe_port, user)

    sync_dir = os.path.join("/sync", safe_path)
    os.makedirs(sync_dir, exist_ok=True)

    print(f"{idx}\\URL={url}")
    print(f"{idx}\\User={user}")
    print(f"{idx}\\AppPassword={password}")
    print(f"{idx}\\SyncDir={sync_dir}")
    print(f"{idx}\\Autostart=true")
EOF >> "$CFG_FILE"

# Accept SSL certs automatically
export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt

# Start Nextcloud headless
exec nextcloud
