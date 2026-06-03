#!/bin/sh
set -e

echo "[entrypoint] Installing PHP dependencies..."
composer install --no-interaction

echo "[entrypoint] Running migrations..."
until php artisan migrate --force; do
    echo "[entrypoint] DB not ready, retrying in 3s..."
    sleep 3
done

echo "[entrypoint] Starting development server (APP_ENV=${APP_ENV})..."
exec "$@"
