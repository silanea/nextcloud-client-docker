#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------------------------
# XDG setup (persistent within /config)
# ------------------------------------------------------------------------------
export XDG_CONFIG_HOME="/config/xdg/config"
export XDG_CACHE_HOME="/config/xdg/cache"
export XDG_DATA_HOME="/config/xdg/data"
export XDG_STATE_HOME="/config/xdg/state"

mkdir -p "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME"

export CONFIG_DIR="$XDG_CONFIG_HOME/Nextcloud"
export CONFIG_FILE="$CONFIG_DIR/nextcloud.cfg"
export ACCOUNTS_FILE="/config/accounts.yml"
export LEGACY_PATH="/config/.config/Nextcloud/nextcloud.cfg"

mkdir -p "$CONFIG_DIR"

# ------------------------------------------------------------------------------
# Generate configuration from YAML
# ------------------------------------------------------------------------------
python3 - <<'EOF'
import yaml, os, urllib.parse

CFG_FILE = os.environ["CONFIG_FILE"]
ACCOUNTS_YML = os.environ["ACCOUNTS_FILE"]
SYNC_BASE = "/sync"

def safe_path(url):
    p = urllib.parse.urlparse(url)
    host = p.hostname or "unknown"
    port = f"-{p.port}" if p.port else ""
    return f"{host}{port}"

if not os.path.exists(ACCOUNTS_YML):
    print(f"WARNING: {ACCOUNTS_YML} missing; no accounts will be configured.")
    os.makedirs(os.path.dirname(CFG_FILE), exist_ok=True)
    with open(CFG_FILE, "w") as f:
        f.write("[General]\nconfirmExternalStorage=false\nuseNewBigFolderSizeLimit=false\nshowMainDialogAsNormalWindow=true\n")
    raise SystemExit(0)

with open(ACCOUNTS_YML) as f:
    data = yaml.safe_load(f) or {}

accounts = data.get("accounts", [])
os.makedirs(os.path.dirname(CFG_FILE), exist_ok=True)
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
    safe_host = safe_path(url)
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
EOF

# ------------------------------------------------------------------------------
# Keep legacy path in sync (symlink)
# ------------------------------------------------------------------------------
mkdir -p "$(dirname "$LEGACY_PATH")"
ln -sf "$CONFIG_FILE" "$LEGACY_PATH"

echo "[INFO] Configuration written to: $CONFIG_FILE"
echo "[INFO] Legacy symlink created at: $LEGACY_PATH"

# ------------------------------------------------------------------------------
# Start Nextcloud client
# ------------------------------------------------------------------------------
exec nextcloud &
wait
