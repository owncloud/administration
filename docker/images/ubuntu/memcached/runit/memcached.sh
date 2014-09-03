#!/bin/sh
set -e
. /etc/memcached.conf
exec /sbin/setuser memcache /usr/bin/memcached $MEMCACHED_OPTS >>/var/log/memcached.log 2>&1