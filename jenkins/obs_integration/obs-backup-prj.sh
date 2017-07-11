#! /bin/sh
#
# Do this before or after you update the project.
#
# Algorithm:
#     When backing up an old version of e.g. isv:ownCloud:desktop we need to find the timestamp and revision
#     corresponding to a given version of owncloud-client.  We backup this revision and the respective
#     revision of all other packages in the same project that existed at the same timestamp.
#
# Usage:
#     obs-backup-prj.sh isv:ownCloud:desktop isv:ownCloud:desktop:client-2.3.1 owncloud-client 2.3.1

srcprj=$1
dstprj=$2
refpkg=$3
refver=$4
osc='osc -Aobs'

if [ "$refver" = '' ]; then
	echo "Usage:"
	echo "\t $0 source-project dest-project reference-package-name reference-version-number"
	echo "\n\nExample:"
	echo "\t $0 isv:ownCloud:desktop isv:ownCloud:desktop:client-2.3.1 owncloud-client 2.3.1"
        echo "\nFirst the timestamp of the release is determined and printed."
        echo "Then, the user is asked to press ENTER to start the copying process."
	exit 1
fi

refline=$($osc log $srcprj $refpkg | grep "| $refver |" | head -1)
refrevision=$(echo $refline | cut -f 1 -d '|' | sed -e 's@\s@@')
refdate=$(echo $refline | cut -f 3 -d '|' | sed -e 's@^\s@@' -e 's@\s$@@')
reftstamp=$(date -d "$refdate" +%s)

echo "Version $refver of package $refpkg was last updated:"
echo $refline
echo "\nPress ENTER to start copying into $dstprj ..."
read a

pkgs=$($osc ls $srcprj)
$osc meta prj     $srcprj | sed -e "s@<project name=.*@<project name=\"$dstprj\">@" > /tmp/prj.$$
$osc meta prjconf $srcprj > /tmp/prjconf.$$
(set -x; $osc meta prj     -F /tmp/prj.$$     $dstprj)
(set -x; $osc meta prjconf -F /tmp/prjconf.$$ $dstprj)
rm -f /tmp/prj.$$ /tmp/prjconf.$$

for pkg in $pkgs; do
  $osc log $srcprj $pkg | grep -A 1 -- '-----------------'  | grep ' | ' | while read line; do
    revision=$(echo $line | cut -f 1 -d '|' | sed -e 's@\s@@')
    datestring=$(echo $line | cut -f 3 -d '|' | sed -e 's@^\s@@' -e 's@\s$@@')
    tstamp=$(date -d "$datestring" +%s)
    if [ "$tstamp" -le "$reftstamp" ]; then
      # echo "$pkg: $revision $tstamp $datestring"
      (set -x ; $osc copypac -$revision $srcprj $pkg $dstprj $pkg)
      break
    fi
  done
done
