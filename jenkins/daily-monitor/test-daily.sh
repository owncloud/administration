#!/usr/bin/env bash

if [ "$#" -ne 1 ]; then
    echo "Usage: test-daily <from-version>"
    echo "Example: test-daily master"
    exit
fi

DATE=`date +%Y-%m-%d`
FROM_VERSION=$1
FROM=owncloud-daily-$FROM_VERSION.tar.bz2

rm -rf $FROM
rm -rf owncloud

wget http://download.owncloud.org/community/$FROM

tar -xjf $FROM

DATE_IN_VERSION=`grep OC_Build owncloud/version.php | cut -d "'" -f 2 | cut -d "T" -f1`

if [ "$DATE" != "$DATE_IN_VERSION" ]; then
    echo "Daily tar $FROM has not been updated - build date is $DATE_IN_VERSION!"
    exit 1
fi
echo "Daily tar $FROM is up to date"
