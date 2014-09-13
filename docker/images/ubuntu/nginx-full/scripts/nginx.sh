#!/usr/bin/env bash
set -e
set -x

apt-get install -y --no-install-recommends nginx

rm -rf /etc/nginx/*
cp /build/configs/nginx.conf /etc/nginx/
cp /build/configs/fastcgi.params /etc/nginx/
cp /build/configs/mime.types /etc/nginx/

mkdir -p /etc/service/nginx
cp /build/runit/nginx.sh /etc/service/nginx/run
