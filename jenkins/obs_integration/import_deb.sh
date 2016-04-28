#! /bin/bash
# This script import a debian binary package into obs.
# A data.tar.gz and all the required debian.* files are created, so that the package
# can pass a normal build cycle, as if it were source. The contents of the data tar is simply copied through unchanged.
# 
# Requires:
# sudo apt-get install libdistro-info-perl
# sudo apt-get install osc

#wget http://security.ubuntu.com/ubuntu/pool/universe/q/qttools-opensource-src/qttools5-dev_5.5.1-3build1_amd64.deb

# https://launchpad.net/ubuntu/xenial/+package/libqt5designer5
default_base_url=http://security.ubuntu.com/ubuntu/pool/universe
url=$1

if [ -z "$url" ]; then
  cat <<EOF
URL or path of debian package needed. Please browse for inspiration:
  $default_base_url

Example usage:
  cd src/obs/isv:ownCloud:devel:Ubuntu_16.04_Universe
  osc mkpac qttools5-dev-tools
  $0 q/qttools-opensource-src/qttools5-dev-tools_5.5.1-3build1_amd64.deb
  osc ci -m '$0 q/qttools-opensource-src/qttools5-dev-tools_5.5.1-3build1_amd64.deb'
EOF
  exit 1
fi

if [[ ! $url =~ '://' ]]; then
  if [ ! -f $url ]; then
    url=$default_base_url/$url
  fi
fi

deb_in_pkg_name=$(echo $url | sed -e 's@.*/@@')
tmpdir=/tmp/import$$
tmpfile=$tmpdir/$deb_in_pkg_name

mkdir -p $tmpdir
if [ -f $url ]; then
  cp $url $tmpfile
else
  wget $url -O $tmpfile
fi

echo $tmpfile

name=$(echo $deb_in_pkg_name | sed -e 's@\(.*\)_\(.*\)_.*@\1@')
## version includes the buildrelease number. E.g. 5.5.1-3build1
version=$(echo $deb_in_pkg_name | sed -e 's@\(.*\)_\(.*\)_.*@\2@')

echo name: $name
echo version: $version

ar x $tmpfile
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
  debchange -c debian.changelog --create --distribution stable  -v ${version} --package $name "created with $0 $url"
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
  echo                  >> $name.dsc "Version: ${version}"
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

echo "Next steps:"
echo " osc build"
echo " osc ci -m '$0 $url'"

rm -rf $tmpdir
rm -f control
rm -f md5sums
