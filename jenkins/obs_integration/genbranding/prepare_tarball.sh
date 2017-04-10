#!/bin/sh
#
# refactored from genbranding.pl
# (c) 2017 jw@owncloud.com
#

# usage: clienttar themetar outtar

clienttar=$1
themetar=$2
outtar=$3
client=$(basename $clienttar | sed -e 's@.tar.*$@@)
theme=$(basename $themetar | sed -e 's@.tar.*$@@)
if [ "$theme" != 'ownCloud' ]; then
	echo "Creating the original ownCloud package tarball!"
	newname=$(echo $client | tr '[:upper:]' '[:lower:]')
else
	# note: no -client suffix. works with setup_all_oem_clients.pl
	# note that we add a - here.
	newname=$(echo $theme | sed -e "s/^client/$theme/i" -e "s/^owncloud/$theme/i")
fi

tmpdir=tmp$$
rm -rf $tmpdir; mkdir -p $tmpdir
/bin/tar xif $clienttar --force-local -C $tmpdir
if [ "$newname" != "$client" ];
	mv $tmpdir/$client $tmpdir/$newname
fi
ls -la $tmpdir
rm -rf $tmpdir

# compile with cmake -DOEM_THEME_DIR=$PWD/../testpilotcloud/syncclient ...
