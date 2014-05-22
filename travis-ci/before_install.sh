#!/bin/bash
#
# ownCloud
#
# @author Thomas Müller
# @copyright 2014 Thomas Müller thomas.mueller@tmit.eu
#

set -e

WORKDIR=$PWD
APP_NAME=$1
CORE_BRANCH=$2
DB=$3
echo "Work directory: $WORKDIR"
echo "Database: $DB"
cd ..
git clone --depth 1 -b $CORE_BRANCH https://github.com/owncloud/core
cd core
git submodule update --init

cd apps
cp -R ../../$APP_NAME/ .
cd $WORKDIR

if [ "$DB" == "mysql" ] ; then
  mysql -e 'create database oc_autotest;'
  mysql -u root -e "CREATE USER 'oc_autotest'@'localhost' IDENTIFIED BY 'owncloud'";
  mysql -u root -e "grant all on oc_autotest.* to 'oc_autotest'@'localhost'";
fi

if [ "$DB" == "pgsql" ] ; then
  createuser -U travis -s oc_autotest
fi

if [ "$DB" == "oracle" ] ; then
  if [ ! -f before_install_oracle.sh ]; then
    wget https://raw.githubusercontent.com/owncloud/administration/master/travis-ci/before_install_oracle.sh
  fi
  bash ./before_install_oracle.sh
fi

#
# copy install script
#
cd ../core
if [ ! -f core_install.sh ]; then
    wget https://raw.githubusercontent.com/owncloud/administration/master/travis-ci/core_install.sh
fi

bash ./core_install.sh $DB
