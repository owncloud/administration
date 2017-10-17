#! /bin/sh
#
# Link a project to another project using aggreates. This is prefered over <link project="other...">
# as linked packages need to be recompiled from source before they can show up.
# https://en.opensuse.org/openSUSE:Build_Service_Concept_project_linking#Publish_Behaviour
#
# Usage:
#     obs-aggregate-prj.sh isv:ownCloud:daily:owncloud-client:2.3 isv:ownCloud:community:nightly
#

srcprj=$1
dstprj=$2
osc="osc -Aobs $OSC_OPT"

if [ "$dstprj" = '' ]; then
	echo "Usage:"
	echo "\t $0 source-project dest-project"
	echo "\n\nExample:"
	echo "\t $0 isv:ownCloud:daily:owncloud-client:2.3 isv:ownCloud:community:nightly"
	echo "\nParameters to osc can be specified"
	echo "through the environment variable OSC_OPT"
	exit 1
fi

pkgs=$($osc ls $srcprj)
$osc meta prj     $srcprj | sed -e "s@<project name=.*@<project name=\"$dstprj\">@" > /tmp/prj.$$
(set -x; $osc meta prj     -F /tmp/prj.$$     $dstprj)
rm -f /tmp/prj.$$ 

for pkg in $pkgs; do
  (set -x ; $osc aggregatepac $srcprj $pkg $dstprj $pkg)
done
