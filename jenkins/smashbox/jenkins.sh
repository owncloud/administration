#!/usr/bin/env bash

#
# Init
#
if [ -z "$WORKSPACE" ]; then
	WORKSPACE=$PWD
fi
if [ -z "$serverVersion" ]; then
	serverVersion=8.1.1
fi
if [ -z "$TEST_NAME" ]; then
	TEST_NAME="test_basicSync"
fi
if [ -z "$DOCKER_IMAGE" ]; then
	DOCKER_IMAGE=ubuntu_oc_lamp
fi

ADMIN_USER=admin
ADMIN_PASS=admin

pip install --user -r requirements.txt
chmod +x client/owncloudcmd

#
# build download url
#


#
# start the docker
#
rm -rf ${WORKSPACE}/data
mkdir -p ${WORKSPACE}/data
if [ -z "$USE_GIT_BRANCH" ]; then
	DOCKER_CONTAINER_ID=`docker run -t -i -d -e "OC_URL=https://download.owncloud.org/community/owncloud-${serverVersion}.tar.bz2" -e "OC_ADMIN_USER=${ADMIN_USER}" -e "OC_ADMIN_PASS=${ADMIN_PASS}" ${DOCKER_IMAGE}`
else
	DOCKER_CONTAINER_ID=`docker run -t -i -d -e "OC_BRANCH=${GIT_BRANCH##*/}" -e "OC_ADMIN_USER=${ADMIN_USER}" -e "OC_ADMIN_PASS=${ADMIN_PASS}" ${DOCKER_IMAGE}`
fi

function cleanup() {
	if [ ! -z "$DOCKER_CONTAINER_ID" ]; then
		echo "Kill the docker $DOCKER_CONTAINER_ID"
		docker stop "$DOCKER_CONTAINER_ID"
		docker rm -f "$DOCKER_CONTAINER_ID"
	fi
}

# restore config on exit
trap cleanup EXIT

HOST=`docker inspect --format="{{.NetworkSettings.IPAddress}}" $DOCKER_CONTAINER_ID`
echo "Docker $DOCKER_CONTAINER_ID is available on $HOST"

