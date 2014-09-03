#!/bin/sh
set -e

. /etc/default/apache2
. /etc/apache2/envvars

exec /usr/sbin/apache2 > /tmp/apache.log 2>&1