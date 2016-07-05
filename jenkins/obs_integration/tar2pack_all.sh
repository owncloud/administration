#!/bin/bash
#
# Yet another script to do packaging.
# lessons lerned: 
#  - unroll everything for easier maintenance.
#  - there is always some manual changes in the templates. better run with echo=echo and do copy-pasta
#  - always push into :testing, and if its a final then add a pull request
#
# 2016-07-04, jw@owncloud.com

co_dir_obs=$HOME/src/obs
co_dir_s2=$HOME/src/obs/s2

tar2pack=$HOME/obs_integration/tar2pack.py

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

for vers in $*; do

  case $vers in 
  *RC*|*BETA*|*rc*|*beta*) testing=testing ;;
  *) testing=;;
  esac

  case $vers in
  # 9.1*) majmin=9.1 ;;

  # 9.0*) majmin=9.0 ;;

  # 8.2*) majmin=8.2 ;;

  8.1*) majmin=8.1

    $echo cd $co_dir_s2/ee:$majmin:testing/owncloud-enterprise
    $echo osc up
    $echo $tar2pack -O . http://$user:$pass@download.owncloud.com/internal/$vers/owncloud-enterprise-complete-$vers.tar.bz2 -d SOURCE_TAR_TOP_DIR=owncloud
    $echo wget https://doc.owncloud.org/server/8.1/ownCloud_Server_Administration_Manual.pdf
    $echo osc addremove
    $echo osc ci
    test -z "$testing" && $echo osc submitpac --no-cleanup ee:$majmin owncloud-enterprise

    $echo cd $co_dir_obs/isv:ownCloud:community:$majmin:testing/owncloud
    $echo osc up
    $echo $tar2pack -O . http://download.owncloud.org/community/$testing/owncloud-$vers.tar.bz2
    $echo osc addremove
    $echo osc ci
    test -z "$testing" && $echo osc submitpac --no-cleanup isv:ownCloud:community:$majmin owncloud-enterprise
  ;;

  8.0*) majmin=8.0

    $echo cd $co_dir_s2/ee:$majmin:testing/owncloud-enterprise
    $echo osc up
    $echo $tar2pack -O . http://$user:$pass@download.owncloud.com/internal/$vers/owncloud-enterprise-$vers.tar.bz2 -d SOURCE_TAR_TOP_DIR=owncloud
    $echo osc addremove
    $echo osc ci
    test -z "$testing" && $echo osc submitpac --no-cleanup ee:$majmin owncloud-enterprise

    $echo cd $co_dir_obs/isv:ownCloud:community:$majmin:testing/owncloud
    $echo osc up
    $echo $tar2pack -O . http://download.owncloud.org/community/$testing/owncloud-$vers.tar.bz2
    $echo osc addremove
    $echo osc ci
    test -z "$testing" && $echo osc submitpac --no-cleanup isv:ownCloud:community:$majmin owncloud-enterprise
  ;;

  esac

  if [ -z "$majmin" ]; then
    echo "unknown maj.min in $vers, please add."
    exit 0
  fi

done

if [ -z "$testing" ]; then
  echo "new pull requests:"
  osc rq list isv:ownCloud:community -s new,review
  osc -As2 rq list -s new,review
  echo "Please accept the pull request to build non-testing packages."
  echo "Caution: at openSUSE obs, you may want to disable publishing first.
fi

echo "ssh root@s2"
echo "# and do bin/publishee ...; bin/publish_ce ... eventually."
