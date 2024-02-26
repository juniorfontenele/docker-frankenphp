FROM dunglas/frankenphp:latest-php8.3-bookworm

LABEL maintainer="Junior Fontenele <dockerfile+frankenphp@juniorfontenele.com.br>"
LABEL version="1.0.0"
LABEL description="Laravel App Server"

ENV WWWGROUP=${WWWGROUP:-33}
ARG WWWGROUP

# Install dependencies
RUN set -xe && \
    apt-get update && apt-get install -y \
    build-essential \
    default-mysql-client \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    locales \
    zip \
    libzip-dev zlib1g-dev \
    jpegoptim optipng pngquant gifsicle \
    libwebp-dev \
    libonig-dev \
    vim \
    nano \
    unzip \
    git \
    curl \
    supervisor \
    wget \
    cron \
    procps \
    htop \
    gosu \
    libicu-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-configure \
    gd --with-webp
    
RUN docker-php-ext-install \
    pdo_mysql mbstring zip exif \
    pcntl gd sockets intl \
    && pecl install -o -f redis \
    && rm -rf /tmp/pear \
    && docker-php-ext-enable redis

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Create sail user
RUN groupadd --force -g $WWWGROUP sail
RUN useradd -ms /bin/bash --no-user-group -g $WWWGROUP -u 1337 sail
RUN setcap CAP_NET_BIND_SERVICE=+eip /usr/local/bin/frankenphp
RUN	chown -R sail:${WWWGROUP} /data/caddy && chown -R sail:${WWWGROUP} /config/caddy

ENV LOG_LEVEL=${LOG_LEVEL:-debug}
ARG LOG_LEVEL=${LOG_LEVEL}

# Replace Caddyfile
COPY ./Caddyfile /etc/caddy/Caddyfile

# Copy files
RUN mkdir -p /etc/supervisor/conf.d /var/log/supervisor
RUN mkdir -p /etc/cron.d
RUN mkdir -p /docker-entrypoint.d
COPY ./supervisord.conf /etc/supervisor/supervisord.conf
COPY ./index.php /app/public/index.php
COPY ./entrypoint.sh /
RUN chmod +x /entrypoint.sh

# Enable PHP Production settings
COPY ./php.ini-production "$PHP_INI_DIR/php.ini"

# Clean up
RUN apt-get remove build-essential -y && apt-get autoremove -y

CMD ["/entrypoint.sh"]