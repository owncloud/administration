#! /bin/sh
#
# calling osc getbinaries to pull built packages from a build project

obs_proj=$1
out_dir=$2
test -z "$out_dir" && out_dir=.

osc_cmd="osc"

echo $obs_proj
pkg_list=$($osc_cmd ls $obs_proj)

for pkg in $pkg_list; do
  $osc_cmd r $obs_proj $pkg | while read -r line
  do
    set $line
    target=$1
    arch=$2
    echo pkg=$pkg, target=4target, arch=$arch
  done
done
