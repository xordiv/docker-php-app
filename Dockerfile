FROM php:fpm
MAINTAINER Pavel Laulin <tonebbs@gmail.com>

ENV DEBIAN_FRONTEND noninteractive

# Working sources
COPY files/sources.list /etc/apt/sources.list

# Prepare and locale
RUN apt-get update
RUN apt-get install -y --no-install-recommends \
		binutils mc nano \
        locales curl \
        autoconf automake autotools-dev g++ \
        git bzip2

RUN locale-gen en_US.UTF-8 &&\
    dpkg-reconfigure locales && \
    /usr/sbin/update-locale LANG=C.UTF-8

# Install base extensions
RUN apt-get install -y --no-install-recommends \
        libfreetype6 libfreetype6-dev \
        libjpeg62-turbo libjpeg62-turbo-dev \
        libmcrypt4 libmcrypt-dev \
        libpng12-dev \
        libssl-dev \
        imagemagick \
        libicu-dev \
    && docker-php-ext-install -j$(nproc) iconv mcrypt \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install mbstring mysqli pdo_mysql zip sockets opcache gettext intl \
    && docker-php-ext-enable mbstring mysqli pdo_mysql zip sockets opcache gettext intl \
    && pecl install xdebug \
    && apt-get clean \
    && apt-get purge -y --auto-remove \
       libfreetype6-dev \
       libjpeg62-turbo-dev \
       libmcrypt-dev


# Postgres, mongodb
RUN apt-get install -y --no-install-recommends libpq-dev &&\
    docker-php-ext-install pdo_pgsql && \
    docker-php-ext-enable pdo_pgsql  && \
    docker-php-ext-install pgsql && \
    docker-php-ext-enable pgsql && \
    pecl install mongodb && \
    docker-php-ext-enable mongodb && \
    apt-get clean

# Memcached, redis
RUN apt-get install -y libmemcached-dev \
    && curl -L -o /tmp/memcached.tar.gz "https://github.com/php-memcached-dev/php-memcached/archive/php7.tar.gz" \
    && mkdir -p /usr/src/php/ext/memcached \
    && tar -C /usr/src/php/ext/memcached -zxvf /tmp/memcached.tar.gz --strip 1 \
    && docker-php-ext-configure memcached \
    && docker-php-ext-install memcached \
    && rm /tmp/memcached.tar.gz \
    && docker-php-ext-enable memcached \
    && pecl install redis && docker-php-ext-enable redis \
    && apt-get clean

# Blitz
RUN cd /tmp ; \
    curl "https://codeload.github.com/alexeyrybak/blitz/tar.gz/0.10.2-PHP7" -o /tmp/blitz.tar.gz &&\
    tar -xzf blitz.tar.gz && \
    cd blitz-0.10.2-PHP7 &&\
    phpize &&\
    ./configure --with-max-lexem=2048 &&\
    make &&\
    make install && make clean &&\
    cd / &&\
    rm -rf /tmp/blitz-0.10.2-PHP7 &&\
    rm -rf /tmp/blitz.tar.gz &&\
    docker-php-ext-enable blitz

# Install Composer
RUN curl -s http://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/composer

# Install nodejs
RUN curl -sL https://deb.nodesource.com/setup_7.x | bash - &&\
    apt-get install -y --no-install-recommends nodejs

# Libsodium
RUN apt-get install -y --no-install-recommends  libsodium-dev &&\
    \
    pecl install libsodium && docker-php-ext-enable libsodium &&\
    apt-get clean

# Xdiff install
RUN curl -L -o /tmp/xdiff.tar.gz "http://www.xmailserver.org/libxdiff-0.23.tar.gz" \
    && mkdir -p /usr/src/xdiff \
    && tar -C /usr/src/xdiff -zxvf /tmp/xdiff.tar.gz --strip 1 \
    && rm /tmp/xdiff.tar.gz \
    && cd /usr/src/xdiff \
    && ./configure  && make && make install \
    \
    &&  pecl install xdiff && docker-php-ext-enable xdiff



# Install V8 5.8.226
RUN apt-get install -y --no-install-recommends libicu-dev ninja-build build-essential subversion chrpath bzip2 libglib2.0-dev &&\
    cd /tmp &&\
    git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git &&\
    export PATH=`pwd`/depot_tools:"$PATH" &&\
    fetch v8 &&\
    cd v8 &&\
    git checkout 5.8.226 &&\
    gclient sync &&\
    tools/dev/v8gen.py -vv x64.release -- is_component_build=true  &&\
    ninja -C out.gn/x64.release/  &&\
    \
    mkdir -p /opt/v8/lib && mkdir -p /opt/v8/include  &&\
    cp out.gn/x64.release/lib*.so out.gn/x64.release/*_blob.bin /opt/v8/lib/  &&\
    cp -R include/* /opt/v8/include/ &&\
    rm -rf /tmp/depot_tools &&\
    rm -rf /tmp/v8 &&\
    apt-get clean &&\
    apt-get purge -y --auto-remove ninja-build build-essential subversion chrpath

# Install v8js
RUN cd /tmp && git clone https://github.com/phpv8/v8js.git &&\
    cd v8js &&\
    phpize &&\
    ./configure --with-v8js=/opt/v8 &&\
    make &&\
    make test &&\
    make install &&\
    rm -rf /tmp/v8js

# Cleaning
RUN apt-get purge -y --auto-remove make m4 gcc g++ re2c \
	python-minimal python2.7-minimal python2.7 \
	autoconf automake autotools-dev &&\
	\
    apt-get clean && rm -rf /var/lib/apt/lists/* &&\
    rm -rf /usr/local/etc/* &&\
    rm -rf /var/log/php &&\
    mkdir -p /var/log/php &&\
    chown www-data:www-data /var/log/php -R

# Tuning
COPY files/conf /usr/local/etc/

COPY /scripts/* /
#COPY docker-entry.sh /docker-entry.sh

RUN echo "export TERM=xterm" >> /etc/bash.bashrc

VOLUME /app
WORKDIR /app

EXPOSE 9000

ENTRYPOINT ["/docker-entry.sh"]
CMD ["/docker-cmd.sh"]
