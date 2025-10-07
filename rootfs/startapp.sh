#!/bin/bash
set -e

CONFIG_DIR="/config/xdg/config/Nextcloud"
mkdir -p "$CONFIG_DIR"
SYNC_BASE="/sync"
mkdir -p "$SYNC_BASE"

CFG_FILE="$CONFIG_DIR/nextcloud.cfg"
TMP_CFG="$(mktemp)"

echo "[Accounts]" > "$TMP_CFG"

python3 - <<'EOF' >> "$TMP_CFG"
import yaml, os, urllib.parse

with open("/config/accounts.yml") as f:
    data = yaml.safe_load(f)

for idx, acct in enumerate(data["accounts"]):
    url = acct["url"].rstrip("/")
    user = acct["user"]
    password = acct["app_password"]

    parsed = urllib.parse.urlparse(url)
    host = parsed.hostname
    port = parsed.port
    safe_port = f"-{port}" if port else ""
    safe_path = os.path.join(host + safe_port, user)

    sync_dir = os.path.join("/sync", safe_path)
    os.makedirs(sync_dir, exist_ok=True)

    print(f"{idx}\\AppPassword={password}")
    print(f"{idx}\\Autostart=true")
    print(f"{idx}\\SyncDir={sync_dir}")
    print(f"{idx}\\url={url}")
    print(f"{idx}\\User={user}")
    print(f"{idx}\\authType=webflow")
    print(f"{idx}\\webflow_user={user}")
    print(f"{idx}\\dav_user={user}")
    print(f"{idx}\\version=1")
    print(f"{idx}\\Folders\\1\\localPath={sync_dir}/")
    print(f"{idx}\\Folders\\1\\targetPath=/")
    print(f"{idx}\\Folders\\1\\version=2")
    print(f"{idx}\\Folders\\1\\paused=false")
    print(f"{idx}\\Folders\\1\\ignoreHiddenFiles=false")
    print(f"{idx}\\Folders\\1\\virtualFilesMode=off")
    print()  # blank line between accounts
EOF

# Merge with old config, preserving everything after [Accounts]
if [ -f "$CFG_FILE" ]; then
    awk '
        /^\[Accounts\]$/ {in_accounts=1; next}
        /^\[/ && in_accounts {in_accounts=0}
        !in_accounts
    ' "$CFG_FILE" >> "$TMP_CFG"
else
    cat <<EOG >> "$TMP_CFG"

[General]
confirmExternalStorage=false
useNewBigFolderSizeLimit=false
showMainDialogAsNormalWindow=true
EOG
fi

mv "$TMP_CFG" "$CFG_FILE"

# Ensure system trusts SSL without interaction
export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt

exec nextcloud
