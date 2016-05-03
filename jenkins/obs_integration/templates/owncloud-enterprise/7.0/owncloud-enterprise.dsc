Format: 1.0
Source: owncloud-enterprise
Version: [% VERSION_DEB %]-[% BUILDRELEASE_DEB %]
Binary: owncloud-enterprise
Maintainer: ownCloud, Inc. <jw@owncloud.com>
Architecture: all
Standards-Version: 3.7.2
Build-Depends: debhelper (>= 4), apache2 | httpd
Replaces: owncloud-enterprise-3rdparty (<= 7.0.3)
# https://github.com/openSUSE/obs-build/pull/147
DEBTRANSFORM-RELEASE: 1
