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
    $DRUSH cim --partial --source=/app/default-config
    $DRUSH apigee-edge:sync --no-interaction
    /set-permissions.sh --drupal_path=/app/code/web --drupal_user=www-data --httpd_group=www-data
  fi
fi

$DRUSH updb -y
$DRUSH cr

supervisord --nodaemon
