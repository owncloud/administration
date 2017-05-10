#!/bin/bash
#
# ownCloud
#
# @author Thomas Müller
# @copyright 2013-2017 Thomas Müller deepdiver@owncloud.com
#
#$EXECUTOR_NUMBER is set by Jenkins and allows us to run autotest in parallel
DATABASENAME=oc_autotest$EXECUTOR_NUMBER
DATABASEUSER=oc_autotest$EXECUTOR_NUMBER
ADMINLOGIN=admin$EXECUTOR_NUMBER
DATABASEHOST=localhost
BASEDIR=$PWD

if [ "$#" -ne 3 ]; then
    echo "Usage: test-upgrade <from-version> <to-version> <database>"
    echo "Example: test-upgrade 5.0.13 6.0.0 pgsql"
    echo "Valid databases: sqlite mysql pgsql"
    exit 1
fi

set -e

FROM_VERSION=$1
TO_VERSION=$2
DATABASE=$3

FROM=owncloud-$FROM_VERSION.tar.bz2
TO=owncloud-$TO_VERSION.tar.bz2

if [[ $TO_VERSION == git* ]]; then
  GIT_BRANCH=`echo $TO_VERSION | cut -c 5-`
  TO=$GIT_BRANCH.tar.bz2
	rm -f $TO
	rm -rf g
	mkdir g
	cd g
	git clone -b $GIT_BRANCH --recursive --depth 1 https://github.com/owncloud/core.git owncloud
	if [ -f owncloud/Makefile ]; then
	  cd owncloud
	  make
	  cd ..
	fi
	tar -cjf $TO owncloud
	mv $TO ..
	cd ..
	rm -rf g
fi

DATADIR=$BASEDIR/$FROM_VERSION-$TO_VERSION-$DATABASE

if [ ! -f $FROM ]; then
  wget http://download.owncloud.org/community/$FROM || true
  wget http://download.owncloud.org/community/testing/$FROM || true
else
  echo "Reuse existing $FROM"
fi

if [ ! -f $TO ]; then
  wget http://download.owncloud.org/community/$TO || true
  wget http://download.owncloud.org/community/testing/$TO || true
else
  echo "Reuse existing $TO"
fi

if [ ! -f $FROM ]; then
  echo "Could not download $FROM"
  exit 1
fi

if [ ! -f $TO ]; then
  echo "Could not download $TO"
  exit 1
fi

function cleanup_config {

	if [ ! -z "$DOCKER_CONTAINER_ID" ]; then
		echo "Kill the docker $DOCKER_CONTAINER_ID"
		docker stop "$DOCKER_CONTAINER_ID"
		docker rm -f "$DOCKER_CONTAINER_ID"
	fi
}

# restore config on exit
trap cleanup_config EXIT

# prepare databases
_DB=$DATABASE

# drop database
if [ "$DATABASE" == "mysql" ] ; then
	mysql -u "$DATABASEUSER" -powncloud -e "DROP DATABASE IF EXISTS $DATABASENAME" -h $DATABASEHOST || true
fi
if [ "$DATABASE" == "mariadb" ] ; then
	if [ ! -z "$USEDOCKER" ] ; then
		echo "Fire up the mariadb docker"
		DOCKER_CONTAINER_ID=$(docker run \
			-v $BASEDIR/tests/docker/mariadb:/etc/mysql/conf.d \
			-e MYSQL_ROOT_PASSWORD=owncloud \
			-e MYSQL_USER="$DATABASEUSER" \
			-e MYSQL_PASSWORD=owncloud \
			-e MYSQL_DATABASE="$DATABASENAME" \
			-d mariadb)
		DATABASEHOST=$(docker inspect --format="{{.NetworkSettings.IPAddress}}" "$DOCKER_CONTAINER_ID")

		echo "Waiting for MariaDB initialisation ..."
		if ! apps/files_external/tests/env/wait-for-connection $DATABASEHOST 3306 60; then
			echo "[ERROR] Waited 60 seconds, no response" >&2
			exit 1
		fi

		echo "MariaDB is up."

	else
		if [ "MariaDB" != "$(mysql --version | grep -o MariaDB)" ] ; then
			echo "Your mysql binary is not provided by MariaDB"
			echo "To use the docker container set the USEDOCKER environment variable"
			exit -1
		fi
		mysql -u "$DATABASEUSER" -powncloud -e "DROP DATABASE IF EXISTS $DATABASENAME" -h $DATABASEHOST || true
	fi

	#Reset _DB to mysql since that is what we use internally
	_DB="mysql"
