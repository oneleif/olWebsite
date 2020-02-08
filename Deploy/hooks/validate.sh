#!/bin/bash

PORT=$(./port.sh)

# wait for application start on $PORT
while ! bash -c "echo >/dev/tcp/localhost/$PORT"; do sleep 1; done

HEALTH_CHECK_URL=localhost:$PORT/docs/index.html

STATUS_CODE=$(curl --write-out %{http_code} --silent --output /dev/null $HEALTH_CHECK_URL)

if [[ "$STATUS_CODE" -ne 200 ]] ; then
  echo "Status code is not 200 ($STATUS_CODE), deployment failed"
  exit 1
else
  echo "Request successful: $STATUS_CODE"
  exit 0
fi
