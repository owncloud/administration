Format: 1.0
Source: [% PACKNAME %]
Binary: [% PACKNAME %]
Version: [% VERSION_DEB %]-[% BUILDRELEASE_DEB %]
Maintainer: Juergen Weigert <jw@owncloud.com>
Architecture: all
Standards-Version: 3.7.2
Build-Depends: debhelper (>= 4), curl, owncloud-config-apache
# https://github.com/openSUSE/obs-build/pull/147
DEBTRANSFORM-RELEASE: 1