#
# wait until started
#
echo Waiting for docker to be started
until $(curl -sf http://$HOST/status.php | grep -q "installed\":true"); do
	# trigger installation
	curl -sSf http://$HOST/index.php
    printf '.'
    sleep 5
done
echo
echo Ready to go!

if [ -z "$USE_GIT_BRANCH" ]; then
	docker logs $DOCKER_CONTAINER_ID
fi

curl http://$HOST/status.php

#
# litmus to see if the system is up
#
if [ "$TEST_NAME" == "litmus" ]; then
	litmus -k http://${HOST}/remote.php/webdav $ADMIN_USER $ADMIN_PASS | tee litmus.out || true
	more litmus.out | grep -a -v high-unicode | grep -a FAIL | tee fail.txt
	if test -s fail.txt ; then
	    echo "litmus did fail! WebDAV not working properly! Aborting!"
	    exit 1
	fi
	echo "litmus succeeded! WebDAV working properly!"
    exit 0
fi

#
# create the config file
#
mkdir -p ${WORKSPACE}/smashdir
rm -f etc/smashbox.conf

cat > etc/smashbox.conf <<DELIM
#
# The _open_SmashBox Project.
#
# Author: Jakub T. Moscicki, CERN, 2013
# License: AGPL
#
# this is the main config file template: copy to smashbox.conf and adjust the settings
#
# this template should work without changes if you are running your tests directly on the owncloud application server
#

# this is the top directory where all local working files are kept (test working direcotires, test logs, test data, temporary filesets, ..)
smashdir = "${WORKSPACE}/smashdir"

# name of the account used for testing
# if None then account name is chosen automatically (based on the test name)
oc_account_name="test"

# default number of users for tests involving multiple users (user number is appended to the oc_account_name)
# this only applies to the tests involving multiple users
oc_number_test_users=3

# name of the group used for testing
oc_group_name="test"

# default number of groups for tests involving multiple groups (group number is appended to the oc_group_name)
# this only applies to the tests involving multiple groups
oc_number_test_groups=1

# password for test accounts: all test account will have the same password
# if not set then it's an error
oc_account_password="test"

# owncloud test server
# if left blank or "localhost" then the real hostname of the localhost will be set
oc_server = '$HOST'


# root of the owncloud installation as visible in the URL
oc_root = ''

# webdav endpoint URI within the oc_server
import os.path
oc_webdav_endpoint = os.path.join(oc_root,'remote.php/webdav') # standard owncloud server

# target folder on the server (this may not be compatible with all tests)
oc_server_folder = ''

# should we use protocols with SSL (https, ownclouds)
oc_ssl_enabled = False

# how to invoke shell commands on the server
# for localhost there is no problem - leave it blank
# for remote host it may be set like this: "ssh -t -l root $oc_server"
# note: configure ssh for passwordless login
# note: -t option is to make it possible to run sudo
oc_server_shell_cmd = ""

# Data directory on the owncloud server.
#
oc_server_datadirectory = os.path.join('/var/www/html',oc_root, 'data')

# a path to server side tools (create_user.php, ...)
#
# it may be specified as relative path "dir" and then resolves to
# <smashbox>/dir where <smashbox> is the top-level of of the tree
# containing THIS configuration file
#

oc_server_tools_path = "server-tools"

# a path to ocsync command with options
# this path should work for all client hosts
#
# it may be specified as relative path "dir" and then resolves to
# <smashbox>/dir where <smashbox> is the top-level of of the tree
# containing THIS configuration file
#
oc_sync_cmd = "client/owncloudcmd --trust"

# number of times to repeat ocsync run every time
oc_sync_repeat = 1

####################################

# unique identifier of your test run
# if None then the runid is chosen automatically (and stored in this variable)
runid = None

# if True then the local working directory path will have the runid added to it automatically
workdir_runid_enabled=False

# if True then the runid will be part of the oc_account_name automatically
oc_account_runid_enabled=False

####################################

# this defines the default account cleanup procedure
#   - "delete": delete account if exists and then create a new account with the same name
#   - "keep": don't delete existing account but create one if needed
#
# these are not implemeted yet:
#   - "sync_delete": delete all files via a sync run
#   - "webdav_delete": delete all files via webdav DELETE request
#   - "filesystem_delete": delete all files directly on the server's filesystem
oc_account_reset_procedure = "delete"

# this defined the default local run directory reset procedure
#   - "delete": delete everything in the local run directory prior to running the test
#   - "keep": keep all files (from the previous run)
rundir_reset_procedure = "delete"

web_user = "travis"

oc_admin_user = "$ADMIN_USER"
oc_admin_password = "$ADMIN_PASS"

# cleanup imported namespaces
del os

# Verbosity of curl client.
# If none then verbosity is on when smashbox run in --debug mode.
# set it to True or False to override
#
pycurl_verbose = True

# Trigger server log file copy based on this property
#
reset_server_log = False

#
# scp port to be used in scp commands, used primarily when copying over the server log file
scp_port=22

DELIM

export LD_LIBRARY_PATH=${PWD}/client:${LD_LIBRARY_PATH}

#
# run smashbox
#
TESTSET="-a"
if [[ $TEST_NAME == *"@"* ]]; then
	TESTSET="-t=${TEST_NAME##*@}"
	TEST_NAME="$( cut -d '@' -f 1 <<< "$TEST_NAME" )"
fi

echo "Running smashbox with $TESTSET"

if [ -f "lib/${TEST_NAME}.py" ]; then
	bin/smash --debug $TESTSET lib/${TEST_NAME}.py
	RESULT=$?
else
	if [ -f "lib/oc-tests/${TEST_NAME}.py" ]; then
		bin/smash --debug $TESTSET lib/oc-tests/${TEST_NAME}.py
		RESULT=$?
	else
		if [ -f "lib/owncloud/${TEST_NAME}.py" ]; then
			bin/smash --debug $TESTSET lib/owncloud/${TEST_NAME}.py
			RESULT=$?
		else
			echo Test case ${TEST_NAME} not found!
			exit 3
		fi
	fi
fi
exit $RESULT
