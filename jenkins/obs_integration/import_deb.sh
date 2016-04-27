#! /bin/sh

#wget http://security.ubuntu.com/ubuntu/pool/universe/q/qttools-opensource-src/qttools5-dev_5.5.1-3build1_amd64.deb

name=qttools5-dev
version=5.5.1
buildrel=3build1
arch=amd64

deb_in_pkg_name=${name}_${version}-${buildrel}_${arch}.deb
ar x $deb_in_pkg_name
tar xf control.tar.xz
rm control.tar.xz
osc add data.tar.xz

if [ ! -f debian.control ]; then
#  dpkg-deb -I $deb_in_pkg_name | sed -e 's@^ @@' -e 's@^ @       @' | sed -n -e '/^Package:/,$p' > debian.control
  mv control debian.control
  osc add debian.control
fi

if [ ! -f $name.dsc ]; then
  echo "Format: 1.0" > $name.dsc
  grep < debian.control >> $name.dsc "^Source: "
  echo                  >> $name.dsc "Binary: $name"
  grep < debian.control >> $name.dsc "^Version: "
  grep < debian.control >> $name.dsc "^Maintainer: "
  grep < debian.control >> $name.dsc "^Uploaders: "
  grep < debian.control >> $name.dsc "^Homepage: "
  grep < debian.control >> $name.dsc "^Architecture: "
  echo                  >> $name.dsc "Standards-Version: 3.9.4"
  echo                  >> $name.dsc "# DEBTRANSFORM-RELEASE: 0"
  osc add $name.dsc
fi

