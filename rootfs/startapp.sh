#!/usr/bin/env bash
set -euo pipefail

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
        f"{idx}\\webflow_password={pw}",
        f"{idx}\\SyncDir={sync}",
        f"{idx}\\Autostart=true",
        f"{idx}\\authType=webflow",
        f"{idx}\\webflow_user={user}",
        f"{idx}\\displayName={user}",
        f"{idx}\\version=1",
        ""
    ]

with open(CFG_FILE, "w") as f:
    f.write("\n".join(cfg))
EOF
        ((i++))
    done
}

# ------------------------------------------------------------------------------
# Function: prune orphaned accounts from local storage
# ------------------------------------------------------------------------------
prune_obsolete_accounts() {
    log "Pruning obsolete account directories not listed in accounts.yml …"

    local listed_users
    listed_users=$(yq -r '.accounts[].user' "$ACCOUNTS_YAML" | sort -u)

    # Check for local data folders (under /data/*)
    if [[ -d /data ]]; then
        for dir in /data/*; do
            [[ -d "$dir" ]] || continue
            local user
            user=$(basename "$dir")
            if ! grep -qx "$user" <<<"$listed_users"; then
                log "→ Removing obsolete account config for $user (keeping data intact)"
                # Just remove any matching config lines — don't delete data
                sed -i "/user=$user/,/localPath=\/data\/$user/d" "$CONFIG_FILE" || true
            fi
        done
    fi
}

# ------------------------------------------------------------------------------
# Function: sync symlink (avoid config duplication)
# ------------------------------------------------------------------------------
sync_symlink() {
    log "Ensuring consistent config symlink …"
    mkdir -p "$(dirname "$SYMLINK_PATH")"
    ln -sf "$CONFIG_FILE" "$SYMLINK_PATH"
}

# ------------------------------------------------------------------------------
# Main execution
# ------------------------------------------------------------------------------
if [[ ! -f "$ACCOUNTS_YAML" ]]; then
    log "❌ Missing $ACCOUNTS_YAML — cannot start client."
    exit 1
fi

generate_config
prune_obsolete_accounts
sync_symlink

log "Configuration successfully written and linked."
log "Starting Nextcloud client …"

# ------------------------------------------------------------------------------
# Launch client (non-blocking)
# ------------------------------------------------------------------------------
exec nextcloud &
wait
