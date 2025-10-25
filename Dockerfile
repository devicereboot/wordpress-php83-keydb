# ---- Base WordPress + PHP 8.3 FPM ----
FROM wordpress:php8.3-fpm

LABEL maintainer="Device Reboot / Motive Cyber"
LABEL description="WordPress + PHP8.3 + Nginx + Redis + Imagick + APCu + Auto Redis Connect (CapRover Ready)"

# ---- Install Nginx and dependencies ----
RUN apt-get update && \
    apt-get install -y nginx curl libzip-dev libjpeg-dev libpng-dev \
    libwebp-dev libmagickwand-dev libonig-dev libxml2-dev libmemcached-dev && \
    docker-php-ext-install zip gd opcache intl mbstring bcmath exif mysqli && \
    pecl install redis imagick apcu && \
    docker-php-ext-enable redis imagick apcu && \
    rm -rf /var/lib/apt/lists/*

# ---- Add WP-CLI ----
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && mv wp-cli.phar /usr/local/bin/wp

# ---- Auto-Configure Redis in wp-config.php ----
RUN echo '\n\
if ( getenv("REDIS_HOST") ) {\n\
    define("WP_REDIS_HOST", getenv("REDIS_HOST"));\n\
    define("WP_REDIS_PORT", getenv("REDIS_PORT") ?: 6379);\n\
    if ( getenv("REDIS_PASSWORD") ) define("WP_REDIS_PASSWORD", getenv("REDIS_PASSWORD"));\n\
    define("WP_REDIS_DISABLED", false);\n\
    define("WP_CACHE", true);\n\
}\n\
' >> /usr/src/wordpress/wp-config-docker.php

# ---- Nginx configuration (correct FPM socket) ----
RUN mkdir -p /var/run/php && \
    echo 'server { \
        listen 80; \
        server_name _; \
        root /var/www/html; \
        index index.php index.html; \
        location / { try_files $uri $uri/ /index.php?$args; } \
        location ~ \.php$$ { \
            include snippets/fastcgi-php.conf; \
            fastcgi_pass unix:/var/run/php/php-fpm.sock; \
            fastcgi_index index.php; \
        } \
        location ~ /\.ht { deny all; } \
    }' > /etc/nginx/sites-available/default

# ---- Tune OPcache ----
RUN echo "opcache.memory_consumption=256\n\
opcache.interned_strings_buffer=16\n\
opcache.max_accelerated_files=20000\n\
opcache.validate_timestamps=1\n\
opcache.revalidate_freq=2" > /usr/local/etc/php/conf.d/zz-opcache.ini

# ---- Expose HTTP ----
EXPOSE 80

# ---- Health check (optional) ----
HEALTHCHECK --interval=30s --timeout=5s \
  CMD curl -f http://localhost/ || exit 1

# ---- Start Nginx + PHP-FPM ----
CMD service nginx start && php-fpm -F
