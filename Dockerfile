# Use an official PHP image with Nginx support
FROM php:7.4-fpm

# Install system dependencies
RUN apt-get update && apt-get install -y \
    nginx \
    curl \
    unzip \
    zip \
    git \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libzip-dev \
    mariadb-client \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install \
    pdo_mysql \
    mysqli \
    zip \
    gd \
    exif \
    pcntl \
    bcmath \
    opcache

# Install Composer globally
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && composer self-update

# Set working directory
WORKDIR /var/www/html

# Copy existing WordPress project
COPY . /var/www/html/

# Ensure Composer plugins are allowed before running install
RUN composer config --global --no-interaction allow-plugins.composer/installers true \
    && composer config --global --no-interaction allow-plugins.johnpbloch/wordpress-core-installer true

# Install Composer dependencies if composer.json exists
RUN if [ -f "/var/www/html/composer.json" ]; then composer install --no-dev --optimize-autoloader --no-scripts; fi

# (Optional) Install WordPress coding standards
RUN composer global require justcoded/wpcs --no-progress --no-suggest || true

# Configure PHP settings for performance
RUN echo "upload_max_filesize = 128M" > /usr/local/etc/php/conf.d/uploads.ini \
    && echo "post_max_size = 128M" >> /usr/local/etc/php/conf.d/uploads.ini \
    && echo "memory_limit = 512M" >> /usr/local/etc/php/conf.d/uploads.ini \
    && echo "max_execution_time = 300" >> /usr/local/etc/php/conf.d/uploads.ini

# Copy Nginx configuration
COPY wnginx.conf /etc/nginx/conf.d/default.conf

# Set permissions for WordPress files
RUN chown -R www-data:www-data /var/www/html/wp-content \
    && chmod -R 755 /var/www/html/wp-content

# Create startup script to run both Nginx & PHP-FPM
RUN echo '#!/bin/bash\nnginx -g "daemon off;" & php-fpm -F' > /start.sh \
    && chmod +x /start.sh

# Expose HTTP port
EXPOSE 80
EXPOSE 9000

# Start Nginx and PHP-FPM
CMD ["/bin/bash", "/start.sh"]


