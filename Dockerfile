FROM php:8.0.5-apache

RUN apt-get update && apt-get install -y \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        git \
        zip \
        unzip \
        libzip-dev \
        autoconf \
        supervisor \
    && docker-php-ext-configure pdo_mysql --with-pdo-mysql=mysqlnd \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd \
    pdo_mysql \
    zip \
    gd \
    opcache \
    sockets

# Set working directory
WORKDIR /var/www/html

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Update Php Settings
RUN sed -E -i -e 's/post_max_size = 8M/post_max_size = 20M/' /usr/local/etc/php/php.ini-production \
 && sed -E -i -e 's/upload_max_filesize = 2M/upload_max_filesize = 20M/' /usr/local/etc/php/php.ini-production

RUN cp /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini

# Add user for laravel application
RUN usermod -u 1000 www-data && groupmod -g 1000 www-data
RUN a2enmod rewrite

#change the web_root to lumen /var/www/html/public folder
RUN sed -i -e "s/html/html\/public/g" /etc/apache2/sites-enabled/000-default.conf

# Copy existing application directory contents
COPY . /var/www/html

# Copy existing application directory permissions
COPY --chown=www-data:www-data . /var/www/html

COPY ./docker/docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh && ln -s /usr/local/bin/docker-entrypoint.sh /

#apply cronjob
#RUN chmod +x /var/www/html/docker/worker-queue.sh /
#RUN touch /var/log/cron.log
#RUN (crontab -l ; echo "*/1 * * * * /var/www/html/docker/worker-queue.sh") | crontab

# Run worker with supervisor
RUN mkdir -p /var/log/supervisor && chown www-data:www-data /var/log/supervisor
COPY docker/supervisord.d /etc/supervisor/conf.d/supervisord.d
COPY docker/supervisord.conf /etc/supervisord.conf

# Set current user
#USER www-data

# Composer install
RUN php composer.phar install --no-dev

EXPOSE 80
ENTRYPOINT ["docker-entrypoint.sh"]