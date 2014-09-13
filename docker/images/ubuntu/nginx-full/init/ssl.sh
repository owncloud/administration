#!/usr/bin/env bash
set -e

if [[ ! -d /data/ssl ]]; then
  mkdir -p /data/ssl
fi

if [[ ! -f /data/ssl/owncloud.crt ]]; then
  pushd /data/ssl
  
  export PASSPHRASE=$(head -c 500 /dev/urandom | tr -dc a-z0-9A-Z | head -c 128; echo)
  
  openssl genrsa -des3 -out owncloud.key -passout env:PASSPHRASE 2048
  openssl req -new -batch -key owncloud.key -out owncloud.csr -passin env:PASSPHRASE
  
  cp owncloud.key owncloud.key.org
  
  openssl rsa -in owncloud.key.org -out owncloud.key -passin env:PASSPHRASE
  openssl x509 -req -days 3650 -in owncloud.csr -signkey owncloud.key -out owncloud.crt
  
  unset PASSPHRASE
  
  popd
fi

chown -R www-data:www-data /data/ssl
