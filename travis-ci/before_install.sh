#!/bin/bash
#
# ownCloud
#
# @author Thomas Müller
# @copyright 2014 Thomas Müller thomas.mueller@tmit.eu
#

WORKDIR=$PWD
APP_NAME=$1
CORE_BRANCH=$2
echo "Work directory: $WORKDIR"
cd ..
git clone --depth 1 -b $CORE_BRANCH https://github.com/owncloud/core
cd core
git submodule update --init

cd apps
cp -R ../../$APP_NAME/ .
cd $WORKDIR

if [ "$1" == "mysql" ] ; then
  mysql -e 'create database oc_autotest;'
  mysql -u root -e "CREATE USER 'oc_autotest'@'localhost' IDENTIFIED BY 'owncloud'";
  mysql -u root -e "grant all on oc_autotest.* to 'oc_autotest'@'localhost'";
fi

if [ "$1" == "pgsql" ] ; then
  createuser -U travis -s oc_autotest
fi

if [ "$1" == "oracle" ] ; then
  if [ ! -f $FROM ]; then
    wget https://raw.githubusercontent.com/owncloud/administration/master/travis-ci/before_install_oracle.sh
  fi

  ./before_install_oracle.sh
fi

#
# copy install script
#
cd ../core
if [ ! -f $FROM ]; then
    wget https://raw.githubusercontent.com/owncloud/administration/master/travis-ci/core_install.sh
fi

./core_install.sh
