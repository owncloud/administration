#! /bin/sh
#
# occ_fsck.sh -- check the filesystem of an owncloud for consistency.
#
# Current limitations:
#  mysql or sqlite only,
#  primary storage only, local filesystem or object store.
#  requires python or python3

bindir=$(dirname $0)
config=$1
suspect="/srv/www/htdocs /srv/www /var/www/htdocs /var/www"

if [ -z "$config" ]; then
  for root in $suspect; do
    if [ -f  $root/owncloud/config/config.php ]; then
      config=$root/owncloud/config/config.php
    fi
  done
fi

if [ -z "$config" -o ! -f "$config" ]; then
  echo "Could not find your owncloud/config/config.php in $suspect"
  echo "Please specify the full path as first parameter to $0"
  echo "Optional second parameter: pathprefix or username"
  exit 1
fi


userprefix=$2
test -z "$userprefix" && userprefix=/

dir=$(date +%Y-%m-%d_%H%M)
mkdir -p $dir
echo "output folder: $dir"

if [ -n "$(python3 --version 2>/dev/null)" ]; then
  python=python3	# prefer 3.x over 2.7
  import_e=$($python $bindir/occ_checksum_check.py /dev/null / 2>&1 | grep ImportError:)
  test -n "$import_e" && python=python
else
  python=python
fi
## force python2:
# python=python

set -x
$python $bindir/occ_checksum_check.py $config $userprefix >$dir/good.log 2>$dir/bad.log

sh $bindir/occ_fsck_report.sh $dir

if [ "$userprefix" = "/" ]; then
  $python $bindir/stale_filecache.py $config $dir/fileids_seen.out
fi
