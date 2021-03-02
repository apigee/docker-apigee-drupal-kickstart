#!/bin/bash

# Copyright 2021 Google LLC
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

if [ -f "/var/www/portal/web/sites/default/files/settings.php" ]; then
    cp -p /var/www/portal/web/sites/default/files/settings.php /var/www/portal/web/sites/default/settings.php
else
    # init portal
    /var/www/portal/vendor/drush/drush/drush si apigee_devportal_kickstart --db-url=$DB_URL --site-name="Apigee Developer Portal" --account-name="$ADMIN_USER" --account-pass="$ADMIN_PASS" --no-interaction

    # enable dependencies
    yes | /var/www/portal/vendor/drush/drush/drush en rest restui basic_auth

    # configure apigee connection credentials from environment variables
    /var/www/portal/vendor/drush/drush/drush config:set key.key.apigee_edge_connection_default key_provider apigee_edge_environment_variables --no-interaction

    # setup REST module
    yes | /var/www/portal/vendor/drush/drush/drush cim --partial --source=/var/www/portal/web/config

    # store settings for container start with same volume
    cp /var/www/portal/web/sites/default/settings.php /var/www/portal/web/sites/default/files/settings.php

    /var/www/portal/set-permissions.sh --drupal_path=/var/www/portal/web --drupal_user=root --httpd_group=www-data
fi
