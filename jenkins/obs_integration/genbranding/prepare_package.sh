#!/bin/sh
#
# refactored from genbranding.pl
# (c) 2017 jw@owncloud.com
# 
# Usage: themed-client.tar.gz template-dir
#
themedclienttar=$1
templatedir=$2

if [ -z "$templatedir" ]; then
  echo "Usage:"
  echo "$0 templatebasedir bash-file-with-template-variables"
  echo ""
  echo "Typical usage together witrh prepare_tarball.sh:"
  echo ""
  echo "sh prepare_tarball.sh owncloudclient-2.3.2git.tar.bz2 testpilotcloud.tar.xz tmpl-vars.sh"
  echo "source tmpl-vars.sh"
  echo "sh $0 templates/client/v\$baseversion tmpl-vars.sh"
  echo ""
  echo "generates subdirectries with package sources according to all"
  echo "subdirectories found under the given template basedirectory."
  echo ""
  echo "'APPLICATION_SHORTNAME' and other all uppercased keywords are substituted "
  echo "according to the variables found in brandvars.sh"
fi


