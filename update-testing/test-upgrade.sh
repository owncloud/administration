#!/bin/bash
#
# ownCloud
#
# @author Thomas Müller
# @copyright 2013 Thomas Müller deepdiver@owncloud.com
#
#$EXECUTOR_NUMBER is set by Jenkins and allows us to run autotest in parallel
DATABASENAME=oc_autotest$EXECUTOR_NUMBER
DATABASEUSER=oc_autotest$EXECUTOR_NUMBER
ADMINLOGIN=admin$EXECUTOR_NUMBER
BASEDIR=$PWD

if [ "$#" -ne 3 ]; then
    echo "Usage: test-upgrade <from-version> <to-version> <database>"
    echo "Example: test-upgrade 5.0.13 6.0.0 pgsql"
    echo "Valid databases: sqlite mysql pgsql"
    exit
fi

FROM_VERSION=$1
TO_VERSION=$2
DATABASE=$3

FROM=owncloud-$FROM_VERSION.tar.bz2
TO=owncloud-$TO_VERSION.tar.bz2

if [ "$TO_VERSION" == "daily" ]; then
  TO=owncloud-daily-master.tar.bz2
  rm -f $TO
  wget http://download.owncloud.org/community/daily/owncloud-daily-master.tar.bz2
fi

if [[ $TO_VERSION == git* ]]; then
  GIT_BRANCH=`echo $TO_VERSION | cut -c 5-`
  TO=$GIT_BRANCH.tar.bz2
  rm -f $TO
  rm -rf g
  mkdir g
  cd g
  git clone -b $GIT_BRANCH --recursive --depth 1 https://github.com/owncloud/core.git owncloud
  rm -rf owncloud/.git
  rm -rf owncloud/build
  rm -rf owncloud/tests
  tar -cjf $TO owncloud
  mv $TO ..
  cd ..
  rm -rf g
fi

BASEDIR_W=`pwd -W`
DATADIR=$BASEDIR_W/$FROM_VERSION-$TO_VERSION-$DATABASE

if [ ! -f $FROM ]; then
  wget http://download.owncloud.org/community/$FROM
  wget http://download.owncloud.org/community/testing/$FROM
else
  echo "Reuse existing $FROM"
fi

if [ ! -f $TO ]; then
  wget http://download.owncloud.org/community/$TO
  wget http://download.owncloud.org/community/testing/$TO
else
  echo "Reuse existing $TO"
fi

if [ ! -f $FROM ]; then
  echo "Could not download $FROM"
  exit
fi

if [ ! -f $TO ]; then
  echo "Could not download $TO"
  exit
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

cat > ./autoconfig-mssql.php <<DELIM
<?php
\$AUTOCONFIG = array (
  'installed' => false,
  'dbtype' => 'mssql',
  'dbtableprefix' => 'oc_',
  'adminlogin' => '$ADMINLOGIN',
  'adminpass' => 'admin',
  'directory' => '$DATADIR/owncloud/data',
  'dbuser' => '$DATABASEUSER',
  'dbname' => '$DATABASENAME',
  'dbhost' => 'localhost\sqlexpress',
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
	echo "drop the database: $DATABASENAME"
	sqlplus -s -l / as sysdba <<EOF
		drop user $DATABASENAME cascade;
EOF

	echo "create the database: $DATABASENAME"
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
if [ "$DATABASE" == "mssql" ] ; then
	sqlcmd -S "localhost\sqlexpress" -U $DATABASEUSER -P owncloud -Q "IF EXISTS (SELECT name FROM sys.databases WHERE name=N'$DATABASENAME') DROP DATABASE [$DATABASENAME]"
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

echo "Done"
exit


if [ -f console.php ]; then
  # install test data
  mkdir -p data/admin/files
  cd data/admin/files
  git clone git@github.com:owncloud/test-data.git

  # scan the files
  cd $DATADIR/owncloud
  php -f console.php files:scan --all
else
  echo "[FAILED] ownCloud console not available."
fi

# fire up the cron scheduler
echo "Running the cron scheduler ..."
cd $DATADIR/owncloud
php -f cron.php
php -f cron.php
echo "Done."

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

echo "Done"
exit

# UPGRADE
echo "Start upgrading from $FROM to $TO"
if [ -f upgrade.php ]; then
  php upgrade.php
else
  php -f console.php upgrade
fi

echo "done."


