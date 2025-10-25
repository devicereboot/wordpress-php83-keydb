#!/bin/bash
set -e
echo "[$(date)] Booting WordPress with KeyDB cache..."
WP_CONFIG=/var/www/html/wp-config.php

echo "Waiting for MySQL..."
until nc -z ${WORDPRESS_DB_HOST%:*} 3306; do
  echo "MySQL not ready, retrying in 3s..."
  sleep 3
done

echo "Waiting for KeyDB..."
until nc -z ${REDIS_HOST:-keydb} ${REDIS_PORT:-6379}; do
  echo "KeyDB not ready, retrying in 3s..."
  sleep 3
done

# Clear old object cache file
rm -f /var/www/html/wp-content/object-cache.php || true

# Inject Redis constants into wp-config.php if missing
if [ -f "$WP_CONFIG" ]; then
  if ! grep -q WP_REDIS_HOST "$WP_CONFIG"; then
    echo "Injecting Redis constants..."
    sed -i "/Happy publishing/i \
    define('WP_REDIS_HOST', '${REDIS_HOST:-keydb}');\n\
    define('WP_REDIS_PORT', ${REDIS_PORT:-6379});\n\
    define('WP_REDIS_DATABASE', ${REDIS_DB:-0});\n\
    define('WP_CACHE_KEY_SALT', 'devicereboot');\n\
    define('WP_CACHE', true);" "$WP_CONFIG"
  fi
fi

echo "[$(date)] Starting Apache..."
exec apache2-foreground
