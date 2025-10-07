# Nextcloud Client Docker Image

This Docker image provides a **headless Nextcloud client** based on `jlesage/baseimage-gui:debian-12-v4`, with persistent configuration and sync directories. Accounts are configured via a host-editable YAML file, and SSL certificates are automatically trusted. The client updates itself daily and restarts automatically.

---

## Features

- Multiple Nextcloud accounts support.
- Automatic generation of sync directories based on URL, user, and port.
- Persistent configuration under `/config` and sync folders under `/sync`.
- SSL certificates accepted without interaction.
- Daily automated updates with automatic client restart.
- Dynamic regeneration of `nextcloud.cfg` from YAML on container start.

---

## Directory Layout

```
nextcloud-docker/
├─ config/
│  └─ accounts.yml     # Host-editable account definitions
├─ sync/               # Persistent sync folders
├─ startapp.sh         # Entrypoint
├─ update-nextcloud.sh # Updates client and restarts
└─ Dockerfile
```

---

## accounts.yml Example

```yaml
accounts:
  - url: "https://cloud.x.y"
    user: "bla.blubb"
    app_password: "top$secret123"
  - url: "https://cloud.x.y:456"
    user: "hans.dampf"
    app_password: "pass#word"
  - url: "https://cloud.some.where"
    user: "user"
    app_password: "some739281&password"
```

**Notes:**

- Only `url`, `user`, and `app_password` are needed.
- Port numbers in URLs are safely converted to folder names (`:` → `-`).
- Sync directories are automatically created under `/sync`.

---

## Usage

### Build the image

```bash
docker build -t nextcloud-client .
```

### Run the container

```bash
docker run -d \
  -v /path/to/config:/config \
  -v /path/to/sync:/sync \
  --name nextcloud-client \
  nextcloud-client
```

- `/config` stores `accounts.yml` and generated `nextcloud.cfg`.  
- `/sync` is where all synced folders will appear.  

### Updating Accounts

1. Edit `accounts.yml` on the host.
2. Restart the container:

```bash
docker restart nextcloud-client
```

The container will regenerate `nextcloud.cfg` automatically and apply the updated configuration.

---

## Automatic Updates

- Updates are handled via `cron` inside the container at **midnight daily**.
- The Nextcloud client is upgraded, and the process is restarted automatically.
- Manual update can be triggered:

```bash
docker exec nextcloud-client /update-nextcloud.sh
```

---

## Notes

- Removed accounts will **not** automatically delete their synced folders; manage them manually in `/sync`.
- SSL certificates are trusted automatically for convenience.
- Only app passwords are supported; regular user passwords are not recommended.

