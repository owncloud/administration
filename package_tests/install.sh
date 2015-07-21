#!/usr/bin/env bash

[ $# == 1 ] || exit

OS=$1

rm -f log/${OS}_owncloud*
docker build -t ${OS}_owncloud ${OS}/

for VERSION in 7.0 8.0 8.1
do
  ((docker run --rm -e VERSION=${VERSION} ${OS}_owncloud > log/${OS}_owncloud_${VERSION}.log) \
     && (tail -n 7 log/${OS}_owncloud_${VERSION}.log > log/${OS}_owncloud_${VERSION}_short.log)) &
done
