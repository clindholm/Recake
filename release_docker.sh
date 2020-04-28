#!/bin/bash
set -e

mkdir -p tmp/

docker build -f Dockerfile.releaser -t bygg_app:releaser .

DOCKER_UUID=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

docker run -ti --name bygg_app_releaser_${DOCKER_UUID} bygg_app:releaser /bin/true
docker cp bygg_app_releaser_${DOCKER_UUID}:/app/priv/static/js/app.js tmp/
docker rm bygg_app_releaser_${DOCKER_UUID}