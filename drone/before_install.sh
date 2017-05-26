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
if [ -f Makefile ]; then
  make
fi

cd apps
pwd
ls ../../
cp -R ../../$APP_NAME/ .
cd $WORKDIR

#
# copy custom php.ini settings
#
#wget https://raw.githubusercontent.com/owncloud/administration/master/travis-ci/custom.ini
#if [ $(phpenv version-name) != 'hhvm' ]; then
#  phpenv config-add custom.ini
#fi

echo 'always_populate_raw_post_data = -1' >> /etc/php.ini
echo 'mbstring.func_overload = 0' >> /etc/php.ini
echo 'always_populate_raw_post_data = -1' >> /etc/php.ini
echo 'default_charset = 'UTF-8'' >> /etc/php.ini
echo 'output_buffering = off' >> /etc/php.ini

#
# copy install script
#
#cd ../core
#if [ ! -f core_install.sh ]; then
#    wget https://raw.githubusercontent.com/owncloud/administration/adding-drone-scripts/drone/core_install.sh 
#fi
#
#bash ./core_install.sh $DB
