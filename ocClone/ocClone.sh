#!/bin/sh

if [ "$1" = "--help" ] ; then
	echo "Usage: ./ocClone.sh [DOWNLOADURL] [CONFIGFILE]
	With a given DOWNLOADURL the new release will be downloaded and extracted.
	Set CONFIGFILE for a config file other than ./.ocClone.conf
	What the script does besides downloading and extracting:
	- The production database will be copied into a new test database
	- The production configuration config.php will be copied and adjusted
	"
	exit
fi


## Loading the configuration

if [ $2 ] ; then
	CONFIGFILE=$2
else
	CONFIGFILE="./.ocClone.conf"
fi
if [ -f "$CONFIGFILE" ] ; then
	. "$CONFIGFILE" || exit
else
	echo "Config file does not exist"
	exit
fi


## Download and extract next ownCloud release

OCURL=$1
if [ "$OCURL" ] ; then
	FILETYPE=`echo "$OCURL" | rev | cut -c-3 | rev`
	if [ "$FILETYPE" = "bz2" ] ; then
		EXT=".tar.bz2";
		DECOMP="tar -xf "
		DECOMPFOLDER="-C $DLBASENAME"
	elif [ "$FILETYPE" = "zip" ] ; then
		EXT=".zip";
		DECOMP="unzip"
		DECOMPFOLDER="-d $DLBASENAME"
	else
		echo "Unsupported download file"
		exit
	fi
	wget "$OCURL" -O "$DLBASENAME$EXT"
	if [ ! -d "$DLBASENAME" ] ; then
		mkdir "$DLBASENAME" || exit
	fi
	cd "$DLBASENAME"
	$DECOMP ../"$DLBASENAME$EXT"  || exit
	cd ..
	if [ -d "$BASETEST" ] ; then
		rsync -r --delete $DLBASENAME/owncloud/* $BASETEST/ || exit
	else
		mv $DLBASENAME/owncloud/ $BASETEST/ || exit
	fi
fi


## Copy and adjust config.php
echo "copying and adjusting config.php"
cp $BASEORIG/config/config.php $BASETEST/config/config.php || exit


if [ $DATATEST ] ; then
	sed -i "s;$DATAPROD;$DATATEST;g" $BASETEST/config/config.php || exit
fi

sed -i "s;'dbname' => '$DBPROD';'dbname' => '$DBTEST';g" $BASETEST/config/config.php || exit


## Copy and adjust Database
echo "Copying and adjusting Database"

$DBDUMPBIN -u "$DBUSR" -p"$DBPWD" "$DBPROD" > "$DBDUMPFILE" || exit

$DBBIN -u "$DBUSR" -p"$DBPWD" -e "DROP DATABASE $DBTEST" &&
$DBBIN -u "$DBUSR" -p"$DBPWD" -e "CREATE DATABASE $DBTEST /*!40100 DEFAULT CHARACTER SET utf8 */" &&
$DBBIN -u "$DBUSR" -p"$DBPWD" "$DBTEST" < $DBDUMPFILE || exit
if [ $MKADMIN ] ; then
	$DBBIN -u "$DBUSR" -p"$DBPWD" -e "insert into group_user (gid, uid) values ('admin', '$MKADMIN')" "$DBTEST"
fi

if [ $DOCHOWNUSER ] ; then
	echo "Adjusting owner"
	chown -R $DOCHOWNUSER:$DOCHOWNGROUP $BASETEST
fi


echo "Everything is done!"