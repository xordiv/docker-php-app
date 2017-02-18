#!/bin/bash
set -e

#php logs
mkdir -p /var/log/php
chown www-data:www-data /var/log/php -R

# XDEBUG
if [ ! -z "$XDEBUG_ENABLE" ] 
then
  docker-php-ext-enable xdebug 

  [ ! -z "$XDEBUG_REMOTE_HOST" ] && [ -e /usr/local/etc/php/conf.d/xdebug.ini ] && sed -i "/^xdebug.remote_host=/cxdebug.remote_host=$XDEBUG_REMOTE_HOST" /usr/local/etc/php/conf.d/xdebug.ini
  
  [ ! -z "$XDEBUG_REMOTE_PORT" ] && [ -e /usr/local/etc/php/conf.d/xdebug.ini ] && sed -i "/^xdebug.remote_port=/cxdebug.remote_port=$XDEBUG_REMOTE_PORT" /usr/local/etc/php/conf.d/xdebug.ini

  [ ! -z "$XDEBUG_REMOTE_AUTOSTART" ] && [ -e /usr/local/etc/php/conf.d/xdebug.ini ] && sed -i "/^xdebug.remote_autostart=/cxdebug.remote_autostart=$XDEBUG_REMOTE_AUTOSTART" /usr/local/etc/php/conf.d/xdebug.ini
else
   [ -f "/usr/local/bin/docker-php-ext-disable" ] && /usr/local/bin/docker-php-ext-disable xdebug  
fi

# With env variable DISPLAY_ERRORS=1 display_errors will be enabled
if [ ! -z "$DISPLAY_ERRORS" ] 
then
  cp -f /usr/local/etc/conf.templates/display.errors.php.ini /usr/local/etc/php/conf.d/display.errors.php.ini
else
  [ -e /usr/local/etc/php/conf.d/display.errors.php.ini ] && unlink /usr/local/etc/php/conf.d/display.errors.php.ini
fi

if [ ! -z "$CUSTOM_INI_STRING" ]
then
  printf "$CUSTOM_INI_STRING\n" > /usr/local/etc/php/conf.d/_custom_ini_strings.php.ini
else
  [ -e /usr/local/etc/php/conf.d/_custom_ini_strings.php.ini ] && unlink /usr/local/etc/php/conf.d/_custom_ini_strings.php.ini
fi


# fpm pool tuning
[ ! -z "$PHP_FPM_MAX_CHILDREN" ] && sed -i "/^pm.max_children = /cpm.max_children = $PHP_FPM_MAX_CHILDREN" /usr/local/etc/php-fpm.d/www.conf

[ ! -z "$PHP_FPM_START_SERVERS" ] && sed -i "/^pm.start_servers = /cpm.start_servers = $PHP_FPM_START_SERVERS" /usr/local/etc/php-fpm.d/www.conf

[ ! -z "$PHP_FPM_MIN_SPARE_SERVERS" ] && sed -i "/^pm.min_spare_servers = /cpm.min_spare_servers = $PHP_FPM_MIN_SPARE_SERVERS" /usr/local/etc/php-fpm.d/www.conf

[ ! -z "$PHP_FPM_MAX_SPARE_SERVERS" ] && sed -i "/^pm.max_spare_servers = /cpm.max_spare_servers = $PHP_FPM_MAX_SPARE_SERVERS" /usr/local/etc/php-fpm.d/www.conf



# fpp clients stricts
[ ! -z "$PHP_FPM_ALLOWED_CLIENTS" ] && sed -i "/^;listen.allowed_clients = /clisten.allowed_clients = $PHP_FPM_ALLOWED_CLIENTS" /usr/local/etc/php-fpm.d/www.conf

if [[ ! -z "$PHP_FPM_ALLOWED_CLIENTS_HOST" ]]
then
  IP=`getent ahosts $PHP_FPM_ALLOWED_CLIENTS_HOST | head -n 1 |awk '{print $1}'` # only first ip
  echo $IP
  [ ! -z "$IP" ] && sed -i "/^;listen.allowed_clients = /clisten.allowed_clients = $IP" /usr/local/etc/php-fpm.d/www.conf
fi


# Timezone setup
if [[ ! -z "$TIMEZONE" ]]
then
  echo "$TIMEZONE" > /etc/timezone
  dpkg-reconfigure -f noninteractive tzdata
fi
test -d /usr/local/etc/php/conf.d && echo "date.timezone=`cat /etc/timezone`" > /usr/local/etc/php/conf.d/timezone.ini

[ -f "/app/scripts/on-entry.sh" ] && [ -x "/app/scripts/on-entry.sh" ]  && /app/scripts/on-entry.sh

exec "$@"
