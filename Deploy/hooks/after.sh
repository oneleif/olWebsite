#!/bin/bash

# clean up
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

docker stop $CONTAINER_NAME || true
docker rm $CONTAINER_NAME || true

docker load -i $IMAGE_FILE

docker create -p $PORT:80 --name $CONTAINER_NAME oneleif-api
docker start $CONTAINER_NAME
