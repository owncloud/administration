#!/usr/bin/env bash
set -e
set -x

apt-get install -y --no-install-recommends php5-fpm php5-gd php5-json php5-mysql php5-sqlite php5-curl php5-intl php5-mcrypt php5-imagick php5-apcu php5-memcached

cp /build/configs/cli.ini /etc/php5/cli/php.ini
cp /build/configs/fpm.ini /etc/php5/fpm/php.ini
cp /build/configs/fpm.conf /etc/php5/fpm/php-fpm.conf
cp /build/configs/pool.conf /etc/php5/fpm/pool.d/www.conf

mkdir -p /etc/service/php
cp /build/runit/php.sh /etc/service/php/run
