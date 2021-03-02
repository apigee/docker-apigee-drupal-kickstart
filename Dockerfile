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

FROM drupal:8-apache

# install dependencies
RUN apt-get update
RUN apt-get update && apt-get install -y curl \
  git ranger unzip vim sqlite3 libmagick++-dev \
  libmagickwand-dev libpq-dev libfreetype6-dev \
  libjpeg62-turbo-dev libpng-dev libwebp-dev libxpm-dev
RUN docker-php-ext-configure gd --with-jpeg=/usr/include/ \
  --with-freetype=/usr/include/
RUN docker-php-ext-install gd bcmath

# install and setup drupal tools
RUN echo "memory_limit = -1;" > /usr/local/etc/php/php.ini
WORKDIR /var/www
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
RUN php composer-setup.php
RUN rm composer-setup.php
RUN mv composer.phar /usr/bin/composer

# create project
RUN composer create-project apigee/devportal-kickstart-project:8.x-dev portal --stability dev --no-interaction

# install dependencies
WORKDIR /var/www/portal
RUN composer require drupal/apigee_m10n drupal/restui drush/drush:8.*
RUN yes | ./vendor/drush/drush/drush init

# configure apache
RUN sed -i 's/DocumentRoot .*/DocumentRoot \/var\/www\/portal\/web/' /etc/apache2/sites-available/000-default.conf
RUN mkdir -p /var/www/portal/web/sites/default/files

# import configuration files for rest module
ADD ./config /var/www/portal/web/config

# set up private filesystem
RUN mkdir -p /var/www/private
RUN usermod -aG root www-data
RUN chmod g+r,g+w /var/www/private
RUN echo "\$settings['file_private_path'] = '/var/www/private';" >> /var/www/portal/web/sites/default/settings.php

# set permissions
WORKDIR /var/www/portal
ADD ./set-permissions.sh ./set-permissions.sh
RUN chmod +x ./set-permissions.sh && ./set-permissions.sh --drupal_path=/var/www/portal/web --drupal_user=root --httpd_group=www-data
ADD ./drupal-install.sh ./drupal-install.sh
RUN chmod +x ./drupal-install.sh

ENV ADMIN_USER=admin@example.com
ENV ADMIN_PASS=pass
ENV DB_URL=sqlite://sites/default/files/.ht.sqlite

ENTRYPOINT ./drupal-install.sh && apache2-foreground
