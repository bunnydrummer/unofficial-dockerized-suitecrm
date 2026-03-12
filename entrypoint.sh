#!/bin/bash
# =============================================================================
# entrypoint.sh — SuiteCRM 8 container entrypoint
# =============================================================================

set -e

SUITECRM_DIR=/var/www/html
OAUTH_DIR="${SUITECRM_DIR}/Api/V8/OAuth2"

# ---------------------------------------------------------------------------
# 1. Generate OAuth2 keys if missing
# ---------------------------------------------------------------------------
if [ ! -f "${OAUTH_DIR}/private.key" ]; then
    echo "[entrypoint] Generating OAuth2 keys..."
    mkdir -p "${OAUTH_DIR}"
    openssl genrsa -out "${OAUTH_DIR}/private.key" 2048 2>/dev/null
    openssl rsa -in "${OAUTH_DIR}/private.key" \
                -pubout -out "${OAUTH_DIR}/public.key" 2>/dev/null
    chmod 600 "${OAUTH_DIR}/private.key"
    chmod 644 "${OAUTH_DIR}/public.key"
    chown www-data:www-data "${OAUTH_DIR}/private.key" "${OAUTH_DIR}/public.key"
    echo "[entrypoint] OAuth2 keys ready."
fi

# ---------------------------------------------------------------------------
# 2. Fix permissions on volume-mounted directories
# ---------------------------------------------------------------------------
chown -R www-data:www-data \
    "${SUITECRM_DIR}/cache" \
    "${SUITECRM_DIR}/custom" \
    "${SUITECRM_DIR}/modules" \
    "${SUITECRM_DIR}/themes" \
    "${SUITECRM_DIR}/data" \
    "${SUITECRM_DIR}/upload" \
    "${SUITECRM_DIR}/logs" \
    "${SUITECRM_DIR}/public" \
    2>/dev/null || true

# Fix config.php permissions if bind-mounted
if [ -f "${SUITECRM_DIR}/config.php" ]; then
    chown www-data:www-data "${SUITECRM_DIR}/config.php"
    chmod 664 "${SUITECRM_DIR}/config.php"
fi
if [ -f "${SUITECRM_DIR}/config_override.php" ]; then
    chown www-data:www-data "${SUITECRM_DIR}/config_override.php"
    chmod 664 "${SUITECRM_DIR}/config_override.php"
fi

# ---------------------------------------------------------------------------
# 3. SuiteCRM 8 scheduler
# ---------------------------------------------------------------------------
if [ ! -f /etc/cron.d/suitecrm ]; then
    echo "* * * * * www-data php ${SUITECRM_DIR}/bin/console schedulers:run > /dev/null 2>&1" \
        > /etc/cron.d/suitecrm
    chmod 0644 /etc/cron.d/suitecrm
fi
service cron start || true

# ---------------------------------------------------------------------------
# 4. Start Apache
# ---------------------------------------------------------------------------
exec "$@"
