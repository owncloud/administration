#!/usr/bin/env bash
exec /usr/bin/mysqld_safe #>> /var/log/nginx.log 2>&1
