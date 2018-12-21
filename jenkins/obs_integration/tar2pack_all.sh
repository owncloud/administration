#!/bin/bash
#
# Yet another script to do packaging.
# lessons lerned: 
#  - unroll everything for easier maintenance.
#  - there is always some manual changes in the templates. better run with echo=echo and do copy-pasta
#  - always push into :testing, and if its a final then add a pull request
#  - do not leave any decisions to the user. Nobody can remember e.g. when to use the enterprise-complete tar and when not.
#
# CAUTION: Keep in sync with https://rotor.int.owncloud.com/job/owncloud-server-nightly
#  - there package owncloud is prepared with tar2pack.py in a code snippet similar to the usage here.
#  - there package owncloud-files with buildpackage.pl, but should be obsoleted by another call to tar2pack.py
#
# 2016-07-04, jw@owncloud.com
# 2016-07-26, jw@owncloud.com - imported code snippet for nightly. untested.
# 2016-08-21, jw@owncloud.com - use -E to avoid pushing to the wrong package / project.


co_dir_obs=$HOME/src/obs
co_dir_s2=$HOME/src/obs/s2

tar2pack=$HOME/obs_integration/tar2pack.py

test -n "$CO_DIR_OBS_EXT" && co_dir_obs="$CO_DIR_OBS_EXT"
test -n "$CO_DIR_OBS_INT" && co_dir_s2="$CO_DIR_OBS_INT"
test -n "$TAR2PACK"       && tar2pack="$TAR2PACK"

logfile=/tmp/tar2pack_all.$$.log
dl_list=/tmp/tar2pack_all.$$.lst

echo=
echo=echo	# use for preview only

if [ -z "$user" ]; then 
  echo "run with user=.... $0"
  exit 0;
fi

if [ -z "$pass" ]; then 
  echo "run with pass=.... $0"
  exit 0;
fi

if [ -z "$1" ]; then
  echo "run with at least one version number. e.g. '8.1.9RC2'"
  exit 0;
fi

:> $logfile

