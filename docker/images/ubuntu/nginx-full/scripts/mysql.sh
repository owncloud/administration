#!/usr/bin/env bash
set -e
set -x

apt-get install -y --no-install-recommends mysql-server mysql-client

rm -rf /etc/mysql/conf.d
cp /build/configs/my.cnf /etc/mysql/

mkdir -p /etc/service/mysql
cp /build/runit/mysql.sh /etc/service/mysql/run
