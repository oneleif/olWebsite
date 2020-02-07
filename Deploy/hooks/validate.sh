#!/bin/bash

case $DEPLOYMENT_GROUP_NAME in
  "production")
    PORT=80
    ;;
  "staging")
    PORT=8080
    ;;
esac

# wait for application start on $PORT
while ! nc -q 1 localhost $PORT </dev/null; do sleep 10; done

HEALTH_CHECK_URL=localhost:$PORT/docs/index.html

STATUS_CODE=$(curl --write-out %{http_code} --silent --output /dev/null $HEALTH_CHECK_URL)

if [[ "$STATUS_CODE" -ne 200 ]] ; then
  echo "Status code is not 200 ($STATUS_CODE), failed deployment"
  exit 1
else
  exit 0
fi
