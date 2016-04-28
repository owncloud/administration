#! /bin/sh
# 
# Requires:
# sudo apt-get install libdistro-info-perl
# sudo apt-get install osc

#wget http://security.ubuntu.com/ubuntu/pool/universe/q/qttools-opensource-src/qttools5-dev_5.5.1-3build1_amd64.deb

name=qttools5-dev
version=5.5.1
buildrel=3build1
arch=amd64

deb_in_pkg_name=${name}_${version}-${buildrel}_${arch}.deb
ar x $deb_in_pkg_name
tar xf control.tar.gz
rm -f control.tar.gz
rm -f debian-binary
xzcat < data.tar.xz | gzip > data.tar.gz
rm -f data.tar.xz
osc add data.tar.gz

if [ ! -f debian.$name.install ]; then
  tar tf data.tar.gz  | sed -e 's@^\./@@' -e 's@^/@@' > debian.$name.install
  osc add debian.$name.install
fi

if [ ! -f debian.changelog ]; then
  debchange -c debian.changelog --create --distribution stable  -v ${version}-${buildrel} --package $name "created with $0"
  osc add debian.changelog
fi

if [ ! -f debian.control ]; then
#  dpkg-deb -I $deb_in_pkg_name | sed -e 's@^ @@' -e 's@^ @       @' | sed -n -e '/^Package:/,$p' > debian.control
  echo "Source: $name" > debian.control
  grep '^Maintainer: ' < control >> debian.control
  grep '^Section: ' < control >> debian.control
  grep '^Priority: ' < control >> debian.control
  echo "" >> debian.control
  echo "Package: $name" >> debian.control

  grep -v '^Source: ' < control | grep -v '^Maintainer: ' | grep -v '^Original-Maintainer: ' | grep -v '^Installed-Size: ' | grep -v '^Package: ' | grep -v '^Version: ' >> debian.control
  osc add debian.control
fi

if [ ! -f $name.dsc ]; then
  echo "Format: 1.0" > $name.dsc
  echo                  >> $name.dsc "Source: $name"
  echo                  >> $name.dsc "Binary: $name"
  echo                  >> $name.dsc "Version: ${version}-${buildrel}"
  grep < debian.control >> $name.dsc "^Maintainer: "
  grep < debian.control >> $name.dsc "^Uploaders: "
  grep < debian.control >> $name.dsc "^Homepage: "
  grep < debian.control >> $name.dsc "^Architecture: "
  echo                  >> $name.dsc "Build-Depends: debhelper (>= 7)"
  echo                  >> $name.dsc "Standards-Version: 3.9.4"
  echo                  >> $name.dsc "# DEBTRANSFORM-RELEASE: 0"
  osc add $name.dsc
fi

if [ ! -f debian.compat ]; then
  echo 9 > debian.compat
  osc add debian.compat
fi

if [ ! -f debian.rules ]; then
  cat << EOF > debian.rules
#!/usr/bin/make -f
# -*- makefile -*-
export DH_VERBOSE=1
SHELL=/bin/bash

%:
	dh \$@

override_dh_auto_install:
	mkdir -p \$(CURDIR)/debian/tmp
	dh_auto_install -- INSTALL_ROOT=\$(CURDIR)/debian/tmp
	tar xf /usr/src/packages/SOURCES/data.tar.gz -C \$(CURDIR)/debian/tmp


EOF
  osc add debian.rules
fi

rm -f control
#rm -f deb_in_pkg_name
