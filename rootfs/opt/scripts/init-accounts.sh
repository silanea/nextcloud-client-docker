#!/bin/bash
set -e

CONFIG_DIR="/config"
SYNC_ROOT="/sync"

i=1
while true; do
    eval URL=\$NC_${i}_URL
    eval USER=\$NC_${i}_USER
    eval PW=\$NC_${i}_PW

    [[ -z "$URL" || -z "$USER" || -z "$PW" ]] && break

    DOMAIN="${URL#https://}"
    DOMAIN="${DOMAIN#http://}"
    TARGET_DIR="${SYNC_ROOT}/${DOMAIN}/${USER}"
    mkdir -p "$TARGET_DIR"

    echo "Setting up Nextcloud account #$i: ${USER}@${URL}"

    ACC_JSON="${CONFIG_DIR}/account-${i}.json"
    cat > "$ACC_JSON" <<EOF
{
  "url": "${URL}",
  "user": "${USER}",
  "password": "${PW}",
  "syncDir": "${TARGET_DIR}"
}
EOF

    ((i++))
done
