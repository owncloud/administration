#!/bin/bash
# Script performs non-interactive installation of Oracle XE 10g on Debian
#
# Based on oracle10g-update.sh from HTSQL project:
# https://bitbucket.org/prometheus/htsql
#
# Modified by Mateusz Loskot <mateusz@loskot.net>
# Changes:
# - Add fake swap support (backup /usr/bin/free manually anyway!)
# 
# Modified by Peter Butkovic <butkovic@gmail.com> to enable i386 install on amd64 architecture (precise 64)
# based on: http://www.ubuntugeek.com/how-to-install-oracle-10g-xe-in-64-bit-ubuntu.html
# 
# set -ex

# build php module
git clone https://github.com/DeepDiver1975/oracle_instant_client_for_ubuntu_64bit.git instantclient
cd instantclient
sudo bash -c 'printf "\n" | python system_setup.py'

sudo mkdir -p /usr/lib/oracle/11.2/client64/rdbms/
sudo ln -s /usr/include/oracle/11.2/client64/ /usr/lib/oracle/11.2/client64/rdbms/public

sudo apt-get install -qq --force-yes libaio1
printf "/usr/lib/oracle/11.2/client64\n" | pecl install oci8

cat ~/.phpenv/versions/$(phpenv version-name)/etc/php.ini

# add travis user to oracle user group - necessary for execution of sqlplus
sudo adduser travis dba

# start oracle docker
DOCKER_CONTAINER_ID=$(docker run -d deepdiver/docker-oracle-xe-11g)
DATABASEHOST=$(docker inspect --format="{{.NetworkSettings.IPAddress}}" "$DOCKER_CONTAINER_ID")

for i in {1..48}
    do
            if sqlplus "system/oracle@(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(Host=$DATABASEHOST)(Port=1521))(CONNECT_DATA=(SID=XE)))" < /dev/null | grep 'Connected to'; then
                    break;
            fi
            sleep 5
    done

export DATABASEHOST
