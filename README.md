# docker-php-app
Docker image built from official PHP image with v8js, blitz, composer, nodejs, npm, libsodium, xdiff, xdebug and other extensions

Image is specific and in development, but Dockerfile may be helpful for build v8, v8js, blitz and other.

Full build time is about 45 minutes because Debian has no actual version of v8 library (libv8) and building from source takes time.

### Description:

**Extensions:** v8js, blitz, libsodium, xdiff, xdebug, gd,
 pdo_pgsql, pgsql, intl, gettext, sockets, zip, pdo_mysql, mysqli,  mongodb, redis, memcached.

**Tools:** composer, nodejs, npm. 

**Packages:** imagemagick, git, nano, mc


#### Environment variables:

    - APP_LABEL:  text label for app, now used for xdebug(phpstorm:// helper)
    - CURRENT_ENV: Current Environment
    - XDEBUG_ENABLE: xdebug will enabled
    - DISPLAY_ERRORS: php errors will be displayed
    - CUSTOM_INI_STRING: This variable will be added to php.ini
    - TIMEZONE: Setting up Timezone
    - PHP_FPM_MAX_CHILDREN: Variable for php-fpm
    - PHP_FPM_ALLOWED_CLIENTS: IP of nginx, for example
    - PHP_FPM_ALLOWED_CLIENTS_HOST: Hostname, which resolved to PHP_FPM_ALLOWED_CLIENTS
    - PHP_FPM_START_SERVERS: Variable for php-fpm
    - PHP_FPM_MIN_SPARE_SERVERS: Variable for php-fpm
    - PHP_FPM_MAX_SPARE_SERVERS: Variable for php-fpm
    - XDEBUG_REMOTE_HOST: Your IDE Debug IP
    - XDEBUG_REMOTE_PORT: Your IDE Debug Port
    - XDEBUG_REMOTE_AUTOSTART: Xdebug variable
    
#### Logs
By default logs will save in */var/log/php* inside conteiner. 
Disable it for production or redirect logs to *stdout&stderr*.
    
#### Mount points  
    - [host dir]:[conteiner dir]
    - /directory/for/app/tmp/php:/tmp
    - /directory/for/app/logs/php:/var/log/php
    - /app/directory/:/app
    
#### Scripts:
    /docker-entry.sh - Entrypoint for conteiner
    /docker-cmd.sh - Default command for conteiner which starts php-fpm
    /php-reload.sh - Reload php-fpm config by sending to it signal USR2
    /app-build.sh - The script just exec script localed in /app/scripts/build.sh
