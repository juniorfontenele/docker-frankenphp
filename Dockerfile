FROM dunglas/frankenphp:php8.4-bookworm

LABEL maintainer="Junior Fontenele <dockerfile+frankenphp@juniorfontenele.com.br>"
LABEL version="2.0.0"
LABEL description="Laravel App Server"

ENV LOG_LEVEL=${LOG_LEVEL:-debug}
ARG LOG_LEVEL=${LOG_LEVEL}

ENV LARAVEL_PATH=/app
ENV SERVER_NAME=${SERVER_NAME:-:80}
ENV WWWUSER=${WWWUSER:-sail}
ENV WWWGROUP=${WWWGROUP:-sail}
ENV WWWUSER_ID=${WWWUSER_ID:-1337}
ENV WWWGROUP_ID=${WWWGROUP_ID:-1337}

# Install dependencies
RUN set -xe \
    && apt-get update \
    && apt-get upgrade -y \
    && curl -fsSL https://deb.nodesource.com/setup_23.x | bash - \
    && apt-get install -y \
    apt-transport-https \
    libnss3-tools \
    gnupg2 \
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
    nodejs \
    libicu-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Configure PHP extensions
RUN docker-php-ext-configure gd --with-webp \
    && docker-php-ext-install \
    pdo_mysql mbstring zip exif \
    pcntl gd sockets intl \
    && pecl install -o -f redis \
    && rm -rf /tmp/pear \
    && docker-php-ext-enable redis

# Install composer    
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Create directories
RUN mkdir -p /etc/supervisor/conf.d /var/log/supervisor /var/log/caddy /etc/cron.d /docker-entrypoint.d

# Create user sail
RUN groupadd -g 1337 sail \
    && useradd -ms /bin/bash --no-user-group -g 1337 -u 1337 sail \
    && setcap CAP_NET_BIND_SERVICE=+eip /usr/local/bin/frankenphp \
    && chown -R sail:sail /data/caddy \
    && chown -R sail:sail /config/caddy \
    && chown -R sail:sail /var/log/caddy

# Replace Caddyfile
COPY ./Caddyfile /etc/caddy/Caddyfile

# Copy files
COPY ./supervisord.conf /etc/supervisor/supervisord.conf
COPY ./index.php /app/public/index.php
COPY ./entrypoint.sh /
RUN chmod +x /entrypoint.sh

# Enable PHP Production settings
COPY ./php.ini-production "$PHP_INI_DIR/php.ini"

# Clean up
RUN apt-get autoremove -y \
    build-essential \
    gnupg2 \
    && rm -rf /etc/apt/sources.list.d/nodesource.list \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/pear

RUN chown -R sail:sail /app
RUN chown -R sail:sail /config

CMD ["/entrypoint.sh"]