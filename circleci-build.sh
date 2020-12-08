#!/usr/bin/env bash

set -o pipefail
set -eu

JRUBY_VERSION="${1:?}"
CLEAR_TEXT_CIRCLECI_TOKEN="$(echo "${CIRCLECI_TOKEN:?}" | gpg --decrypt)"

curl -X POST \
  --header "Content-Type: application/json" \
  -d "{\"name\":\"JRUBY_VERSION\", \"value\":\"${JRUBY_VERSION}\"}" \
  "https://circleci.com/api/v1.1/project/github/heroku/docker-heroku-jruby-builder/envvar?circle-token=${CLEAR_TEXT_CIRCLECI_TOKEN}"

curl -X POST \
  --header "Content-Type: application/json" \
  -d '{"branch": "main"}' \
  "https://circleci.com/api/v1.1/project/github/heroku/docker-heroku-jruby-builder/build?circle-token=${CLEAR_TEXT_CIRCLECI_TOKEN}"
