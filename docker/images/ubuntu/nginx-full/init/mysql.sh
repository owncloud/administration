#!/usr/bin/env bash
set -e

if [[ ! -d /data/mysql ]]; then
  mkdir -p /data/mysql
  cp -rf /var/lib/mysql/* /data/mysql/
fi

chown -R mysql:mysql /data/mysql
