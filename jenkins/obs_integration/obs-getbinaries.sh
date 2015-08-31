#! /bin/sh
#
# calling osc getbinaries to pull built packages from a build project

obs_prj=$1
out_dir=$2
test -z "$out_dir" && out_dir=.

osc_cmd="osc"

echo $obs_prj
pkg_list=$($osc_cmd ls $obs_prj)

for pkg in $pkg_list; do
  $osc_cmd r $obs_prj $pkg | while read -r line
  do
    set $line
    target=$1
    arch=$2
    echo pkg=$pkg, target=$target, arch=$arch
    out_ta=$out_dir/$target/$arch
    mkdir -p $out_ta
    $osc_cmd getbinaries $obs_prj $pkg $target $arch -d $out_ta
  done
done
