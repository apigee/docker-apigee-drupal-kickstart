#!/bin/bash
VERSION=${1:-1.27.4}
wget https://gist.githubusercontent.com/giteshw/35875a36decd24c61a9d0fb5c6afad42/raw/f3ef0a6edbf345acb5702d7de0e0f9a4226dedfc/docker-compose.yaml
docker run --rm \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v "$PWD:$PWD" \
    -w="$PWD" \
    docker/compose:${VERSION}  docker-compose up
