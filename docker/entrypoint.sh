#!/bin/sh
set -e

echo "[entrypoint] Running migrations..."
until php artisan migrate --force; do
    echo "[entrypoint] DB not ready, retrying in 3s..."
    sleep 3
done

echo "[entrypoint] Caching config, routes and views..."
php artisan config:cache
php artisan route:cache
php artisan view:cache

echo "[entrypoint] Starting application (APP_ENV=${APP_ENV})..."
exec "$@"
