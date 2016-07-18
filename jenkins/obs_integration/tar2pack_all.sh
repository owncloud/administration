#!/bin/bash
#
# Yet another script to do packaging.
# lessons lerned: 
#  - unroll everything for easier maintenance.
#  - there is always some manual changes in the templates. better run with echo=echo and do copy-pasta
#  - always push into :testing, and if its a final then add a pull request
#  - do not leave any decisions to the user. Nobody can remember e.g. when to use the enterprise-complete tar and when not.
#
# 2016-07-04, jw@owncloud.com

co_dir_obs=$HOME/src/obs
co_dir_s2=$HOME/src/obs/s2

tar2pack=$HOME/obs_integration/tar2pack.py
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
  9.1*) majmin=9.1

    $echo cd $co_dir_s2/ee:$majmin:testing/owncloud-enterprise-files
    $echo osc up
    $echo $tar2pack -O . http://$user:$pass@download.owncloud.com/internal/$vers/owncloud-enterprise-complete-$vers.tar.bz2 -d SOURCE_TAR_TOP_DIR=owncloud
    $echo osc addremove
    $echo osc ci -m "$msg" --noservice
    test -z "$testing" && $echo osc submitpac --no-cleanup ee:$majmin owncloud-enterprise-files
    echo >> $logfile "$vers enterprise	https://obs.int.owncloud.com/package/show/ee:$majmin:testing/owncloud-enterprise-files"
    echo >> $dl_list "$vers enterprise	http://obs.int.owncloud.com:83/ee:$majmin:testing"

    $echo cd $co_dir_s2/ee:$majmin:testing/owncloud-enterprise
    $echo osc up
    $echo $tar2pack -O . -d VERSION=$vers owncloud-empty.tar.bz2
    $echo osc addremove
    $echo osc ci -m "$msg" --noservice
    test -z "$testing" && $echo osc submitpac --no-cleanup ee:$majmin owncloud-enterprise
    echo >> $logfile "               	https://obs.int.owncloud.com/package/show/ee:$majmin:testing/owncloud-enterprise"
    echo >> $dl_list "                	http://obs.int.owncloud.com:83/ee:$majmin:testing"

    $echo cd $co_dir_s2/ce:$majmin:testing/owncloud-files
    $echo osc up
    $echo $tar2pack -O . http://download.owncloud.org/community/$testing/owncloud-$vers.tar.bz2
    $echo osc addremove
    $echo osc ci -m "$msg" --noservice
    test -z "$testing" && $echo osc submitpac --no-cleanup ce:$majmin owncloud-files
    echo >> $dl_list "$vers community 	http://obs.int.owncloud.com:83/ce:$majmin:testing"
    echo >> $logfile "$vers community	https://obs.int.owncloud.com/package/show/ce:$majmin:testing/owncloud-files"

    $echo cd $co_dir_s2/ce:$majmin:testing/owncloud
    $echo osc up
    $echo $tar2pack -O . -d VERSION=$vers owncloud-empty.tar.bz2
    $echo osc addremove
    $echo osc ci -m "$msg" --noservice
    test -z "$testing" && $echo osc submitpac --no-cleanup ce:$majmin owncloud
    echo >> $dl_list "                	http://obs.int.owncloud.com:83/ce:$majmin:testing"
    echo >> $logfile "               	https://obs.int.owncloud.com/package/show/ce:$majmin:testing/owncloud"
  ;;

  9.0*) majmin=9.0

    $echo cd $co_dir_s2/ee:$majmin:testing/owncloud-enterprise-files
    $echo osc up
    $echo $tar2pack -O . http://$user:$pass@download.owncloud.com/internal/$vers/owncloud-enterprise-complete-$vers.tar.bz2 -d SOURCE_TAR_TOP_DIR=owncloud
    $echo osc addremove
    $echo osc ci -m "$msg" --noservice
    test -z "$testing" && $echo osc submitpac --no-cleanup ee:$majmin owncloud-enterprise-files
    echo >> $dl_list "$vers enterprise	http://obs.int.owncloud.com:83/ee:$majmin:testing"
    echo >> $logfile "$vers enterprise	https://obs.int.owncloud.com/package/show/ee:$majmin:testing/owncloud-enterprise-files"

    $echo cd $co_dir_s2/ee:$majmin:testing/owncloud-enterprise
    $echo osc up
    $echo $tar2pack -O . -d VERSION=$vers owncloud-empty.tar.bz2
    $echo osc addremove
    $echo osc ci -m "$msg" --noservice
    test -z "$testing" && $echo osc submitpac --no-cleanup ee:$majmin owncloud-enterprise
    echo >> $dl_list "                	http://obs.int.owncloud.com:83/ee:$majmin:testing"
    echo >> $logfile "               	https://obs.int.owncloud.com/package/show/ee:$majmin:testing/owncloud-enterprise"

    $echo cd $co_dir_s2/ce:$majmin:testing/owncloud-files
    $echo osc up
    $echo $tar2pack -O . http://download.owncloud.org/community/$testing/owncloud-$vers.tar.bz2
    $echo osc addremove
    $echo osc ci -m "$msg" --noservice
    test -z "$testing" && $echo osc submitpac --no-cleanup ce:$majmin owncloud-files
    echo >> $dl_list "$vers community 	http://obs.int.owncloud.com:83/ce:$majmin:testing"
    echo >> $logfile "$vers community	https://obs.int.owncloud.com/package/show/ce:$majmin:testing/owncloud-files"

    $echo cd $co_dir_s2/ce:$majmin:testing/owncloud
    $echo osc up
    $echo $tar2pack -O . -d VERSION=$vers owncloud-empty.tar.bz2
    $echo osc addremove
    $echo osc ci -m "$msg" --noservice
    test -z "$testing" && $echo osc submitpac --no-cleanup ce:$majmin owncloud
    echo >> $dl_list "                	http://obs.int.owncloud.com:83/ce:$majmin:testing"
    echo >> $logfile "               	https://obs.int.owncloud.com/package/show/ce:$majmin:testing/owncloud"
  ;;

  8.2*) majmin=8.2

    $echo cd $co_dir_s2/ee:$majmin:testing/owncloud-enterprise
    $echo osc up
    $echo $tar2pack -O . http://$user:$pass@download.owncloud.com/internal/$vers/owncloud-enterprise-$vers.tar.bz2 -d SOURCE_TAR_TOP_DIR=owncloud
    $echo wget https://doc.owncloud.org/server/8.2/ownCloud_Server_Administration_Manual.pdf
    $echo osc addremove
    $echo osc ci -m "$msg" --noservice
    echo >> $dl_list "$vers enterprise	http://obs.int.owncloud.com:83/ee:$majmin:testing"
    echo >> $logfile "$vers enterprise	https://obs.int.owncloud.com/package/show/ee:$majmin:testing/owncloud-enterprise"
    test -z "$testing" && $echo osc submitpac --no-cleanup ee:$majmin owncloud-enterprise

    $echo cd $co_dir_s2/ce:$majmin:testing/owncloud
    $echo osc up
    $echo $tar2pack -O . http://download.owncloud.org/community/$testing/owncloud-$vers.tar.bz2
    $echo osc addremove
    $echo osc ci -m "$msg" --noservice
    echo >> $dl_list "$vers community 	http://obs.int.owncloud.com:83/ce:$majmin:testing"
    echo >> $logfile "$vers community	https://obs.int.owncloud.com/package/show/ce:$majmin:testing/owncloud"
    test -z "$testing" && $echo osc submitpac --no-cleanup ce:$majmin owncloud
    test -n "$echo" && echo
  ;;

  8.1*) majmin=8.1

    $echo cd $co_dir_s2/ee:$majmin:testing/owncloud-enterprise
    $echo osc up
    $echo $tar2pack -O . http://$user:$pass@download.owncloud.com/internal/$vers/owncloud-enterprise-$vers.tar.bz2 -d SOURCE_TAR_TOP_DIR=owncloud
    $echo wget https://doc.owncloud.org/server/8.1/ownCloud_Server_Administration_Manual.pdf
    $echo osc addremove
    $echo osc ci -m "$msg" --noservice
    echo >> $dl_list "$vers enterprise	http://obs.int.owncloud.com:83/ee:$majmin:testing"
    echo >> $logfile "$vers enterprise	https://obs.int.owncloud.com/package/show/ee:$majmin:testing/owncloud-enterprise"
    test -z "$testing" && $echo osc submitpac --no-cleanup ee:$majmin owncloud-enterprise

    $echo cd $co_dir_obs/isv:ownCloud:community:$majmin:testing/owncloud
    $echo osc up
    $echo $tar2pack -O . http://download.owncloud.org/community/$testing/owncloud-$vers.tar.bz2
    $echo osc addremove
    $echo osc ci -m "$msg" --noservice
    echo >> $dl_list "$vers community 	http://software.opensuse.org/download.html?project=isv:ownCloud:community:$majmin:testing&package=owncloud"
    echo >> $logfile "$vers community	https://build.opensuse.org/package/show/isv:ownCloud:community:$majmin:testing/owncloud"
    test -z "$testing" && $echo osc submitpac --no-cleanup isv:ownCloud:community:$majmin owncloud
    test -n "$echo" && echo
  ;;

  8.0*) majmin=8.0

    $echo cd $co_dir_s2/ee:$majmin:testing/owncloud-enterprise
    $echo osc up
    $echo $tar2pack -O . http://$user:$pass@download.owncloud.com/internal/$vers/owncloud-enterprise-$vers.tar.bz2 -d SOURCE_TAR_TOP_DIR=owncloud
    $echo osc addremove
    $echo osc ci -m "$msg" --noservice
    echo >> $dl_list "$vers enterprise	http://obs.int.owncloud.com:83/ee:$majmin:testing"
    echo >> $logfile "$vers enterprise	https://obs.int.owncloud.com/package/show/ee:$majmin:testing/owncloud-enterprise"
    test -z "$testing" && $echo osc submitpac --no-cleanup ee:$majmin owncloud-enterprise

    $echo cd $co_dir_obs/isv:ownCloud:community:$majmin:testing/owncloud
    $echo osc up
    $echo $tar2pack -O . http://download.owncloud.org/community/$testing/owncloud-$vers.tar.bz2
    $echo osc addremove
    $echo osc ci -m "$msg" --noservice
    echo >> $dl_list "$vers community	http://software.opensuse.org/download.html?project=isv:ownCloud:community:$majmin:testing&package=owncloud"
    echo >> $logfile "$vers community	https://build.opensuse.org/package/show/isv:ownCloud:community:$majmin:testing/owncloud"
    test -z "$testing" && $echo osc submitpac --no-cleanup isv:ownCloud:community:$majmin owncloud-enterprise
    test -n "$echo" && echo
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
  osc rq list isv:ownCloud:community -s new,review
  osc -As2 rq list -s new,review
  echo "Please accept the pull request to build non-testing packages."
  echo "Caution: at openSUSE obs, you may want to disable publishing first."
fi

echo "Download build results from:"
cat $dl_list | sed -e 's@^@  @'
rm -f $dl_list
echo
echo "ssh root@s2"
echo "# and do bin/publishee ...; bin/publish_ce ... eventually"

