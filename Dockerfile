# ================================================================
# Device Reboot WordPress PHP 8.3 + Nginx + KeyDB/Redis + Imagick
# ================================================================

FROM php:8.3-fpm-bookworm

LABEL maintainer="Device Reboot <support@devicereboot.com>"
LABEL description="Slim, optimized WordPress PHP 8.3-FPM + Nginx + Redis + Imagick + APCu + WP-CLI for CapRover"

# ------------------------------------------------
# 1. System Dependencies
# ------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    nginx curl zip unzip git less nano mariadb-client \
    libjpeg-dev libpng-dev libwebp-dev libfreetype6-dev \
    libmagickwand-dev libzip-dev libonig-dev libxml2-dev libmemcached-dev \
 && rm -rf /var/lib/apt/lists/*

# ------------------------------------------------
# 2. PHP Extensions
# ------------------------------------------------
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
 && docker-php-ext-install gd zip opcache intl mbstring bcmath exif mysqli pdo_mysql \
 && pecl install redis imagick apcu \
 && docker-php-ext-enable redis imagick apcu

# ------------------------------------------------
# 3. PHP / OPcache Config
# ------------------------------------------------
COPY zz-php-opts.ini /usr/local/etc/php/conf.d/zz-php-opts.ini

# ------------------------------------------------
# 4. Install WP-CLI
# ------------------------------------------------
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
 && chmod +x wp-cli.phar && mv wp-cli.phar /usr/local/bin/wp

# ------------------------------------------------
# 5. Nginx Configuration
# ------------------------------------------------
RUN mkdir -p /run/php /var/www/html
RUN rm -f /etc/nginx/sites-enabled/default
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
# 6. Optional Redis Auto-Connect Hook
# ------------------------------------------------
RUN echo '\n\
if [ -n "$REDIS_HOST" ]; then\n\
  echo \"Setting up Redis cache...\"\n\
  WP_CONFIG=\"/var/www/html/wp-config.php\"\n\
  if [ -f \"$WP_CONFIG\" ]; then\n\
    grep -q \"WP_REDIS_HOST\" $WP_CONFIG || \\\n\
    sed -i \"/Happy publishing/i \\\n\
    define( 'WP_REDIS_HOST', getenv('REDIS_HOST') );\\n\\\n\
    define( 'WP_REDIS_PORT', getenv('REDIS_PORT') ?: 6379 );\\n\\\n\
    define( 'WP_REDIS_PASSWORD', getenv('REDIS_PASSWORD') ?: '' );\\n\\\n\
    define( 'WP_REDIS_DISABLED', false );\\n\" $WP_CONFIG;\n\
  fi\n\
fi\n' > /usr/local/bin/wp_redis_autoconnect.sh && chmod +x /usr/local/bin/wp_redis_autoconnect.sh

# ------------------------------------------------
# 7. Entrypoint
# ------------------------------------------------
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 80
WORKDIR /var/www/html

CMD ["/entrypoint.sh"]
