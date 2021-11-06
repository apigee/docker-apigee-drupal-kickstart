#!/usr/bin/env bash
# Copyright 2021 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -ex

DRUSH='php -d memory_limit=-1 /usr/bin/drush'
composer require drupal/restui -o --working-dir=/app/code --no-interaction

FILE="/app/code/web/sites/default/private/salt.txt"

if [ ! -f "$FILE" ]; then
  if [ "$AUTO_INSTALL_PORTAL" == "true" ]; then
    $DRUSH si apigee_devportal_kickstart --site-name="Apigee Developer Portal" \
      --account-name="$ADMIN_USER" --account-mail="$ADMIN_EMAIL" \
      --account-pass="$ADMIN_PASS" --site-mail="noreply@apigee.com" \
      --no-interaction
    $DRUSH en rest restui basic_auth
    $DRUSH config:set key.key.apigee_edge_connection_default key_provider apigee_edge_environment_variables --no-interaction
    $DRUSH cim --partial --source=/app/default-config
    $DRUSH apigee-edge:sync --no-interaction
    /set-permissions.sh --drupal_path=/app/code/web --drupal_user=www-data --httpd_group=www-data
  fi
else
  $DRUSH updb -y || true
fi

$DRUSH cr || true

supervisord --nodaemon -c /etc/supervisor/conf.d/drupal-supervisor.conf
