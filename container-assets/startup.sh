#!/usr/bin/env bash
set -ex

DRUSH='php -d memory_limit=-1 /usr/bin/drush'
composer require drupal/restui -o --working-dir=/app/code --no-interaction

FILE="/app/code/web/sites/default/private/salt.txt"

if [ ! -f "$FILE" ]; then
  if [ ! -z "$AUTO_INSTALL_PORTAL" ]; then
    sleep 10 #Sleep for 10 seconds to give the mariadb docker container time to startup
    $DRUSH si apigee_devportal_kickstart --site-name="Apigee Developer Portal" \
      --account-name="$ADMIN_USER" --account-mail="$ADMIN_EMAIL" \
      --account-pass="$ADMIN_PASS" --site-mail="noreply@apigee.com" \
      --no-interaction
    $DRUSH en rest restui basic_auth
    $DRUSH config:set key.key.apigee_edge_connection_default key_provider apigee_edge_environment_variables --no-interaction
    find /app/code/web/sites/default/files -type d -exec chmod ug=rwx,o= '{}' \;
    find /app/code/web/sites/default/private -type d -exec chmod ug=rwx,o= '{}' \;
    find /app/config -type d -exec chmod ug=rwx,o= '{}' \;
    $DRUSH cim --partial --source=/app/default-config
    chown -R www-data:www-data /app
    $DRUSH apigee-edge:sync --no-interaction
  fi
fi

chown -R www-data:www-data /app
$DRUSH updb -y
$DRUSH cr

supervisord --nodaemon
