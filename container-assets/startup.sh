#!/usr/bin/env bash
set -ex

DRUSH='php -d memory_limit=-1 /usr/bin/drush'
composer require drupal/restui -o --working-dir=/var/www/devportal/code --no-interaction

FILE=/var/www/devportal/code/web/sites/default/private/site-installed

if [ ! -f "$FILE" ]; then
  sleep 10; #Sleep for 10 seconds to give the mariadb docker container time to startup
  $DRUSH si apigee_devportal_kickstart --site-name="Apigee Developer Portal" --account-name="$ADMIN_USER" --account-mail="$ADMIN_EMAIL" --account-pass="$ADMIN_PASS" --site-mail="noreply@apigee.com"--no-interaction
  $DRUSH en rest restui basic_auth
  $DRUSH config:set key.key.apigee_edge_connection_default key_provider apigee_edge_environment_variables --no-interaction
  find /var/www/devportal/code/web/sites/default/files -type d  -exec chmod ug=rwx,o= '{}' \;
  find /var/www/devportal/code/web/sites/default/private -type d  -exec chmod ug=rwx,o= '{}' \;
  find /var/www/devportal/config -type d  -exec chmod ug=rwx,o= '{}' \;
  $DRUSH cim --partial --source=/var/www/devportal/config
  chown -R www-data:www-data /var/www/devportal
  $DRUSH apigee-edge:sync --no-interaction
  touch $FILE
else
  chown -R www-data:www-data /var/www/devportal
  $DRUSH updb -y
fi

$DRUSH cr

supervisord --nodaemon