# SuiteCRM Docker — Multi-arch

[![Build & Push](https://github.com/bunnydrummer/suitecrm-docker/actions/workflows/build.yml/badge.svg)](https://github.com/bunnydrummer/suitecrm-docker/actions/workflows/build.yml)
[![Docker Pulls](https://img.shields.io/docker/pulls/bunnydrummer/suitecrm)](https://hub.docker.com/r/bunnydrummer/suitecrm)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Docker image for **SuiteCRM 8.9** supporting multiple architectures — works on standard Linux servers, Raspberry Pi 5 (arm64) and Raspberry Pi 3/4 (arm/v7).

## Supported architectures

| Architecture | Device |
|---|---|
| `linux/amd64` | Standard Linux server / VPS |
| `linux/arm64` | Raspberry Pi 5, Pi 4 (64-bit OS) |
| `linux/arm/v7` | Raspberry Pi 3/4 (32-bit OS) |

## Quick start

### 1. Clone the repo

```bash
git clone https://github.com/bunnydrummer/suitecrm-docker.git
cd suitecrm-docker
```

### 2. Configure

```bash
cp .env.example .env
nano .env   # set passwords, timezone, data directory, port
```

### 3. Run setup

```bash
chmod +x setup.sh
./setup.sh
```

### 4. Start

```bash
docker compose up -d
```

### 5. Install via browser

Open `http://<your-host>:<HTTP_PORT>` and complete the wizard.

Use these DB values:

| Field | Value |
|---|---|
| Host | `db` |
| Port | `3306` |
| Database | value of `DB_NAME` in `.env` |
| Username | value of `DB_USER` in `.env` |
| Password | value of `DB_PASSWORD` in `.env` |

> `config.php` is already bind-mounted — configuration persists across restarts automatically, no manual `docker cp` needed.

---

## Configuration

All settings are in `.env`:

| Variable | Default | Description |
|---|---|---|
| `DOCKER_IMAGE` | `bunnydrummer/suitecrm:latest` | Image to use |
| `DATA_DIR` | `/opt/suitecrm/data` | Host path for persistent data |
| `HTTP_PORT` | `8080` | Host port for HTTP |
| `TZ` | `Europe/London` | Timezone |
| `DB_ROOT_PASSWORD` | — | MariaDB root password |
| `DB_NAME` | `suitecrm` | Database name |
| `DB_USER` | `suitecrm` | Database user |
| `DB_PASSWORD` | — | Database password |

---

## Useful commands

```bash
# View logs
docker compose logs -f suitecrm

# Shell into app container
docker compose exec suitecrm bash

# View PHP errors
docker compose exec suitecrm tail -f /var/log/apache2/php_errors.log

# Stop
docker compose down

# Stop and remove all data (careful!)
docker compose down -v
```

---

## Behind a reverse proxy (Nginx Proxy Manager, Traefik, etc.)

Set `HTTP_PORT` to an internal port (e.g. `8080`) and let your proxy handle 80/443.
The `suitecrm_net` Docker network is named explicitly so external proxies can join it:

```yaml
# In your proxy docker-compose.yml
networks:
  suitecrm_net:
    external: true
```

---

## Building locally

```bash
# Single arch (e.g. for local testing)
docker build -t suitecrm:local .

# Multi-arch push to Docker Hub
docker buildx build \
  --platform linux/amd64,linux/arm64,linux/arm/v7 \
  -t bunnydrummer/suitecrm:8.9.0 \
  -t bunnydrummer/suitecrm:latest \
  --push .
```

---

## CI/CD

Push to `main` triggers a GitHub Actions workflow that:
1. Builds `amd64` on a native x86 runner
2. Builds `arm64` on a native arm64 runner (no QEMU — fast)
3. Builds `arm/v7` with QEMU
4. Merges all three into a single multi-arch manifest on Docker Hub

You can also trigger a manual build from the **Actions** tab with a custom version number.

Required secrets: `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN`

---

## License

MIT — see [LICENSE](LICENSE)

SuiteCRM is licensed under [AGPL v3](https://github.com/salesagility/SuiteCRM-Core/blob/main/LICENSE).
