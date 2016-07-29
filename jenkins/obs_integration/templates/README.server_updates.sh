#!/bin/sh
#
# Do not run this script. It is for demonstration only. Refer to ../tar2pack_all.sh instead.
# Copy paste, monitor!

# msg='Updated to [% VERSION %]'
# msg='Updated to [% VERSION %]~[% PRERELEASE %]'
msg='template change: no more fdupes for SUSE. All shall behave equal'

# use this, if osc user fails:
defs='-d MAINTAINER_EMAIL=jw@owncloud.com -d MAINTAINER_NAME='Juergen Weigert'
opts="-v -t ~/obs_integration/templates/ $defs"

cd ce:9.0/owncloud
tar2pack -d VERSION=9.0.0 $opts -O . -m $msg owncloud-*.tar.bz2
cd ../..

cd ce:9.0/owncloud-files
tar2pack -d VERSION=9.0.0 $opts -O . -m $msg owncloud-*.tar.bz2
cd ../..


cd ce:nighlty/owncloud-files
tar2pack -d VERSION=9.1.0 -d SOURCE_TAR_URL='owncloud-%{base_version}%{prerelease}.tar.bz2' $opts -n -O . -m $msg owncloud-*.tar.bz2
cd ../..

cd ce:nighlty/owncloud
tar2pack -d VERSION=9.1.0 -d PRERELEASE=prealpha $opts -O . -m $msg owncloud-*.tar.bz2
cd ../..

