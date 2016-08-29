#! /bin/bash
#
# see http://openbuildservice.org/help/manuals/obs-best-practices/cha.obs.best-practices.bootstrapping.html
#

test -z "$OBS_API_DST"  && OBS_API_DST=obs-new
test -z "$OBS_API_SRC"  && OBS_API_SRC=obs-old
test -z "$OBS_USER_DST" && OBS_USER_DST=$(osc -A$OBS_API_DST whois | awk -F: '{ print $1 }')

echo "Using: env OBS_API_SRC=$OBS_API_SRC OBS_API_DST=$OBS_API_DST OBS_USER_DST=$OBS_USER_DST"

if [ -z "$1" ]; then
  echo "Projects on $OBS_API_SRC:"
  echo "-------------------------"
  osc -A$OBS_API_SRC ls
  echo ""
  echo "To copy a project from $OBS_API_SRC to OBS_API_DST try "
  echo "\t $0 PROJECT_NAME ..."
  exit 0
fi

echo press ENTER to continue
read a

set -x
for prj in "$@"; do
  if [ -z "$(osc -A$OBS_API_DST meta prj $prj)" ]; then
    echo "creating $prj at $OBS_API_DST ..."
    # remove all users, add myself as maintainer
    osc -A$OBS_API_SRC meta prj $prj | grep -v userid= | sed -e 's@</project>@<person userid="'$my_id'" role="maintainer"/></project>@' | osc -A$OBS_API_DST meta prj $prj -F -
    # also copy prjconf
    osc -A$OBS_API_SRC meta prjconf $prj | osc -A$OBS_API_DST meta prjconf $prj -F -
  fi
  echo "copying project $prj ..."
  pkgs=$(osc -A$OBS_API_SRC ls $prj)
  npkgs=$(echo $pkgs | wc -w)
  counter=0
  for pkg in $pkgs; do
    counter=$(expr $counter + 1)
    echo "$prj: $counter/npkgs ..."
    osc -A$OBS_API_SRC copypac -t $OBS_API_DST $prj $pkg $prj || exit 1
  done
done

