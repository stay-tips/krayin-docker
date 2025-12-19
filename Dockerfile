# main image
FROM php:8.3-apache

# installing dependencies
RUN apt-get update && apt-get install -y \
    git \
    ffmpeg \
    libfreetype6-dev \
    libicu-dev \
    libgmp-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libwebp-dev \
    libxpm-dev \
    libzip-dev \
    unzip \
    zlib1g-dev

# configuring php extension
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp
RUN docker-php-ext-configure intl

# download mailparse source
RUN curl -L -o /tmp/mailparse.tar.gz https://pecl.php.net/get/mailparse && \
    mkdir -p /usr/src/php/ext/mailparse && \
    tar -xf /tmp/mailparse.tar.gz -C /usr/src/php/ext/mailparse --strip-components=1 && \
    rm /tmp/mailparse.tar.gz

# installing php extension
RUN docker-php-ext-install bcmath calendar exif gd gmp intl mailparse mysqli pdo pdo_mysql zip

# installing composer
COPY --from=composer:2.7 /usr/bin/composer /usr/local/bin/composer

# installing node js
COPY --from=node:22.9 /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=node:22.9 /usr/local/bin/node /usr/local/bin/node
RUN ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm

# installing global node dependencies
RUN npm install -g npx
RUN npm install -g laravel-echo-server

# arguments
ARG container_project_path
ARG uid
ARG user

# setting work directory
WORKDIR $container_project_path

# adding user
RUN useradd -G www-data,root -u $uid -d /home/$user $user
RUN mkdir -p /home/$user/.composer && \
    chown -R $user:$user /home/$user

# setting apache
COPY ./.configs/apache.conf /etc/apache2/sites-available/000-default.conf
RUN a2enmod rewrite

# setting up project from `src` folder
RUN chmod -R 775 $container_project_path
RUN chown -R $user:www-data $container_project_path

# changing user
USER $user
