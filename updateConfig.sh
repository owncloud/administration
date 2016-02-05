#!/bin/sh

currentDir=$(pwd)

if [[ -d /tmp/owncloud-documentation ]]
then
	rm -rf /tmp/owncloud-documentation
fi

# fetch documentation repo
git clone -q git@github.com:owncloud/documentation.git /tmp/owncloud-documentation
cd /tmp/owncloud-documentation

for branch in stable7 stable8 stable8.1 stable8.2 master
do
	git checkout -q $branch
	cd $currentDir

	# download current version of config.sample.php
	curl -sS -o /tmp/config.sample.php https://raw.githubusercontent.com/owncloud/core/$branch/config/config.sample.php

	if [[ $branch == 'stable7' ]]; then
		# use that to generate the documentation
		php convert.php --input-file=/tmp/config.sample.php --output-file=/tmp/owncloud-documentation/admin_manual/configuration/config_sample_php_parameters.rst
	else
		# use that to generate the documentation
		php convert.php --input-file=/tmp/config.sample.php --output-file=/tmp/owncloud-documentation/admin_manual/configuration_server/config_sample_php_parameters.rst
	fi

	cd /tmp/owncloud-documentation
	# invokes an output if something has changed
	status=$(git status -s)

	if [ -n "$status" ]; then
		echo "Push $branch"
		git commit -qam 'generate documentation from config.sample.php'
		git push
	fi

	# cleanup
	rm -rf /tmp/config.sample.php
done
