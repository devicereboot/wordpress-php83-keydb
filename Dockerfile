# ================================================================
# Device Reboot WordPress 8.3 + KeyDB/Redis + Imagick (Slim Build)
# ================================================================

FROM php:8.3-fpm-bookworm

LABEL maintainer="Device Reboot <support@devicereboot.com>"
LABEL description="Optimized WordPress (PHP 8.3 FPM) with Nginx, Imagick, Redis, APCu, and WP-CLI for CapRover"

# ------------------------------------------------
# 1. Install system dependencies
# ------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    nginx curl zip unzip git less vim nano \
    libjpeg-dev libpng-dev libwebp-dev libfreetype6-dev \
    libmagickwand-dev libzip-dev libonig-dev libxml2-dev \
    libmemcached-dev mariadb-client \
 && rm -rf /var/lib/apt/lists/*

# ------------------------------------------------
# 2. Configure PHP extensions
# ------------------------------------------------
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
 && docker-php-ext-install gd zip opcache intl mbstring bcmath exif mysqli pdo_mysql \
 && pecl install redis imagick apcu \
 && docker-php-ext-enable redis imagick apcu

# ------------------------------------------------
# 3. Configure PHP runtime
# ------------------------------------------------
COPY zz-php-opts.ini /usr/local/etc/php/conf.d/zz-php-opts.ini
RUN echo "memory_limit=512M\nupload_max_filesize=64M\npost_max_size=64M\nmax_execution_time=300" \
    > /usr/local/etc/php/conf.d/99-device-reboot.ini

# ------------------------------------------------
# 4. Install WP-CLI
# ------------------------------------------------
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
 && chmod +x wp-cli.phar && mv wp-cli.phar /usr/local/bin/wp

# ------------------------------------------------
# 5. Nginx configuration
# ------------------------------------------------
RUN mkdir -p /run/php /var/run/php /var/www/html

# Remove default site
RUN rm -f /etc/nginx/sites-enabled/default

# Add optimized WordPress Nginx config
RUN echo 'server {\n\
    listen 80;\n\
    root /var/www/html;\n\
    index index.php index.html;\n\
    server_name _;\n\
\n\
    location / {\n\
        try_files $uri $uri/ /index.php?$args;\n\
    }\n\
\n\
    location ~ \.php$ {\n\
        include snippets/fastcgi-php.conf;\n\
        fastcgi_pass 127.0.0.1:9000;\n\
    }\n\
\n\
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|webp)$ {\n\
        expires max;\n\
        log_not_found off;\n\
    }\n\
}' > /etc/nginx/sites-enabled/wordpress.conf

# ------------------------------------------------
# 6. Healthcheck
# ------------------------------------------------
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s \
 CMD curl -fsS http://localhost || exit 1

# ------------------------------------------------
# 7. Entrypoint
# ------------------------------------------------
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 80
WORKDIR /var/www/html

CMD ["/entrypoint.sh"]
