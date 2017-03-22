#! /bin/sh
#
# Do this before you update the project. 

srcprj=$1
dstprj=$2
osc='osc -Aobs'

pkgs=$($osc ls $srcprj)
$osc meta prj     $srcprj | sed -e "s@<project name=.*@<project name=\"$dstprj\">@" > /tmp/prj.$$
$osc meta prjconf $srcprj > /tmp/prjconf.$$
set -x
$osc meta prj     -F /tmp/prj.$$     $dstprj
$osc meta prjconf -F /tmp/prjconf.$$ $dstprj
rm -f /tmp/prj.$$ /tmp/prjconf.$$

for pkg in $pkgs; do
  $osc copypac $srcprj $pkg $dstprj $pkg
done
