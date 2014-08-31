#!/bin/bash

BASE_PATH=$(dirname $0)
cd $BASE_PATH

TESTS=$PWD/specs
SERVER_NAME="oc-test"
PORT=8888

echo "Discover IP"
#Get IP of ownCLoud-Server
IP=$(docker inspect -f "{{ .NetworkSettings.IPAddress }}" $SERVER_NAME) 
while ! ssh -oStrictHostKeyChecking=no -i configs/insecure_key root@$IP php -v > /dev/null 2>&1
do
  printf "." && sleep 1
done
echo "ssh -i configs/insecure_key root@$IP"

BASE_URL="https://127.0.0.1:$PORT/"

echo "Testing on $BASE_URL"
# Install with install test suite
protractor $TESTS/protractor_conf.js --params.baseUrl=$BASE_URL --suite install

# Disabling the firstrunwizard via ssh
scp -oStrictHostKeyChecking=no -i configs/insecure_key configs/disable_firstrunwizard.sh root@$IP:/tmp/disable_firstrunwizard.sh > /dev/null 2>&1
ssh -oStrictHostKeyChecking=no -i configs/insecure_key root@$IP /tmp/disable_firstrunwizard.sh > /dev/null 2>&1

protractor $TESTS/protractor_conf.js --params.baseUrl=$BASE_URL --exclude=specs/tests/install/install_spec.js

# Single Suites

# protractor $TESTS/protractor_conf.js --params.baseUrl=$BASE_URL --suite login
# protractor $TESTS/protractor_conf.js --params.baseUrl=$BASE_URL --suite files
# protractor $TESTS/protractor_conf.js --params.baseUrl=$BASE_URL --suite share

# Single Specs

# protractor $TESTS/protractor_conf.js --params.baseUrl=$BASE_URL --specs specs/tests/login/authentication_spec.js
# protractor $TESTS/protractor_conf.js --params.baseUrl=$BASE_URL --specs specs/tests/login/change_password_spec.js
# protractor $TESTS/protractor_conf.js --params.baseUrl=$BASE_URL --specs specs/tests/login/new_user_spec.js
# protractor $TESTS/protractor_conf.js --params.baseUrl=$BASE_URL --specs specs/tests/login/username_cases_spec.js

# protractor $TESTS/protractor_conf.js --params.baseUrl=$BASE_URL --specs specs/tests/share/share_spec.js
# protractor $TESTS/protractor_conf.js --params.baseUrl=$BASE_URL --specs specs/tests/share/share_api_spec.js