fi
if [ "$DATABASE" == "pgsql" ] ; then
	if [ ! -z "$USEDOCKER" ] ; then
		echo "Fire up the postgres docker"
		DOCKER_CONTAINER_ID=$(docker run -e POSTGRES_USER="$DATABASEUSER" -e POSTGRES_PASSWORD=owncloud -d postgres)
		DATABASEHOST=$(docker inspect --format="{{.NetworkSettings.IPAddress}}" "$DOCKER_CONTAINER_ID")

		echo "Waiting for Postgres initialisation ..."

		# grep exits on the first match and then the script continues
		docker logs -f "$DOCKER_CONTAINER_ID" 2>&1 | grep -q "database system is ready to accept connections"

		echo "Postgres is up."
	else
		dropdb -U "$DATABASEUSER" "$DATABASENAME" || true
	fi
fi
if [ "$DATABASE" == "oci" ] ; then
	echo "Fire up the oracle docker"
	DOCKER_CONTAINER_ID=$(docker run -d deepdiver/docker-oracle-xe-11g)
	DATABASEHOST=$(docker inspect --format="{{.NetworkSettings.IPAddress}}" "$DOCKER_CONTAINER_ID")

	echo "Waiting for Oracle initialization ... "

	# Try to connect to the OCI host via sqlplus to ensure that the connection is already running
        for i in {1..48}
            do
                    if sqlplus "system/oracle@(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(Host=$DATABASEHOST)(Port=1521))(CONNECT_DATA=(SID=XE)))" < /dev/null | grep 'Connected to'; then
                            break;
                    fi
                    sleep 5
            done

	DATABASEUSER=autotest
	DATABASENAME='XE'
fi


rm -rf $DATADIR
mkdir $DATADIR
cd $DATADIR

# install from version
echo "Installing $FROM to $DATADIR"
tar -xjf $BASEDIR/$FROM
cd owncloud
mkdir data

# installation
./occ maintenance:install -vvv --database="$_DB" --database-name="$DATABASENAME" --database-host="$DATABASEHOST" --database-user="$DATABASEUSER" --database-pass=owncloud --database-table-prefix=oc_ --admin-user="$ADMINLOGIN" --admin-pass=admin

#if [ -f console.php ]; then
#  # install test data
#  mkdir -p data/admin/files
#  cd data/admin/files
#  git clone git@github.com:owncloud/test-data.git
#
#  # scan the files
#  cd $DATADIR/owncloud
#  php -f console.php files:scan --all
#else
#  echo "[FAILED] ownCloud console not available."
#fi

# fire up the cron scheduler
echo "Running the cron scheduler ..."
cd $DATADIR/owncloud
php -f cron.php
php -f cron.php
echo "Done."

echo $GIT_BRANCH
# remove apps when using git
if [ -v GIT_BRANCH ]; then
	./occ app:disable activity
	./occ app:disable configreport
	./occ app:disable files_pdfviewer
	./occ app:disable files_texteditor
	./occ app:disable files_videoplayer
	./occ app:disable firstrunwizard
	./occ app:disable gallery
	./occ app:disable notifications
	./occ app:disable templateeditor
fi

# cleanup old code
ls | grep -v data | grep -v config | xargs rm -rf

cd $DATADIR

# install to version
echo "Installing $TO to $DATADIR"

tar -xjf $BASEDIR/$TO
cd owncloud

# UPGRADE
echo "Start upgrading from $FROM to $TO"
./occ upgrade

if [ -d tests ]; then
  cd tests
  ../lib/composer/bin/phpunit --configuration phpunit-autotest.xml --log-junit "autotest-results-$DATABASE.xml"

#  make clean-test-integration
#  make test-integration OC_TEST_ALT_HOME=1
fi

echo "done."


