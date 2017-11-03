#! /bin/sh
#
# (c) 2017 jw@owncloud.com GPL-2.0 or ask.
#
# Copy all packages of one project to a new location.
# This command is missing from osc, probably because it is too complex 
# to get right.
# This implements a deepcopy, resolving all linkpac and aggregatepac.
#
# This script takes care of the following:
#  meta prj
#  meta prjconf
#  loop over copypac + meta pkg
# and worksaround all known OBS/osc bugs/limitations.

srcprj=$1
dstprj=$2
osc="osc $OSC_OPT"

if [ "$dstprj" = '' ]; then
	echo "Usage:"
	echo "\t env OSC_OPT=-Aint $0 source-project dest-project"
	exit 1
fi

# meta pkg returns false data across obs boundaries. e.g. <build> section is
# just silently missing.
# We have to query locally, what a hack!
srcprjm=$(echo $srcprj | sed -e 's/^openSUSE.org://')
oscm=$osc
test "$srcprj" != "$srcprjm" && oscm="$osc -Ahttps://api.opensuse.org"

# meta prj also returns "modified" data across obs boundaries. e.g. "<path project=..." elements get modified to contain the needed prefix for remote access.
# This is in our case a nice feature. But just as surprising and unexpected 
# as the missing build section with meta pkg.
$osc meta prj     $srcprj | sed -e "s@<project name=.*@<project name=\"$dstprj\">@" > /tmp/prj.$$
$osc meta prjconf $srcprj > /tmp/prjconf.$$
(set -x; $osc meta prj     -F /tmp/prj.$$     $dstprj)
(set -x; $osc meta prjconf -F /tmp/prjconf.$$ $dstprj)
rm -f /tmp/prj.$$ /tmp/prjconf.$$

saved_srcprj=$srcprj
saved_srcprjm=$srcprjm

pkgs=$($osc ls $srcprj)
# pkgs=ocqt562-filesystem
for pkg in $pkgs; do
  srcprj=$saved_srcprj
  srcprjm=$saved_srcprjm
  echo ""
  echo "================== $srcprj $pkg ==============="
  echo ""
  # --expand helps to make a copy from a linkpac (instead of a link)
  # but it does not help to expand aggregatepac
  is_aggregate=$($osc cat $srcprj $pkg _aggregate 2>/dev/null)
  while [ -n "$is_aggregate" ]; do
     aggpkg=$(echo $is_aggregate | sed -e 's@.*<package>@@' -e 's@</package>.*@@')
     aggprj=$(echo $is_aggregate | sed -e 's@.*project="\([^"]*\)".*@\1@')
     # BUG ALERT: contents of _aggregatepac is just false, when viewed remote. 
     # (copypac, cat makes no differenc) -- we patch that:
     test "$srcprj" != "$srcprjm" && aggprj="openSUSE.org:$aggprj"
     echo "\t $pkg is an aggregatepac from $aggprj $aggpkg"
     pkg=$aggpkg
     srcprj=$aggprj
     srcprjm=$(echo $srcprj | sed -e 's/^openSUSE.org://')
     is_aggregate=$($osc cat $srcprj $pkg _aggregate 2>/dev/null)
     test -n "$is_aggregate" && echo "\t $pkg needs another aggregate round ... "
  done
  (set -x ; $osc copypac --expand $srcprj $pkg $dstprj $pkg)
  (set -x ; $oscm meta pkg $srcprjm $pkg | sed -e 's/project=".*"//' | $osc meta pkg $dstprj $pkg -F -)
done

