#! /bin/sh
#

obsprj=$1	# e.g. isv:ownCloud:devel:Qt562

osc=$OSC_CMD
test -z "$OSC_CMD" && osc=osc	# for env OSC_CMD="osc -A..."

$osc meta prjconf $obsprj | grep '^%define ' | sed -e 's/^%define\s*//' -e 's/\s\s*/="/' -e 's/$/"/'


