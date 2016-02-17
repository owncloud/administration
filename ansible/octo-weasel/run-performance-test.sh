#!/usr/bin/env bash

function execute_tests {

  if [ -f /var/log/mysql/mysql.log ]; then
    rm /var/log/mysql/mysql.log
  fi
  if [ -f /var/log/mysql/mysql-slow.log ]; then
    rm /var/log/mysql/mysql-slow.log
  fi
  echo -n "" > /var/log/apache2/access.log

  echo "$(date '+%Y-%m-%d %H-%M-%S') Re-setup MySQL ..."
  mysql -e "DROP DATABASE owncloud; CREATE DATABASE owncloud; SET GLOBAL general_log = $1;"
  rm -rf /var/www/owncloud/config/config.php /var/www/owncloud/data/*

  echo "$(date '+%Y-%m-%d %H-%M-%S') Install owncloud ..."
  cd /var/www/owncloud
  sudo -u www-data php occ maintenance:install --admin-pass=admin --database=mysql --database-name=owncloud --database-user=owncloud --database-pass=owncloud

  mkdir -p /tmp/performance-tests
  echo "$(date '+%Y-%m-%d %H-%M-%S') Running performance test ..."
  DAV_USER=admin DAV_PASS=admin /root/administration/performance-tests-c++/webdav-benchmark http://localhost/remote.php/webdav/ -csv > /tmp/performance-tests/$currentTime.csv

  if [ "$1" -eq "1" ]; then
    rm /tmp/performance-tests/$currentTime.csv
  else
    mv /tmp/performance-tests/$currentTime.csv /tmp/performance-tests/result.$2.$shaSum.$currentTime.csv
  fi

  if [ -f /var/log/mysql/mysql.log -a "$1" -eq "1" ]; then
    mv /var/log/mysql/mysql.log /tmp/performance-tests/mysql-general-query-$currentTime.log
  fi
  if [ -f /var/log/mysql/mysql-slow.log -a "$1" -eq "0" ]; then
    mv /var/log/mysql/mysql-slow.log /tmp/performance-tests/mysql-slow-query-$currentTime.log
  fi

  cp /var/log/apache2/access.log /tmp/performance-tests/access-$currentTime.log
}

if [ -z "$1" ]; then
    echo "Please specify the commit to test"
    exit 1;
fi

echo "$(date '+%Y-%m-%d %H-%M-%S') Starting ..."

currentTime=$(date +%Y-%m-%d.%H-%M-%S)

echo "$(date '+%Y-%m-%d %H-%M-%S') Checkout commit $2 ..."
cd /var/www/owncloud
git fetch
git checkout -q $1 || exit 1
shaSum=$(git rev-parse HEAD)
echo "SHA sum: $shaSum"
git submodule update

echo "$(date '+%Y-%m-%d %H-%M-%S') Running WITHOUT general query logger ... "
execute_tests 0 $1
echo "$(date '+%Y-%m-%d %H-%M-%S') Running WITH general query logger ... "
execute_tests 1 $1

echo "$(date '+%Y-%m-%d %H-%M-%S') Aggregate query and access logs ..."
cd /root
php process.php /tmp/performance-tests/mysql-general-query-$currentTime.log /tmp/performance-tests/access-$currentTime.log /tmp/performance-tests/stats.$1.$shaSum.$currentTime.json

# TODO push the results to weasel API

echo "$(date '+%Y-%m-%d %H-%M-%S') Finished"
