#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------------------------
# Nextcloud Client Auto Configuration + Sync Wrapper
# ------------------------------------------------------------------------------
# - Reads /config/accounts.yml
# - Generates a clean nextcloud.cfg (no keychain)
# - Removes accounts not listed in accounts.yml
# - Updates changed credentials
# - Creates consistent symlink between /config/xdg/config and ~/.config
# ------------------------------------------------------------------------------

CONFIG_DIR="/config/xdg/config/Nextcloud"
CONFIG_FILE="${CONFIG_DIR}/nextcloud.cfg"
SYMLINK_PATH="/root/.config/Nextcloud/nextcloud.cfg"
ACCOUNTS_YAML="/config/accounts.yml"

# Environment for headless / container use
export NEXTCLOUD_NO_KEYCHAIN=1
export QT_LOGGING_RULES="*.debug=false"

mkdir -p "$CONFIG_DIR" "$(dirname "$SYMLINK_PATH")"

# ------------------------------------------------------------------------------
# Function: log helper
# ------------------------------------------------------------------------------
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >&2
}

# ------------------------------------------------------------------------------
# Function: regenerate config file from YAML
# ------------------------------------------------------------------------------
generate_config() {
    log "Generating nextcloud.cfg from $ACCOUNTS_YAML …"

    echo "[Accounts]" > "$CONFIG_FILE"
    echo "version=2" >> "$CONFIG_FILE"

    i=0
    yq -o=json '.accounts[]' "$ACCOUNTS_YAML" | jq -c '.' | while read -r entry; do
        url=$(echo "$entry" | jq -r '.url')
        user=$(echo "$entry" | jq -r '.user')
        pass=$(echo "$entry" | jq -r '.app_password')

        if [[ -z "$url" || -z "$user" || -z "$pass" ]]; then
            log "⚠️  Skipping incomplete account (url/user/pass missing)"
            continue
        fi

        cat >> "$CONFIG_FILE" <<EOF

[Accounts/$i]
url=$url
user=$user
dav_user=$user
authType=http
authMethod=password
password=$pass
localPath=/data/$user
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
