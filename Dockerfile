# Copyright 2019 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FROM composer:2 as composer

FROM php:7.4-fpm
ENV DRUPAL_DATABASE_NAME=devportal \
    DRUPAL_DATABASE_USER=dbuser \
    DRUPAL_DATABASE_PASSWORD=dbpass \
    DRUPAL_DATABASE_HOST=localhost \
    DRUPAL_DATABASE_PORT=3306 \
    DRUPAL_DATABASE_DRIVER=mysql \
    ADMIN_USER=admin \
    ADMIN_PASS=admin

RUN apt-get update && apt-get install -y \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        libxml2-dev \
        git zip unzip default-mysql-client\
        curl \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd bcmath opcache xmlrpc pdo_mysql

RUN cp /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini \
    && sed -i 's/\(^max_execution_time = 30$\)/max_execution_time = 300/g' /usr/local/etc/php/php.ini \
    && echo "php_admin_value[memory_limit] = 512M" >> /usr/local/etc/php-fpm.d/www.conf \
    && sed -i 's/\(^;request_terminate_timeout = 0$\)/request_terminate_timeout = 300/g' /usr/local/etc/php-fpm.d/www.conf

COPY --from=composer /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/devportal/code/web

RUN curl https://raw.githubusercontent.com/apigee/devportal-kickstart-project-composer/9.x/composer.json -o /var/www/devportal/code/composer.json \
    && curl https://raw.githubusercontent.com/apigee/devportal-kickstart-project-composer/9.x/LICENSE.txt -o /var/www/devportal/code/LICENSE.txt

#OVERRIDE custom code folder if any
COPY code /var/www/devportal/code

RUN php -d memory_limit=-1 /usr/bin/composer install -o --working-dir=/var/www/devportal/code --no-interaction \
    && php -d memory_limit=-1 /usr/bin/composer require drush/drush -o --working-dir=/var/www/devportal/code --no-interaction \
    && ln -sf /var/www/devportal/code/vendor/bin/drush /usr/bin/drush


RUN mkdir -p /var/www/devportal/code/web/sites/default/files \
    && mkdir -p /var/www/devportal/code/web/sites/default/private \
    && mkdir -p /var/www/devportal/tmp \
    && mkdir -p /var/www/devportal/config \
    && chown -R www-data:www-data /var/www/devportal

COPY container-assets/settings.php /var/www/devportal/code/web/sites/default/settings.php

RUN apt-get install -y nginx \
    && unlink /etc/nginx/sites-enabled/default

COPY container-assets/drupal-nginx.conf /etc/nginx/sites-enabled/drupal-nginx.conf

EXPOSE 80

RUN apt-get install -y supervisor
COPY container-assets/supervisor.conf /etc/supervisor/conf.d/drupal-supervisor.conf
COPY container-assets/startup.sh /startup.sh
RUN chmod +x /startup.sh

CMD ["/startup.sh"]