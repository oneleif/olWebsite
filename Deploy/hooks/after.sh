#!/bin/bash

CONTAINER_NAME=oneleif-api-$DEPLOYMENT_GROUP_NAME
IMAGE_FILE=$(find .. -name "oneleif-api.*.tar.gz" | head -n 1)

case $DEPLOYMENT_GROUP_NAME in
  "production")
    PORT=80
    ;;
  "staging")
    PORT=8080
    ;;
  *)
    PORT=8888
    ;;
esac

echo "Deploying oneleif-api ($DEPLOYMENT_GROUP_NAME) on port $PORT..."

# clean up
docker stop $CONTAINER_NAME || true
docker rm $CONTAINER_NAME || true

# load revision image
docker load -i $IMAGE_FILE

# start new version
docker run --restart=on-failure:10 --name $CONTAINER_NAME -p $PORT:80 -d oneleif-api
