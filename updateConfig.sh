#!/bin/sh

currentDir=$(pwd)

if [[ -d /tmp/owncloud-documentation ]]
then
	rm -rf /tmp/owncloud-documentation
fi

# fetch documentation repo
git clone -q git@github.com:owncloud/documentation.git /tmp/owncloud-documentation
cd /tmp/owncloud-documentation
git checkout -q config-sample-preparation
git checkout -q -b config-update-$(date +%Y-%m-%d)
cd $currentDir

# download current version of config.sample.php
curl -sS -o /tmp/config.sample.php https://raw.githubusercontent.com/owncloud/core/stable7/config/config.sample.php

# use that to generate the documentation
php convert.php --input-file=/tmp/config.sample.php --output-file=/tmp/owncloud-documentation/admin_manual/configuration/configuration_config_sample_php.rst

cd /tmp/owncloud-documentation
# invokes an output if something has changed
git status -s

# cleanup
rm -rf /tmp/config.sample.php
