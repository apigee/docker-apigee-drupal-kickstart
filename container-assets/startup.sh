#!/usr/bin/env bash
set -ex

DRUSH='php -d memory_limit=-1 /usr/bin/drush'
composer require drupal/restui -o --working-dir=/app/code --no-interaction

FILE="/app/code/web/sites/default/private/salt.txt"

if [ ! -f "$FILE" ]; then
  sleep 20; #Sleep for 20 seconds to give the mariadb docker container time to startup
  if [ ! -z "$AUTO_INSTALL_PORTAL" ]; then
    $DRUSH si apigee_devportal_kickstart --site-name="Apigee Developer Portal" \
      --account-name="$ADMIN_USER" --account-mail="$ADMIN_EMAIL" \
      --account-pass="$ADMIN_PASS" --site-mail="noreply@apigee.com" \
      --no-interaction
    $DRUSH en rest restui basic_auth
    $DRUSH config:set key.key.apigee_edge_connection_default key_provider apigee_edge_environment_variables --no-interaction
    $DRUSH cim --partial --source=/app/default-config
    $DRUSH apigee-edge:sync --no-interaction
  fi
  /set-permissions.sh --drupal_path=/app/code/web --drupal_user=www-data --httpd_group=www-data
fi

$DRUSH updb -y || true
$DRUSH cr || true

supervisord --nodaemon
