#!/bin/bash
set -e

# Ensure PHP socket dir exists
mkdir -p /run/php /var/run/php

# Start nginx in background
nginx -g "daemon off;" &

# Start PHP-FPM in foreground
php-fpm -F
