FROM php:8.5-fpm-alpine AS base

RUN apk add --no-cache \
        bash curl git unzip zip \
        libzip-dev oniguruma-dev postgresql-dev \
        autoconf g++ make \
    && docker-php-ext-install bcmath mbstring pdo_pgsql zip pcntl \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && apk del autoconf g++ make

WORKDIR /var/www/html

# ── local ──────────────────────────────────────────────────────────────────────
FROM base AS local

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

COPY docker/entrypoint.local.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8000
ENTRYPOINT ["/entrypoint.sh"]
CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=8000"]

# ── runner (production) ────────────────────────────────────────────────────────
FROM base AS runner

RUN apk add --no-cache nginx supervisor

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

COPY composer.json composer.lock ./
RUN composer install --no-dev --no-scripts --no-autoloader --prefer-dist --no-interaction

COPY . .
RUN composer dump-autoload --optimize --no-dev

COPY docker/nginx.conf       /etc/nginx/http.d/default.conf
COPY docker/supervisord.conf /etc/supervisord.conf
COPY docker/entrypoint.sh    /entrypoint.sh
RUN chmod +x /entrypoint.sh \
    && chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

EXPOSE 80
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisord.conf"]
