#!/bin/sh

set -e

echo 'Building...'

[ -f "/app/scripts/build.sh" ] && [ -x "/app/scripts/build.sh" ] && /app/scripts/build.sh