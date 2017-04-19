sh prepare_tarball.sh owncloud-client/owncloudclient-2.3.2git.tar.bz2 customer-themes/testpilotcloud.tar.xz tmplvars.sh
sh fetch_prjconf_vars.sh isv:ownCloud:devel:Qt562 >> tmplvars.sh
echo "BUILD_NUMBER=\"${BUILD_NUMBER}\"" >> tmplvars.sh
. ./tmplvars
sh prepare_package.sh ../templates/client/v$BASEVERSION out tmplvars.sh

