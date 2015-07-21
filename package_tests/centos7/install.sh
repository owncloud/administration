#!/usr/bin/env bash

declare -x VERSION

cd /etc/yum.repos.d/
wget http://download.opensuse.org/repositories/isv:ownCloud:community/CentOS_7/isv:ownCloud:community.repo
wget http://download.opensuse.org/repositories/isv:/ownCloud:/community:/$VERSION/CentOS_7/isv:ownCloud:community:$VERSION.repo
yum -y install owncloud; yum clean all;

/usr/sbin/httpd

cd /var/www/html/owncloud/
su -s /bin/sh apache -c "php ./occ maintenance:install --no-interaction --admin-user admin --admin-pass admin"

echo "Installed Version $VERSION with repository:" 
echo "http://download.opensuse.org/repositories/isv:/ownCloud:/community:/$VERSION/CentOS_7/isv:ownCloud:community:$VERSION.repo"

su -s /bin/sh apache -c "php ./occ status"