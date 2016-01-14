#!/bin/bash

echo "$(date '+%Y-%m-%d %H-%M-%S') Starting ..."


function execute_tests {

  rm /var/log/apache2/access.log /var/log/mysql/mysql.log /var/log/mysql/mysql-slow.log

  echo "$(date '+%Y-%m-%d %H-%M-%S') Re-setup MySQL ..."
  mysql -e "DROP DATABASE owncloud; CREATE DATABASE owncloud; SET GLOBAL general_log = $1;"
  rm -rf /var/www/owncloud/config/config.php /var/www/owncloud/data/*

  cd /var/www/owncloud
  sudo -u www-data php occ maintenance:install --admin-pass=admin --database=mysql --database-name=owncloud --database-user=owncloud --database-pass=owncloud

  mkdir -p /tmp/performance-tests
  currentTime=$(date +%Y-%m-%d.%H-%M-%S)
  echo "$(date '+%Y-%m-%d %H-%M-%S') Running performance test ..."
  DAV_USER=admin DAV_PASS=admin /root/administration/performance-tests-c++/webdav-benchmark http://localhost/remote.php/webdav/ -csv > /tmp/performance-tests/$currentTime.csv
  mv /var/log/mysql/mysql.log /tmp/performance-tests/mysql-general-query-$currentTime.log
  mv /var/log/mysql/mysql-slow.log /tmp/performance-tests/mysql-slow-query-$currentTime.log

  mv /var/log/apache2/access.log /tmp/performance-tests/access-$currentTime.log
}

echo "$(date '+%Y-%m-%d %H-%M-%S') Running WITHOUT general query logger ... "
execute_tests 0
echo "$(date '+%Y-%m-%d %H-%M-%S') Running WITH general query logger ... "
execute_tests 1

echo "$(date '+%Y-%m-%d %H-%M-%S') Finished"
