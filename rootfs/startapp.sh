#!/bin/bash
set -euo pipefail

CONFIG_DIR="/config/xdg/config/Nextcloud"
mkdir -p "$CONFIG_DIR"
SYNC_BASE="/sync"
mkdir -p "$SYNC_BASE"

CFG_FILE="$CONFIG_DIR/nextcloud.cfg"
HASH_FILE="$CONFIG_DIR/accounts.hash"

# Ensure SSL certs are accepted silently
export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt

# ------------------------------------------------------------------------------
# Parse YAML and generate nextcloud.cfg
# ------------------------------------------------------------------------------
python3 - <<'EOF'
import yaml, os, hashlib, urllib.parse, re

CONFIG_DIR = os.path.expanduser("~/.config/Nextcloud")
SYNC_BASE = "/sync"
CFG_FILE = os.path.join(CONFIG_DIR, "nextcloud.cfg")
HASH_FILE = os.path.join(CONFIG_DIR, "accounts.hash")
ACCOUNTS_YML = "/config/accounts.yml"

def safe_path_from_url(url):
    parsed = urllib.parse.urlparse(url)
    host = parsed.hostname or "unknown"
    port = f"-{parsed.port}" if parsed.port else ""
    return f"{host}{port}"

if not os.path.exists(ACCOUNTS_YML):
    print(f"WARNING: {ACCOUNTS_YML} missing; no accounts will be configured.")
    os.makedirs(CONFIG_DIR, exist_ok=True)
    with open(CFG_FILE, "w") as f:
        f.write("[General]\nconfirmExternalStorage=false\nuseNewBigFolderSizeLimit=false\nshowMainDialogAsNormalWindow=true\n")
    raise SystemExit(0)

# Compute hash to track changes
with open(ACCOUNTS_YML, "rb") as f:
    new_hash = hashlib.sha256(f.read()).hexdigest()

# Read old hash if present
old_hash = ""
if os.path.exists(HASH_FILE):
    with open(HASH_FILE) as f:
        old_hash = f.read().strip()

# Always regenerate (since user requested auto-syncing)
with open(ACCOUNTS_YML) as f:
    data = yaml.safe_load(f)

accounts = data.get("accounts", [])
os.makedirs(CONFIG_DIR, exist_ok=True)
os.makedirs(SYNC_BASE, exist_ok=True)

# Prepare header
cfg_lines = [
    "[General]",
    "confirmExternalStorage=false",
    "useNewBigFolderSizeLimit=false",
    "showMainDialogAsNormalWindow=true",
    "",
    "[Accounts]"
]

for idx, acct in enumerate(accounts):
    url = acct["url"].strip().rstrip("/")
    user = acct["user"].strip()
    password = acct["app_password"].strip()

    safe_host = safe_path_from_url(url)
    sync_dir = os.path.join(SYNC_BASE, safe_host, user)
    os.makedirs(sync_dir, exist_ok=True)

    cfg_lines += [
        f"{idx}\\url={url}",
        f"{idx}\\User={user}",
        f"{idx}\\AppPassword={password}",
        f"{idx}\\SyncDir={sync_dir}",
        f"{idx}\\Autostart=true",
        f"{idx}\\authType=basic",
        f"{idx}\\dav_user={user}",
        f"{idx}\\displayName={user}",
        f"{idx}\\version=1",
        ""
    ]

# Write final config
with open(CFG_FILE, "w") as f:
    f.write("\n".join(cfg_lines))

# Update hash
with open(HASH_FILE, "w") as f:
    f.write(new_hash)
EOF

# ------------------------------------------------------------------------------
# Launch Nextcloud client
# ------------------------------------------------------------------------------
exec nextcloud
