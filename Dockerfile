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

ARG ADMIN_USER
ARG ADMIN_PASS

# install dependencies
RUN apt-get update
RUN apt-get install -y curl git ranger libpng-dev unzip vim sqlite3
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

# install drush
WORKDIR /var/www/portal
RUN composer require drush/drush
RUN yes | ./vendor/drush/drush/drush init

# install dependencies
RUN composer require drupal/swagger_ui_formatter drupal/apigee_m10n drupal/restui

# configure apache
RUN sed -i 's/DocumentRoot .*/DocumentRoot \/var\/www\/portal\/web/' /etc/apache2/sites-available/000-default.conf
RUN mkdir -p /var/www/portal/web/sites/default/files

# get swagger ui dependency
WORKDIR /var/www/portal/web
RUN mkdir -p libraries && curl -sSL https://github.com/swagger-api/swagger-ui/archive/v3.19.4.tar.gz -o swagger.tar.gz && tar -xvzf swagger.tar.gz && rm swagger.tar.gz  && mv swagger-ui-3.19.4 libraries/swagger_ui

# perform site install
RUN ../vendor/drush/drush/drush si apigee_devportal_kickstart --db-url=sqlite://sites/default/files/.ht.sqlite --site-name="Apigee Developer Portal" --account-name="$ADMIN_USER" --account-pass="$ADMIN_PASS" --no-interaction

# enable dependencies
RUN ../vendor/drush/drush/drush en rest restui basic_auth

# configure apigee connection credentials from environment variables
RUN ../vendor/drush/drush/drush config:set key.key.apigee_edge_connection_default key_provider apigee_edge_environment_variables --no-interaction

# import configuration files for rest module
ADD ./config ./config
RUN ../vendor/drush/drush/drush cim --partial --source=$(pwd)/config

# set permissions
WORKDIR /var/www/portal
ADD ./set-permissions.sh ./set-permissions.sh
RUN chmod +x ./set-permissions.sh && ./set-permissions.sh --drupal_path=$(pwd)/web --drupal_user=root --httpd_group=www-data
