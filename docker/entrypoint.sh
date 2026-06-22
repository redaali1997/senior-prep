#!/bin/sh

set -e

echo "🔧 Preparing Laravel application..."

if [ "$APP_ENV" = "local" ]; then
    echo "📦 [dev] Regenerating autoloader..."
    composer dump-autoload -o
else
    echo "⚡ [prod] Caching config & routes..."
    php artisan optimize
fi

# php artisan migrate --force

echo "✅ Ready. Starting..."

exec "$@"