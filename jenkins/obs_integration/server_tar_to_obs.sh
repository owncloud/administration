#!/bin/bash -x
#
# server_tar_to_obs.sh
#
# wrapper for obs-new-tar.py to push new tar verstions
# into internal and external build service.
# This is a version of the initial script called update_all_tar.sh that
# is mainly to be used out of jenkins. That is why it reads its parameter
# from the environment.
#
########### The following variables should be set outside of this script:
# PREREL: a suffix like rc1 or beta1
# VERSIONS: A space separated list of versions.
# USERNAME: The person who changed it
# INT_URL_WITH_CREDS: Internal url to download packages with credentials
#                     something like http://owncloud:secret@download.owncloud.com
# SUFFIX_REPO: Repository suffix, usually testing, but can be devel 
#
prerel="${PREREL:-}"
username="${USERNAME:-jenkins@owncloud.com}"

# version string like this: versions="7.0.10   8.0.8   8.1.3"
if [ -z "$VERSIONS" ]; then
    echo "ERROR: Required parameter 'VERSIONS' is empty. Nothing to do."
    exit 1
fi

# cmd="../../obs-new-tar.py -e $username "
cmd="../../obs-new-tar.py --commit -e $username "
submitreq=0	# switch to 1, to also create submitrequests from $prj$prjsuffix to $prj
test -z "$prerel"  && submitreq=1

########### End edit section

# compute the download mirror path
if [ -z "$prerel" ]; then
  d_o_o_path=community		# final tars are there.
else
  d_o_o_path=community/testing	# beta and RC tas are there.
fi
d_o_c_path=internal		# beta,rc,final tars are all ther.

prjsuffix=${SUFFIX_REPO:-testing}

osc="osc -c ~/.oscrc"
# build.opensuse.org
echo "do_d_o_o='$cmd http://download.owncloud.org'"
do_d_o_o="$cmd http://download.owncloud.org"
for v in $VERSIONS; do
  case $v in
  6*)
    prj=isv:ownCloud:community:6.0
    ;;
  7*)
    prj=isv:ownCloud:community:7.0
    ;;
  8.0*)
    prj=isv:ownCloud:community:8.0
    ;;
  8.1*)
    prj=isv:ownCloud:community:8.1
    ;;
  8.2*)
    prj=isv:ownCloud:community:8.2
    ;;
  esac
  for name in owncloud; do
    # Clean the package name to be debian compatible
    pkg=$(echo $name | tr _ -)

    # checkout or upate the obs checkout
    if [ -d "$prj:$prjsuffix" ]; then
      pushd "$prj:$prjsuffix/$pkg"
      $osc up
    else
      # no checkout dir, do new checkout
      $osc co $prj:$prjsuffix $pkg
      pushd $prj:$prjsuffix/$pkg
    fi

    $do_d_o_o/$d_o_o_path/$name-$v$prerel.tar.bz2
    test $submitreq -ne 0 && echo "sleep 10; osc submitreq $prj"
    popd
  done
done

echo "==> Community package done."
#s2.owncloud.com

# internal url with credentials: http://user:secret@download.owncloud.com
# Set this through environment: $INT_URL_WITH_CREDS
if [ -z "$INT_URL_WITH_CREDS" ]; then
    echo "Bad download url for internal source archives."
    exit 1
fi

do_d_o_c='$cmd $INT_URL_WITH_CREDS'
osc="osc -c ~/.ocoscrc"

# export an environment parameter to point osc to the correct profile
# for the internal buildservice.
export OSCPARAM="-c ~/.ocoscrc"

for v in $VERSIONS; do
  case $v in
  6*)
    names="owncloud_enterprise owncloud_enterprise_3rdparty owncloud_enterprise_apps owncloud_enterprise_core owncloud_enterprise_unsupported"
    prj=ee:6.0
    manual=""
    ;;
  7*)
    names="owncloud_enterprise owncloud_enterprise_3rdparty owncloud_enterprise_apps owncloud_enterprise_core owncloud_enterprise_unsupported"
    prj=ee:7.0
    manual=""
    ;;
  8.0*)
    manual="ownCloud_Server_Administration_Manual.pdf"
    manual_sub="8.0"
    names="owncloud_enterprise"
    prj=ee:8.0
    ;;
  8.1*)
    manual="ownCloud_Server_Administration_Manual.pdf"
    manual_sub="8.1"
    names="owncloud_enterprise"
    prj=ee:8.1
    ;;
  8.2*)
    manual_sub="8.2"
    manual="ownCloud_Server_Administration_Manual.pdf"
    names="owncloud_enterprise"
    prj=ee:8.2
    ;;
  esac
  for name in $names; do
    pkg=$(echo $name | tr _ -)
    $osc co $prj:$prjsuffix $pkg
    pushd $prj:$prjsuffix/$pkg
    test -n "$manual" && wget -nv https://doc.owncloud.org/server/$manual_sub/$manual -O $manual

    # download the fil
    eval "$do_d_o_c/$d_o_c_path/$v$prerel/$name-$v$prerel.tar.bz2"
    test $submitreq -ne 0 && echo "sleep 10; osc submitreq $prj"
    popd
  done
done
