#!/bin/bash
#
# ownCloud
#
# @author Thomas Müller
# @copyright 2013 Thomas Müller deepdiver@owncloud.com
#
DATABASENAME=oc_autotest
DATABASEUSER=oc_autotest
ADMINLOGIN=admin
BASEDIR=$PWD

FROM=owncloud-5.0.10.tar.bz2
TO=owncloud-5.0.11RC1.tar.bz2

# use tmpfs for datadir - should speedup unit test execution
if [ -d /dev/shm ]; then
  DATADIR=/dev/shm/upgrade-testing
else
  DATADIR=$BASEDIR/upgrade-testing
fi

if [ ! -f $FROM ]; then
  wget http://download.owncloud.org/community/$FROM
else
  echo "Reuse existing $FROM"
fi

if [ ! -f $TO ]; then
  wget http://download.owncloud.org/community/$TO
else
  echo "Reuse existing $TO"
fi

# create owncloud configurations
cat > ./autoconfig-sqlite.php <<DELIM
<?php
\$AUTOCONFIG = array (
  'installed' => false,
  'dbtype' => 'sqlite',
  'dbtableprefix' => 'oc_',
  'adminlogin' => '$ADMINLOGIN',
  'adminpass' => 'admin',
  'directory' => '$DATADIR/data',
);
DELIM

cat > ./autoconfig-mysql.php <<DELIM
<?php
\$AUTOCONFIG = array (
  'installed' => false,
  'dbtype' => 'mysql',
  'dbtableprefix' => 'oc_',
  'adminlogin' => '$ADMINLOGIN',
  'adminpass' => 'admin',
  'directory' => '$DATADIR/data',
  'dbuser' => '$DATABASEUSER',
  'dbname' => '$DATABASENAME',
  'dbhost' => 'localhost',
  'dbpass' => 'owncloud',
);
DELIM

cat > ./autoconfig-pgsql.php <<DELIM
<?php
\$AUTOCONFIG = array (
  'installed' => false,
  'dbtype' => 'pgsql',
  'dbtableprefix' => 'oc_',
  'adminlogin' => '$ADMINLOGIN',
  'adminpass' => 'admin',
  'directory' => '$DATADIR/data',
  'dbuser' => '$DATABASEUSER',
  'dbname' => '$DATABASENAME',
  'dbhost' => 'localhost',
  'dbpass' => 'owncloud',
);
DELIM

# database cleanup
if [ "$1" == "mysql" ] ; then
	mysql -u $DATABASEUSER -powncloud -e "DROP DATABASE $DATABASENAME"
fi
if [ "$1" == "pgsql" ] ; then
	dropdb -U $DATABASEUSER $DATABASENAME
fi

rm -rf $DATADIR
mkdir $DATADIR
cd $DATADIR

# install from version
echo "Installing $FROM to $DATADIR"
tar -xjf $BASEDIR/$FROM
cd owncloud
mkdir data

DATABASE=sqlite
if [ ! -z "$1" ]; then
  DATABASE=$1
fi

cp $BASEDIR/autoconfig-$DATABASE.php config/autoconfig.php

php -f index.php

if [ -f occ ]; then
  # install test data
  mkdir -p data/admin/files
  cd data/admin/files
  git clone git@github.com:owncloud/test-data.git
  cd $DATADIR
  ./occ files:scan --all
else
  echo "[FAILED] ownCloud console not available."
fi

cd $DATADIR

# install to version
echo "Installing $TO to $DATADIR"

tar -xjf $BASEDIR/$TO
cd owncloud

# UPGRADE
echo "Start upgrading from $FROM to $TO"
if [ -f upgrade.php ]; then
  php upgrade.php
else
  echo "[FAILED] no upgrade script available."
fi


