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

if [[ $TO_VERSION == git* ]]; then
  GIT_BRANCH=`echo $TO_VERSION | cut -c 5-`
  TO=$GIT_BRANCH.tar.bz2
  if [ ! -f $TO ]; then
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
fi

DATADIR=$BASEDIR/$FROM_VERSION-$TO_VERSION-$DATABASE

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


# database cleanup
if [ "$DATABASE" == "mysql" ] ; then
	mysql -u $DATABASEUSER -powncloud -e "DROP DATABASE $DATABASENAME"
fi
if [ "$DATABASE" == "pgsql" ] ; then
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

# installation
./occ maintenance:install -vvv --admin-pass=admin

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
  ../lib/composer/bin/phpunit --configuration phpunit-autotest.xml

#  make clean-test-integration
#  make test-integration OC_TEST_ALT_HOME=1
fi

echo "done."


