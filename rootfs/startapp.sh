#!/bin/bash
set -euo pipefail
# Ensure SSL certs are accepted silently
export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt

# ------------------------------------------------------------------------------
# Resolve XDG base dirs (all within /config to persist)
# ------------------------------------------------------------------------------
export XDG_CONFIG_HOME="/config/xdg/config"
export XDG_CACHE_HOME="/config/xdg/cache"
export XDG_DATA_HOME="/config/xdg/data"
export XDG_STATE_HOME="/config/xdg/state"

mkdir -p "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME"

export CONFIG_HOME="${XDG_CONFIG_HOME:-/xdg/config}"
export CONFIG_DIR="$CONFIG_HOME/Nextcloud"
export CONFIG_FILE="$CONFIG_DIR/nextcloud.cfg"
export ACCOUNTS_FILE="/config/accounts.yml"

# ------------------------------------------------------------------------------
# Generate configuration from YAML
# ------------------------------------------------------------------------------
python3 - <<'EOF'
import yaml, os, hashlib, urllib.parse

CFG_FILE = os.environ["CONFIG_FILE"]
ACCOUNTS_YML = os.environ["ACCOUNTS_FILE"]
SYNC_BASE = "/sync"

os.makedirs(os.path.dirname(CFG_FILE), exist_ok=True)

def safe_path(url):
    p = urllib.parse.urlparse(url)
    host = p.hostname or "unknown"
    port = f"-{p.port}" if p.port else ""
    return f"{host}{port}"

with open(ACCOUNTS_YML) as f:
    data = yaml.safe_load(f) or {}

accounts = data.get("accounts", [])

cfg = [
    "[General]",
    "confirmExternalStorage=false",
    "useNewBigFolderSizeLimit=false",
    "showMainDialogAsNormalWindow=true",
    "",
    "[Accounts]"
]

for idx, acct in enumerate(accounts):
    url = acct["url"].rstrip("/")
    user = acct["user"]
    pw = acct["app_password"]
    sync = os.path.join(SYNC_BASE, safe_path(url), user)
    os.makedirs(sync, exist_ok=True)
    cfg += [
        f"{idx}\\url={url}",
        f"{idx}\\User={user}",
        f"{idx}\\AppPassword={pw}",
        f"{idx}\\SyncDir={sync}",
        f"{idx}\\Autostart=true",
        f"{idx}\\authType=basic",
        f"{idx}\\dav_user={user}",
        f"{idx}\\displayName={user}",
        f"{idx}\\version=1",
        ""
    ]

with open(CFG_FILE, "w") as f:
    f.write("\n".join(cfg))
EOF

# ------------------------------------------------------------------------------
# Accept SSL certs automatically and start client
# ------------------------------------------------------------------------------
export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt

echo "✅ Configuration ready, starting Nextcloud client..."
exec nextcloud
