<?php

$databases['default']['default'] = [
    'database' => getenv('DRUPAL_DATABASE_NAME'),
    'username' => getenv('DRUPAL_DATABASE_USER'),
    'password' => getenv('DRUPAL_DATABASE_PASSWORD'),
    'host' => getenv('DRUPAL_DATABASE_HOST'),
    'port' => getenv('DRUPAL_DATABASE_PORT'),
    'driver' => getenv('DRUPAL_DATABASE_DRIVER'),
];

$settings['update_free_access'] = FALSE;
$settings['allow_authorize_operations'] = FALSE;
$settings['file_public_path'] = 'sites/default/files';
$settings['file_private_path'] = '/app/code/web/sites/default/private';
$settings['config_sync_directory'] = $settings['file_private_path'] . "/config";
$settings['file_temp_path'] = '/tmp';


$salt_file = $settings['file_private_path'] . "/salt.txt";
if (!file_exists($salt_file)) {
    file_put_contents($salt_file, \Drupal\Component\Utility\Crypt::randomBytesBase64(55));
}
$settings['hash_salt'] = file_get_contents($salt_file);