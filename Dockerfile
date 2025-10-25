FROM wordpress:php8.3-fpm

RUN apt-get update && apt-get install -y \
    libzip-dev libjpeg-dev libpng-dev libwebp-dev \
    libmagickwand-dev libonig-dev libxml2-dev libmemcached-dev \
    curl git unzip && \
    docker-php-ext-install zip gd opcache intl mbstring bcmath exif && \
    pecl install redis imagick apcu && \
    docker-php-ext-enable redis imagick apcu && \
    rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    -o /usr/local/bin/wp && chmod +x /usr/local/bin/wp

WORKDIR /var/www/html
EXPOSE 9000
CMD ["php-fpm"]
