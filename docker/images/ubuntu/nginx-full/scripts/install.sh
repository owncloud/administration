#!/usr/bin/env bash
set -e
set -x

cp /build/init/* /etc/my_init.d/

/build/scripts/update.sh
/build/scripts/nginx.sh
/build/scripts/mysql.sh
/build/scripts/php.sh
/build/scripts/finalize.sh
