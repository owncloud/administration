#! /bin/bash
#
# This script checks the links in the project.
# It ignores links that remain in the same project.
# It reports all links pointing outside and gives recommendations how to resolve them. 

BRANCH=2.3
prj=isv:ownCloud:toolchains:mingw:win32:$BRANCH
test -z "$1" || prj=$1
test -z "$OBS_API" && OBS_API=https://api.opensuse.org

echo "... checking $OBS_API project $prj"

pkgs=$(osc -A$OBS_API ls $prj)

for pkg in $pkgs; do
  echo -n "\t$pkg ...                            \r"
  haslink=
  lin=$(osc -Aobs cat -u $prj $pkg _link 2>/dev/null) && haslink=true
  if [ "$haslink" = "true" ]; then
    if (echo "$lin" | grep -q '\bproject="'); then
      if (echo $lin | grep '\bproject="' | grep -q "project=\"isv"); then
        echo "\t$pkg: harmless local project link."
      else
        echo "ERROR: $pkg has link with remote project found: $lin"
      fi
    else
        echo "\t$pkg: harmless local link."
    fi
  fi
done
