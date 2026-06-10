
FROM php:8.4-fpm AS base

RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libzip-dev \
    libpng-dev \
    && docker-php-ext-install pdo_mysql zip gd \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && rm -rf /var/lib/apt/lists/*

COPY ./docker/entrypoint.sh /usr/local/bin/entrypoint
RUN chmod +x /usr/local/bin/entrypoint

ENTRYPOINT ["entrypoint"]

# Builder Stage
FROM base AS builder

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs

WORKDIR /var/www

COPY composer.json composer.lock ./

RUN composer install --no-scripts --no-autoloader --no-dev --optimize-autoloader

COPY . .

RUN composer dump-autoload --optimize

RUN npm ci && npm run build && rm -rf node_modules

CMD ["php-fpm"]

# Production Stage
FROM base AS production

WORKDIR /var/www

COPY --from=builder /var/www /var/www/

RUN chown -R www-data:www-data storage bootstrap/cache

USER www-data

EXPOSE 9000
CMD ["php-fpm"]

# Nginx Stage
FROM nginx:1.27-alpine AS nginx

COPY docker/nginx.conf /etc/nginx/conf.d/default.conf

COPY --from=production /var/www/public /var/www/public