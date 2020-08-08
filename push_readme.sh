#!/usr/bin/env bash

# Push the README.md file to the docker hub repository

# Requires the following environment variables to be set:
# DOCKER_PASSWORD, DOCKER_USERNAME, IMAGE_NAME

set -o nounset
set -o errexit
set -o pipefail

echo "Logging in and requesting JWT..."
token=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  -d '{"username": "'"$DOCKER_USERNAME"'", "password": "'"$DOCKER_PASSWORD"'"}' \
  https://hub.docker.com/v2/users/login/ | jq -r .token)

echo "Pushing README file..."
code=$(jq -n --arg msg "$(<README.md)" \
  '{"registry":"registry-1.docker.io","full_description": $msg }' | \
      curl -s -o /dev/null -L -w "%{http_code}" \
         https://hub.docker.com/v2/repositories/"${IMAGE_NAME}"/ \
         -d @- -X PATCH \
         -H "Content-Type: application/json" \
         -H "Authorization: JWT ${token}")

if [[ "${code}" = "200" ]]; then
  printf "Successfully pushed README to Docker Hub"
else
  printf "Unable to push README to Docker Hub, response code: %s\n" "${code}"
  exit 1
fi
