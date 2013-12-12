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

if [ "$#" -ne 3 ]; then
    echo "Usage: test-upgrade <from-version> <to-version> <database>"
    echo "Example: test-upgrade 5.0.13 6.0.0 pgsql"
    echo "Valid databases: sqlit mysql pgsql"
    exit
fi

FROM_VERSION=$1
TO_VERSION=$2
DATABASE=$3

FROM=owncloud-$FROM_VERSION.tar.bz2
TO=owncloud-$TO_VERSION.tar.bz2

DATADIR=$BASEDIR/upgrade-testing-$FROM_VERSION-$TO_VERSION-$DATABASE

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
  'directory' => '$DATADIR/owncloud/data',
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
  'directory' => '$DATADIR/owncloud/data',
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
  'directory' => '$DATADIR/owncloud/data',
  'dbuser' => '$DATABASEUSER',
  'dbname' => '$DATABASENAME',
  'dbhost' => 'localhost',
  'dbpass' => 'owncloud',
);
DELIM

cat > ./autoconfig-oci.php <<DELIM
<?php
\$AUTOCONFIG = array (
  'installed' => false,
  'dbtype' => 'oci',
  'dbtableprefix' => 'oc_',
  'adminlogin' => '$ADMINLOGIN',
  'adminpass' => 'admin',
  'directory' => '$DATADIR/owncloud/data',
  'dbuser' => '$DATABASENAME',
  'dbname' => 'XE',
  'dbhost' => 'localhost',
  'dbpass' => 'owncloud',
);
DELIM

# database cleanup
if [ "$DATABASE" == "mysql" ] ; then
	mysql -u $DATABASEUSER -powncloud -e "DROP DATABASE $DATABASENAME"
fi
if [ "$DATABASE" == "pgsql" ] ; then
	dropdb -U $DATABASEUSER $DATABASENAME
fi
if [ "$DATABASE" == "oci" ] ; then
	echo "drop the database"
	sqlplus -s -l / as sysdba <<EOF
		drop user $DATABASENAME cascade;
EOF

	echo "create the database"
	sqlplus -s -l / as sysdba <<EOF
		create user $DATABASENAME identified by owncloud;
		alter user $DATABASENAME default tablespace users
		temporary tablespace temp
		quota unlimited on users;
		grant create session
		, create table
		, create procedure
		, create sequence
		, create trigger
		, create view
		, create synonym
		, alter session
		to $DATABASENAME;
		exit;
EOF
fi

rm -rf $DATADIR
mkdir $DATADIR
cd $DATADIR

# install from version
echo "Installing $FROM to $DATADIR"
tar -xjf $BASEDIR/$FROM
cd owncloud
mkdir data

cp $BASEDIR/autoconfig-$DATABASE.php config/autoconfig.php

php -f index.php

if [ -f console.php ]; then
  # install test data
  mkdir -p data/admin/files
  cd data/admin/files
  git clone git@github.com:owncloud/test-data.git
  cd $DATADIR/owncloud
  php -f console.php files:scan --all
else
  echo "[FAILED] ownCloud console not available."
fi

cd $DATADIR

# cleanup old code
rm -rf owncloud/3rdparty
rm -rf owncloud/apps
rm -rf owncloud/core
rm -rf owncloud/l10n
rm -rf owncloud/lib
rm -rf owncloud/ocs
rm -rf owncloud/search
rm -rf owncloud/settings
rm -rf owncloud/upgrade.php

# install to version
echo "Installing $TO to $DATADIR"

tar -xjf $BASEDIR/$TO
cd owncloud

# generate db migration script
php -f console.php db:generate-change-script > $BASEDIR/migration-$FROM_VERSION-$TO_VERSION-$DATABASE.sql

# UPGRADE
echo "Start upgrading from $FROM to $TO"
if [ -f upgrade.php ]; then
  php upgrade.php
else
  php -f console.php upgrade
fi

echo "done."


