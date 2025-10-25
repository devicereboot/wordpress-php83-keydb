# ───────────────────────────────────────────────────────────────
#  WordPress PHP 8.3 + Apache + PhpRedis + KeyDB-ready
#  Tuned for 2–4 GB memory environments
#  Maintainer: Device Reboot
# ───────────────────────────────────────────────────────────────
FROM wordpress:php8.3-apache

LABEL maintainer="Device Reboot <contact@devicereboot.com>"
LABEL version="2025.3"
LABEL description="WordPress 8.3 + Apache + PhpRedis + KeyDB (2–4 GB optimized build)"

# --- Compile PhpRedis correctly ---
RUN apt-get update && apt-get install -y \
        autoconf make gcc g++ pkg-config libssl-dev \
        libcurl4-openssl-dev libzip-dev netcat-openbsd \
    && docker-php-source extract \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && docker-php-source delete \
    && apt-get purge -y autoconf make gcc g++ \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# --- PHP & Opcache tuning for 2–4 GB containers ---
RUN { \
    echo 'upload_max_filesize=1G'; \
    echo 'post_max_size=1G'; \
    echo 'memory_limit=2048M'; \
    echo 'max_execution_time=600'; \
    echo 'max_input_vars=16000'; \
    echo 'opcache.enable=1'; \
    echo 'opcache.memory_consumption=512'; \
    echo 'opcache.interned_strings_buffer=32'; \
    echo 'opcache.max_accelerated_files=40000'; \
    echo 'opcache.revalidate_freq=2'; \
    echo 'opcache.validate_timestamps=1'; \
  } > /usr/local/etc/php/conf.d/99-performance.ini

# --- Copy the KeyDB-aware startup script ---
COPY wp-redis-init.sh /usr/local/bin/wp-redis-init.sh
RUN chmod +x /usr/local/bin/wp-redis-init.sh

ENTRYPOINT ["/usr/local/bin/wp-redis-init.sh"]
