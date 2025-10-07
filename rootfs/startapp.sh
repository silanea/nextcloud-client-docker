#!/bin/bash
set -euo pipefail
# Ensure SSL certs are accepted silently
export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt

# ------------------------------------------------------------------------------
# Directories and files
# ------------------------------------------------------------------------------
mkdir -p /xdg/config /xdg/cache /xdg/data /xdg/state
chown -R $(id -u):$(id -g) /xdg

CONFIG_HOME="${XDG_CONFIG_HOME:-/xdg/config}"
CONFIG_DIR="$CONFIG_HOME/Nextcloud"
CONFIG_FILE="$CONFIG_DIR/nextcloud.cfg"
LEGACY_CONFIG_DIR="$HOME/.config/Nextcloud"
LEGACY_CONFIG_FILE="$LEGACY_CONFIG_DIR/nextcloud.cfg"
ACCOUNTS_FILE="/config/accounts.yml"

# Ensure directory structure
mkdir -p "$CONFIG_DIR" "$LEGACY_CONFIG_DIR" /sync
rm -f "$LEGACY_CONFIG_FILE"
ln -sf "$CONFIG_FILE" "$LEGACY_CONFIG_FILE"

# ------------------------------------------------------------------------------
# Unify configuration path: always use /xdg/config/Nextcloud/nextcloud.cfg
# ------------------------------------------------------------------------------
if [ -L "$LEGACY_CONFIG_FILE" ] || [ -f "$LEGACY_CONFIG_FILE" ]; then
    rm -f "$LEGACY_CONFIG_FILE"
fi
ln -sf "$CONFIG_FILE" "$LEGACY_CONFIG_FILE"

# ------------------------------------------------------------------------------
# Generate nextcloud.cfg from accounts.yml
# ------------------------------------------------------------------------------
python3 - <<'EOF'
import yaml, os, hashlib, urllib.parse

CONFIG_DIR = os.path.expanduser("/xdg/config/Nextcloud")
SYNC_BASE = "/sync"
CFG_FILE = os.path.join(CONFIG_DIR, "nextcloud.cfg")
HASH_FILE = os.path.join(CONFIG_DIR, "accounts.hash")
ACCOUNTS_YML = "/config/accounts.yml"

def safe_path_from_url(url):
    parsed = urllib.parse.urlparse(url)
    host = parsed.hostname or "unknown"
    port = f"-{parsed.port}" if parsed.port else ""
    return f"{host}{port}"

# Handle missing config gracefully
if not os.path.exists(ACCOUNTS_YML):
    print(f"WARNING: {ACCOUNTS_YML} missing; no accounts will be configured.")
    os.makedirs(CONFIG_DIR, exist_ok=True)
    with open(CFG_FILE, "w") as f:
        f.write("[General]\nconfirmExternalStorage=false\nuseNewBigFolderSizeLimit=false\nshowMainDialogAsNormalWindow=true\n")
    raise SystemExit(0)

# Compute hash to track changes
with open(ACCOUNTS_YML, "rb") as f:
    new_hash = hashlib.sha256(f.read()).hexdigest()

old_hash = ""
if os.path.exists(HASH_FILE):
    with open(HASH_FILE) as f:
        old_hash = f.read().strip()

# Always regenerate config (auto-sync)
with open(ACCOUNTS_YML) as f:
    data = yaml.safe_load(f)

accounts = data.get("accounts", [])
os.makedirs(CONFIG_DIR, exist_ok=True)
os.makedirs(SYNC_BASE, exist_ok=True)

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

with open(CFG_FILE, "w") as f:
    f.write("\n".join(cfg_lines))

with open(HASH_FILE, "w") as f:
    f.write(new_hash)

EOF

# ------------------------------------------------------------------------------
# Accept SSL certs automatically and start client
# ------------------------------------------------------------------------------
export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt

echo "✅ Configuration ready, starting Nextcloud client..."
exec nextcloud
