#!/bin/bash

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

echo $PORT
