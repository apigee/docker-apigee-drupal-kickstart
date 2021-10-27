#!/bin/bash

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

docker volume rm public-files || true
docker volume rm private-files || true

docker volume create public-files
docker volume create private-files

docker rm -f apigee-devportal-db || true

docker run --name apigee-devportal-db -p 53306:3306 -d \
    -e MYSQL_DATABASE=apigee_devportal \
    -e MYSQL_USER=dbuser \
    -e MYSQL_PASSWORD=passw0rd \
    -e MYSQL_ROOT_PASSWORD=rootpasswd \
	mariadb:latest

docker rm -f apigee-devportal || true

docker run --name apigee-devportal -p 8080:80 --env-file=./apigee.env \
    -e DRUPAL_DATABASE_NAME=apigee_devportal \
    -e DRUPAL_DATABASE_USER=dbuser \
    -e DRUPAL_DATABASE_PASSWORD=passw0rd \
    -e DRUPAL_DATABASE_HOST=host.docker.internal \
    -e DRUPAL_DATABASE_PORT=53306 \
    -e DRUPAL_DATABASE_DRIVER=mysql \
    -e AUTO_INSTALL_PORTAL=true \
    -v public-files:/app/code/web/sites/default/files \
    -v private-files:/app/code/web/sites/default/private \
	ghcr.io/apigee/docker-apigee-drupal-kickstart:latest