#!/bin/bash
# Runs the original NetPoint unit tests and tests whether all initializers work.
# Usage:
#   ./test.sh latest
#   ./test.sh v2.9.7
#   ./test.sh develop-2.10
#   IMAGE='khulnasoft/netpoint:latest'        ./test.sh
#   IMAGE='khulnasoft/netpoint:v2.9.7'        ./test.sh
#   IMAGE='khulnasoft/netpoint:develop-2.10'  ./test.sh
#   export IMAGE='khulnasoft/netpoint:latest';       ./test.sh
#   export IMAGE='khulnasoft/netpoint:v2.9.7';       ./test.sh
#   export IMAGE='khulnasoft/netpoint:develop-2.10'; ./test.sh

# exit when a command exits with an exit code != 0
set -e

source ./build-functions/gh-functions.sh

# IMAGE is used by `docker-compose.yml` do determine the tag
# of the Docker Image that is to be used
if [ "${1}x" != "x" ]; then
  # Use the command line argument
  export IMAGE="khulnasoft/netpoint:${1}"
else
  export IMAGE="${IMAGE-khulnasoft/netpoint:latest}"
fi

# Ensure that an IMAGE is defined
if [ -z "${IMAGE}" ]; then
  echo "⚠️ No image defined"

  if [ -z "${DEBUG}" ]; then
    exit 1
  else
    echo "⚠️ Would 'exit 1' here, but DEBUG is '${DEBUG}'."
  fi
fi

# The docker compose command to use
doco="docker compose --file docker-compose.test.yml --file docker-compose.test.override.yml --project-name netpoint_docker_test"

test_setup() {
  gh_echo "::group:: Test setup"
  echo "🏗 Setup up test environment"
  $doco up --detach --quiet-pull --wait --force-recreate --renew-anon-volumes --no-start
  $doco start postgres
  $doco start redis
  $doco start redis-cache
  gh_echo "::endgroup::"
}

test_netpoint_unit_tests() {
  gh_echo "::group:: Netpoint unit tests"
  echo "⏱ Running NetPoint Unit Tests"
  $doco run --rm netpoint /opt/netpoint/venv/bin/python /opt/netpoint/netpoint/manage.py test
  gh_echo "::endgroup::"
}

test_compose_db_setup() {
  gh_echo "::group:: Netpoint DB migrations"
  echo "⏱ Running NetPoint DB migrations"
  $doco run --rm netpoint /opt/netpoint/venv/bin/python /opt/netpoint/netpoint/manage.py migrate
  gh_echo "::endgroup::"
}

test_netpoint_start() {
  gh_echo "::group:: Start Netpoint service"
  echo "⏱ Starting NetPoint services"
  $doco up --detach --wait
  gh_echo "::endgroup::"
}

test_netpoint_web() {
  gh_echo "::group:: Web service test"
  echo "⏱ Starting web service test"
  RESP_CODE=$(
    curl \
      --silent \
      --output /dev/null \
      --write-out '%{http_code}' \
      --request GET \
      --connect-timeout 5 \
      --max-time 10 \
      --retry 5 \
      --retry-delay 0 \
      --retry-max-time 40 \
      http://127.0.0.1:8000/
  )
  if [ "$RESP_CODE" == "200" ]; then
    echo "Webservice running"
  else
    echo "⚠️ Got response code '$RESP_CODE' but expected '200'"
    exit 1
  fi
  gh_echo "::endgroup::"
}

test_cleanup() {
  echo "💣 Cleaning Up"
  gh_echo "::group:: Docker compose logs"
  $doco logs --no-color
  gh_echo "::endgroup::"
  gh_echo "::group:: Docker compose down"
  $doco down --volumes
  gh_echo "::endgroup::"
}

echo "🐳🐳🐳 Start testing '${IMAGE}'"

# Make sure the cleanup script is executed
trap test_cleanup EXIT ERR
test_setup

test_netpoint_unit_tests
test_compose_db_setup
test_netpoint_start
test_netpoint_web

echo "🐳🐳🐳 Done testing '${IMAGE}'"
