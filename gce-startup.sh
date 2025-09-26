#!/bin/bash
VERSION=${1:-1.29.2}

# Download config files
wget https://raw.githubusercontent.com/apigee/docker-apigee-drupal-kickstart/main/docker-compose.yml
wget https://raw.githubusercontent.com/apigee/docker-apigee-drupal-kickstart/main/apigee.env

# Modify port for GCE environment
sed -i 's/8080:80/80:80/g' docker-compose.yml

# Run containers using the docker/compose image
docker run --rm \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v "$PWD:$PWD" \
    -w="$PWD" \
    docker/compose:${VERSION} up -d
