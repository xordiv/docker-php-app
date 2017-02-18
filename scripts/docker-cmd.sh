#!/bin/sh

set -e

[ -f "/app/scripts/on-start.sh" ] && [ -x "/app/scripts/on-start.sh" ] && /app/scripts/on-start.sh

php-fpm -c /usr/local/etc/php/php.fpm.ini -R "$@"