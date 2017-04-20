sh prepare_tarball.sh testdata/owncloudclient-2.3.2git.tar.bz2 testdata/customer-themes/testpilotcloud.tar.xz testdata/tp_tmplvars.sh
sh fetch_prjconf_vars.sh isv:ownCloud:devel:Qt562 >> testdata/tp_tmplvars.sh
BUILD_NUMBER=666
echo "BUILD_NUMBER=\"${BUILD_NUMBER}\"" >> testdata/tp_tmplvars.sh
echo "PACKAGE_NAME_PREFIX=\"oc\"" >> testdata/tp_tmplvars.sh
. testdata/tp_tmplvars.sh
sh prepare_package.sh ../templates/client/v$BASEVERSION out testdata/tp_tmplvars.sh
