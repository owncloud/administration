#!/bin/bash
#
# ownCloud
#
# @author Thomas Müller
# @copyright 2014 Thomas Müller thomas.mueller@tmit.eu
#
DB=$1

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