for vers in $*; do

  case $vers in 
  *RC*|*BETA*|*rc*|*beta*) testing=testing ;;
  *) testing=;;
  esac

  msg="Update to $vers"
  test -n "$echo" && msg="'$msg'"
  test -n "$echo" && echo "# - - - - - - - - - - -  $vers  - - - - - - - - - - -"

  case $vers in
  daily|nightly)
    test -n "$echo" && { echo "echo mode ignored for nighly, executing in 5 sec..."; sleep 5; }
    # Imported code from https://rotor.int.owncloud.com/job/owncloud-server-nightly/configure
    # TODO
    cd $co_dir_s2/ce:nightly/owncloud-files
    osc up
    download=owncloud-daily-master.tar.bz2
    wget --server-response --progress=dot http://download.owncloud.org/community/$download
    ##extract correct version
    tarversion=$(tar xvf $download owncloud/version.php -O | grep 'OC_Version =')
    tarversionstring=$(tar xvf $download owncloud/version.php -O | grep 'OC_VersionString')
    echo "Version in $download: $tarversion"
    # version=$(echo $tarversion | sed -e 's@.*(\([0-9][0-9]*\),\([0-9][0-9]*\).*@\1.\2@')
    version=$(echo $tarversionstring | sed -e "s@';.*@@" -e "s@.*'@@" -e 's@ @@g')
    vers=${version}.$(date +%Y%m%d)
    ##rename to a speaking name
    newname=owncloud-${version_date}.tar.bz2
    mv $download $newname
    $tar2pack -O . -E ce:nightly/owncloud-files $newname -d VERSION=$vers -d SOURCE_TAR_TOP_DIR=owncloud
    osc addremove
    osc ci -m "$msg" --noservice
    echo >> $logfile "$vers community	https://obs.int.owncloud.com/package/show/ce:nightly/owncloud-files"
    echo >> $dl_list "$vers community	http://obs.int.owncloud.com:83/ce:nightly"

    cd $co_dir_s2/ce:nightly/owncloud
    osc up
    $tar2pack -O . -E ce:nightly/owncloud -d VERSION=$vers owncloud-empty.tar.bz2
    osc addremove
    osc ci -m "$msg" --noservice
    echo >> $logfile "$vers          	https://obs.int.owncloud.com/package/show/ce:nightly/owncloud"
    ;;
    
 10.*) majmin=${vers%.*}

    $echo cd $co_dir_s2/ee:$majmin:testing/owncloud-enterprise-files
    $echo osc up
    $echo $tar2pack -O . -E ee:$majmin:testing/owncloud-enterprise-files \'http://$user:$pass@download.owncloud.com/internal/$vers/owncloud-enterprise-complete-$vers.tar.bz2\' -d SOURCE_TAR_TOP_DIR=owncloud
    $echo osc addremove
    $echo osc ci -m "$msg" --noservice
    test -z "$testing" && echo y | $echo EDITOR="sed -i -e 's/$/ /'" osc submitpac --yes --no-cleanup ee:$majmin owncloud-enterprise-files
    echo >> $logfile "$vers enterprise	https://obs.int.owncloud.com/package/show/ee:$majmin:testing/owncloud-enterprise-files"
    echo >> $dl_list "$vers enterprise	http://obs.int.owncloud.com:83/ee:$majmin:testing"

    $echo cd $co_dir_s2/ce:$majmin:testing/owncloud-files
    $echo osc up
    $echo $tar2pack -O . -E ce:$majmin:testing/owncloud-files http://download.owncloud.org/community/$testing/owncloud-$vers.tar.bz2
    $echo osc addremove
    $echo osc ci -m "$msg" --noservice
    test -z "$testing" && echo y | $echo EDITOR="sed -i -e 's/$/ /'" osc submitpac --yes --no-cleanup ce:$majmin owncloud-files
    echo >> $dl_list "$vers community 	http://obs.int.owncloud.com:83/ce:$majmin:testing"
    echo >> $logfile "$vers community	https://obs.int.owncloud.com/package/show/ce:$majmin:testing/owncloud-files"
    ;;
  esac

  if [ -z "$majmin" ]; then
    echo "unknown maj.min in $vers, please add."
    exit 0
  fi

done

echo
echo "Packages pushed into the build services:"
cat $logfile | sed -e 's@^@  @'
rm -f $logfile
echo

if [ -z "$testing" ]; then
  echo "New pull requests:"
  $echo cd /tmp
  $echo osc -Ahttps://api.opensuse.org rq list isv:ownCloud:community:8.1 -s new,review
  $echo osc -Ahttps://api.opensuse.org rq list isv:ownCloud:community:8.0 -s new,review
  $echo osc -Ahttps://obs.int.owncloud.com rq list -s new,review
  echo "Please accept the pull request to build non-testing packages."
  echo "Caution: at openSUSE obs, you may want to disable publishing first."
fi

echo "Download build results from:"
cat $dl_list | sed -e 's@^@  @'
rm -f $dl_list
echo

echo "ssh root@obs.int"
echo "# and do bin/publishee ...; bin/publish_ce ... eventually"
if [ -z "$testing" ]; then
  echo "# ... check https://download.owncloud.org/download/repositories/stable/owncloud/"
else
  echo "# ... check https://download.owncloud.org/download/repositories/testing/owncloud/"
fi
echo

echo "ssh monkey"
if [ -z "$testing" ]; then
  echo "# bash src/github/owncloud/enterprise/appliance/obfuscation/ZendGuard-7.0.0/obfuscate_apps-9.sh ee:9.1"
else
  echo "# bash src/github/owncloud/enterprise/appliance/obfuscation/ZendGuard-7.0.0/obfuscate_apps-9.sh ee:9.1:testing"
fi

