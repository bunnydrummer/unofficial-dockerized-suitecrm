#  =============================================================================
# SuiteCRM 8.9.x — Multi-arch Dockerfile
# Supports: linux/amd64, linux/arm64, linux/arm/v7
#
# Build & push:
#   docker buildx build \
#     --platform linux/amd64,linux/arm64,linux/arm/v7 \
#     -t bunnydrummer/suitecrm:8.9.0 \
#     -t bunnydrummer/suitecrm:latest \
#     --push .
# =============================================================================

FROM php:8.2-apache-bookworm

LABEL maintainer="bunnydrummer"
LABEL description="SuiteCRM 8.9 multi-arch Docker image (amd64, arm64, arm/v7)"
LABEL org.opencontainers.image.source="https://github.com/bunnydrummer/suitecrm-docker"
LABEL org.opencontainers.image.licenses="MIT"

ENV SUITECRM_VERSION=8.9.0 \
    TZ=Europe/London

# ---------------------------------------------------------------------------
# System packages
# ---------------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
        tzdata \
        curl \
        wget \
        unzip \
        cron \
        openssl \
        libicu-dev \
        libcurl4-openssl-dev \
        libmagickwand-dev \
        libpng-dev \
        libjpeg62-turbo-dev \
        libwebp-dev \
        libfreetype6-dev \
        libzip-dev \
        libxml2-dev \
        libbz2-dev \
        libonig-dev \
        libgmp-dev \
        libldap2-dev \
        libc-client-dev \
        libkrb5-dev \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# PHP extensions
# ---------------------------------------------------------------------------
RUN docker-php-ext-configure gd \
        --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-configure imap \
        --with-kerberos --with-imap-ssl \
    && docker-php-ext-install -j$(nproc) \
        bcmath bz2 calendar curl exif gd gmp imap intl ldap \
        mbstring mysqli opcache pdo_mysql soap xml zip \
    && pecl install imagick \
    && docker-php-ext-enable imagick \
    && rm -rf /tmp/pear

# ---------------------------------------------------------------------------
# PHP runtime config
# ---------------------------------------------------------------------------
RUN { \
        echo "memory_limit = 512M"; \
        echo "upload_max_filesize = 100M"; \
        echo "post_max_size = 100M"; \
        echo "max_execution_time = 300"; \
        echo "max_input_time = 300"; \
        echo "max_input_vars = 10000"; \
        echo "date.timezone = ${TZ}"; \
        echo "session.name = PHPSESSID"; \
        echo "session.gc_maxlifetime = 21600"; \
        echo "error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT & ~E_NOTICE & ~E_WARNING"; \
        echo "display_errors = Off"; \
        echo "log_errors = On"; \
        echo "error_log = /var/log/apache2/php_errors.log"; \
        echo "opcache.enable = 1"; \
        echo "opcache.memory_consumption = 128"; \
        echo "opcache.interned_strings_buffer = 16"; \
        echo "opcache.max_accelerated_files = 10000"; \
        echo "opcache.revalidate_freq = 60"; \
        echo "opcache.fast_shutdown = 1"; \
    } > /usr/local/etc/php/conf.d/suitecrm.ini

# ---------------------------------------------------------------------------
# Apache
# ---------------------------------------------------------------------------
RUN a2enmod rewrite headers expires deflate ssl
COPY apache-suitecrm.conf /etc/apache2/conf-available/suitecrm.conf
RUN a2enconf suitecrm \
    && sed -i "s#DocumentRoot /var/www/html#DocumentRoot /var/www/html/public#g" \
       /etc/apache2/sites-available/000-default.conf

# ---------------------------------------------------------------------------
# Download SuiteCRM 8
# ---------------------------------------------------------------------------
WORKDIR /var/www/html

RUN wget -q \
        "https://github.com/salesagility/SuiteCRM-Core/releases/download/v${SUITECRM_VERSION}/SuiteCRM-${SUITECRM_VERSION}.zip" \
        -O /tmp/suitecrm.zip \
    && unzip -q /tmp/suitecrm.zip -d /tmp/suitecrm_src \
    && SUBDIR=$(find /tmp/suitecrm_src -maxdepth 1 -mindepth 1 -type d | head -1) \
    && if [ -n "$SUBDIR" ] && [ -f "$SUBDIR/index.php" ]; then \
         cp -r "$SUBDIR/." /var/www/html/; \
       else \
         cp -r /tmp/suitecrm_src/. /var/www/html/; \
       fi \
    && rm -rf /tmp/suitecrm.zip /tmp/suitecrm_src

# ---------------------------------------------------------------------------
# Permissions
# ---------------------------------------------------------------------------
RUN find /var/www/html -type d -exec chmod 755 {} \; \
    && find /var/www/html -type f -exec chmod 644 {} \; \
    && for dir in cache custom modules themes data upload logs vendor public; do \
         [ -d "$dir" ] && chmod 775 "$dir" || true; \
       done \
    && chmod 775 config_override.php 2>/dev/null || true \
    && chown -R www-data:www-data /var/www/html

# ---------------------------------------------------------------------------
# Entrypoint
# ---------------------------------------------------------------------------
COPY entrypoint.sh /entrypoint.sh
RUN sed -i 's/\r//' /entrypoint.sh && chmod +x /entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]
CMD ["apache2-foreground"]
