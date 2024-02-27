FROM dunglas/frankenphp:latest-php8.3-bookworm

LABEL maintainer="Junior Fontenele <dockerfile+frankenphp@juniorfontenele.com.br>"
LABEL version="1.0.0"
LABEL description="Laravel App Server"

ENV WWWGROUP=${WWWGROUP:-33}
ARG WWWGROUP

ENV LOG_LEVEL=${LOG_LEVEL:-debug}
ARG LOG_LEVEL=${LOG_LEVEL}

# Install dependencies
RUN set -xe \
    && apt-get update \
    && apt-get upgrade -y \
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

# Install logstash 7
RUN wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add - && \
    echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | tee -a /etc/apt/sources.list.d/elastic-7.x.list && \
    apt-get update && apt-get install -y logstash && apt-get clean && rm -rf /var/lib/apt/lists/*

# Create directories
RUN mkdir -p /etc/supervisor/conf.d /var/log/supervisor /var/log/caddy /etc/cron.d /docker-entrypoint.d

# Create user sail
RUN groupadd --force -g $WWWGROUP sail \
    && useradd -ms /bin/bash --no-user-group -g $WWWGROUP -u 1337 sail \
    && setcap CAP_NET_BIND_SERVICE=+eip /usr/local/bin/frankenphp \
    && chown -R sail:${WWWGROUP} /data/caddy \
    && chown -R sail:${WWWGROUP} /config/caddy \
    && chown -R sail:${WWWGROUP} /var/log/caddy

# Replace Caddyfile
COPY ./Caddyfile /etc/caddy/Caddyfile

# Copy files
COPY ./supervisord.conf /etc/supervisor/supervisord.conf
COPY ./index.php /app/public/index.php
COPY ./entrypoint.sh /
COPY ./caddy-stdout.conf /etc/logstash/conf.d/caddy-stdout.conf
RUN chmod +x /entrypoint.sh

# Enable PHP Production settings
COPY ./php.ini-production "$PHP_INI_DIR/php.ini"

# Clean up
RUN apt-get autoremove -y \
    build-essential \
    gnupg2 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/pear

CMD ["/entrypoint.sh"]