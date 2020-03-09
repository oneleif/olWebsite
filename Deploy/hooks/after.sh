#!/bin/bash

CONTAINER_NAME=oneleif-api-$DEPLOYMENT_GROUP_NAME
IMAGE_FILE=$(find .. -name "oneleif-api.*.tar.gz" | head -n 1)
NETWORK_NAME=olwebsite_default
RESTART_POLICY=on-failure:10
IMAGE_NAME=oneleif-api
ENV_FILE_PATH=/home/ubuntu/oneleif-env/$DEPLOYMENT_GROUP_NAME.env

case $DEPLOYMENT_GROUP_NAME in
  "production")
    PORT=8080
    ;;
  "staging")
    PORT=8081
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
docker run \ 
  --env-file $ENV_FILE_PATH \
  --name $CONTAINER_NAME \
  --network $NETWORK_NAME \
  --publish $PORT:80 \
  --restart $RESTART_POLICY \
  --detach \
  $IMAGE_NAME
