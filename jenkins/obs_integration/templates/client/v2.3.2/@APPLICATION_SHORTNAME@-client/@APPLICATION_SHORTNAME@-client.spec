#
# spec file for package owncloud-client
#
# Copyright (c) 2012 ownCloud, inc.; Nuernberg, Germany.
#
# All modifications and additions to the file contributed by third parties
# remain the property of their copyright owners, unless otherwise agreed
# upon. The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package itself (unless the
# license for the pristine package is not an Open Source License, in which
# case the license is the MIT License). An "Open Source License" is a
# license that conforms to the Open Source Definition (Version 1.9)
# published by the Open Source Initiative.

# Please submit bugfixes, issues or comments via http://github.com/owncloud/
#

## Caution: This spec file exists in multiple locations. Keep in sync:
##  isv:ownCloud:desktop
##  isv:ownCloud:community:nightly
##  isv:ownCloud:community:testing
##  github.com/owncloud/administration/jenkins/obs_integration/templates/client/v1_8_1/SHORTNAME-client.spec.in
##  -> you can modify it in testing, and play around for a while, but then merge into the copy on
##     github, which is authorative for the branded clients.
##
## created by: ./genbranding.pl (V1.13) -o -p isv:ownCloud:desktop owncloudclient-2.2.4.tar.xz ownCloud.tar.xz

## One specfile to rule them all:
##  versions 1.6.x or 1.7.x, released or prerelease versions. All rpm based platforms.
##  testing, branding, whatever.
##

%_oc_package_header
%_use_oc_qt5_as_default
%define use_devtoolset 0
%if 0%{?el6} || 0%{?el7}
%define use_devtoolset 1
%endif

Name:           %{_oc_pkg_name_client}

# Use translations from an external tarball in the package, or build them
# using the Qt tools? For distros where we do not have the tools, disable.

%include %{_sourcedir}/common.inc

%if 0%{?centos_version} == 600 || 0%{?rhel_version} == 600 || 0%{?fedora_version} || "%{prerelease}" == ""
# For beta and rc versions we use the ~ notation, as documented in
# http://en.opensuse.org/openSUSE:Package_naming_guidelines
# Some distro's (centos_6) don't allow ~ characters. There we follow the Fedora guidelines,
# which suggests massaging the buildrelease number.
# Otoh: for openSUSE, this technique is discouraged by the package naming guidelines.
Version:       	%{base_version}
%if "%{prerelease}" == ""
Release:        0
%else
Release:       	0.<CI_CNT>.<B_CNT>.%{prerelease}
%endif
%else
Version:       	%{base_version}~%{prerelease}
Release:        0
%endif

License:        GPL-2.0+
Summary:        The ownCloud synchronization client
Url:            http://owncloud.com
Group:          Productivity/Networking/Other
Source0:        owncloudclient-%{tar_version}.tar.bz2
Source1:        owncloud.sh
Source2:        owncloudcmd.sh
Source3:        100-sync-inotify.conf
Source4:        README.UPDATE.txt
Source5:        l10n.zip

%if 0%{?rhel_version} || 0%{?centos_version} || 0%{?suse_version} == 1110
Patch1:         autostart_use_wrapper.diff
%endif

# TODO: What's up with this?
# %if 0%{?rhel_version} >= 600 || 0%{?centos_version} >= 600 || 0%{?suse_version} == 1110 || 0%{?fedora_version} == 23
# Must be all in one line:
#%%define cmake_args -DCMAKE_INCLUDE_PATH=%{_prefix}/include -DCMAKE_LIBRARY_PATH=%{_prefix}/%{_lib} -DCMAKE_INSTALL_RPATH_USE_LINK_PATH=TRUE
%global cmake_args %nil
 

# default to have docs, only disable for RHEL/CentOS 6
%define have_doc 1
%if 0%{?el6} || 0%{?rhel_version} == 700 || (0%{?suse_version} && ! 0%{?is_opensuse})  
%define have_doc 0
%endif
# https://github.com/owncloud/client/issues/2153
%define have_man 0


# The infamous SUSE matrix:
# -------------------------
#
#                      	is_opensuse 	suse_version	sle_version
# openSUSE_13.1				1310
# SLE_12				1315		120000
# SLE_12_SP1				1315		120100
# openSUSE_Leap_42.1	1		1315		120100
# openSUSE_13.2				1320
# openSUSE_Factory	1		1330
# openSUSE_Tumbleweed	1		1330


######################################################################### BuildRequires only below here.

BuildRequires:  cmake >= 2.8.11

BuildRequires:  %{_oc_pkg_prefix}-filesystem
BuildRequires:  %{_oc_pkg_prefix}-qt5keychain-devel >= 0.7.0, %{_oc_pkg_prefix}-qt5keychain1 >= 0.7.0
BuildRequires:  %{_oc_pkg_prefix}-libQt5Core-devel
BuildRequires:  %{_oc_pkg_prefix}-libQt5Gui-devel
BuildRequires:  %{_oc_pkg_prefix}-libQt5Network-devel
BuildRequires:  %{_oc_pkg_prefix}-libQt5Xml-devel
BuildRequires:  %{_oc_pkg_prefix}-libQt5PrintSupport-devel
BuildRequires:  %{_oc_pkg_prefix}-libQt5DBus-devel
BuildRequires:  %{_oc_pkg_prefix}-libQt5Concurrent-devel
BuildRequires:  %{_oc_pkg_prefix}-libqt5-qtwebkit-devel
# BuildRequires:  %{_oc_pkg_prefix}-libqt5-linguist-devel
# HACK: Fix qttools spec file
BuildRequires:  %{_oc_pkg_prefix}-libqt5-linguist


%if 0%{?use_devtoolset}
BuildRequires: devtoolset-4-gcc-c++
%else
BuildRequires: gcc gcc-c++
%endif

BuildRequires:  openssl-devel
BuildRequires:  desktop-file-utils

# SUSE specific stuff
%if 0%{?suse_version}
BuildRequires:  update-desktop-files
BuildRequires:  libopenssl-devel
%endif

# Version independant package name mapping between suse and fedora/centos
%if 0%{?fedora_version} || 0%{?rhel_version} || 0%{?centos_version}
BuildRequires:  sqlite-devel
BuildRequires:  desktop-file-utils
# was 0%{?fedora_version} || 0%{?rhel_version} > 700 || 0%{?centos_version} > 600
%if %have_doc	
BuildRequires:  python-sphinx
# sphinx fails on Fedora 25: https://github.com/owncloud/client/issues/5355
BuildRequires: python
%endif
%else
# Documentation
%if 0%{have_doc}
BuildRequires:  python-Sphinx
%endif
BuildRequires:  sqlite3-devel
BuildRequires:  update-desktop-files
%endif


######################################################################### Requires only below here.

%if 0%{?fedora_version} > 20 || 0%{?centos_version} > 700 || 0%{?suse_version} || 0%{?rhel_version} > 700
# Fedora-19 and -20, CentOS-6, CentOS-7, RHEL_6,7 don't have Suggests.
Suggests:	%{name}-nautilus
Suggests:       %{name}-nemo
%endif

Requires: %{name}-l10n
Requires: libowncloudsync0 = %{version}

######################################################################### Obsoletes only below here.

Obsoletes: libocsync0
Obsoletes: libocsync-devel
Obsoletes: libocsync-plugin-owncloud
Obsoletes: libocsync-plugin-owncloud
Obsoletes: libocsync-devel-doc
Obsoletes: libocsync-doc
Obsoletes: opt-owncloud-client

# Obsolete the experimental Qt5 packages if this is the unbranded client.
%if %{is_owncloud_client}
Obsoletes: libowncloudqt5sync0 libowncloudqt5sync-devel owncloud-client-qt5 owncloud-client-qt5-doc owncloud-client-qt5-l10n
%endif

######################################################################### Package Descriptions start here.

BuildRoot:      %{_tmppath}/%{name}-%{version}-build

%description
The ownCloud sync client - github.com/owncloud/client

ownCloud client enables you to connect to your private
ownCloud Server. With it you can create folders in your home
directory, and keep the contents of those folders synced with your
ownCloud server. Simply copy a file into the directory and the
ownCloud Client does the rest.

ownCloud gives your employees anytime, anywhere access to the files
they need to get the job done, whether through this desktop application,
our mobile apps, the web interface, or other WebDAV clients. With it,
your employees can easily view and share documents and information
critical to the business, in a secure, flexible and controlled
architecture. You can easily extend ownCloud with plug-ins from the
community, or that you build yourself to meet the requirements of
your infrastructure and business.

ownCloud - Your Cloud, Your Data, Your Way!  www.owncloud.com

Authors
=======
Duncan Mac-Vicar P. <duncan@kde.org>
Klaas Freitag <freitag@owncloud.com>
Daniel Molkentin <danimo@owncloud.com>



%package -n %{name}-doc
Summary:        Documentation for ownCloud
Group:          Development/Libraries/C and C++
Requires: %{name}%{?_isa} = %{version}-%{release}
Obsoletes:      opt-%{name}-doc

%description -n %{name}-doc
Documentation for the ownCloud desktop application.

%package -n %{name}-l10n
Summary:        Localization for ownCloud
Group:          Development/Libraries/C and C++
Requires: %{name}%{?_isa} = %{version}-%{release}
Obsoletes:      opt-%{name}-l10n

%description -n %{name}-l10n
Localization files for the ownCloud desktop application.

%package -n libowncloudsync0
Requires:       %{_oc_pkg_prefix}-qt5keychain1 >= 0.7.0
Obsoletes:      opt-libowncloudsync0

Summary:        The ownCloud synchronization library
Group:          Development/Libraries/C and C++

%description -n libowncloudsync0
The ownCloud synchronization library.

%package -n libowncloudsync-devel
Summary:        Development files for the ownCloud synchronization library
Group:          Development/Libraries/C and C++
Requires: libowncloudsync0 = %{version}
Obsoletes:      opt-libowncloudsync-devel

%description -n libowncloudsync-devel
Development files for the ownCloud synchronization library.

%prep
%setup -q -n owncloudclient-%{tar_version}

%_oc_client_apply_common_patches

%if 0%{?rhel_version} || 0%{?centos_version} || 0%{?suse_version} == 1110
# autostart_use_wrapper.diff
%patch1 -p1
%endif

# %if 0%{?el6}
# %patch2 -p1
# %patch3 -p1
# %endif

%if 0%{?rhel_version} == 600 || 0%{?centos_version} == 600
sed -i -e 's/OVERRIDE=override/OVERRIDE=/' cmake/modules/QtVersionAbstraction.cmake
%endif

%build
echo centos_version 0%{?centos_version}
echo rhel_version   0%{?rhel_version}
echo fedora_version 0%{?fedora_version}
echo suse_version   0%{?suse_version}
echo have_doc       0%{?have_doc}

%if 0%{?use_devtoolset}
source /opt/rh/devtoolset-4/enable
%endif

export LD_LIBRARY_PATH=%{_oc_prefix}/%{_lib}
export PATH=%{_oc_prefix}/bin:$PATH

env

mkdir build
pushd build
# http://www.cmake.org/Wiki/CMake_RPATH_handling#Default_RPATH_settings
cmake .. -DWITH_DOC=TRUE \
  -DCMAKE_FIND_ROOT_PATH="%{_oc_prefix}" \
%if "%{prerelease}" != ""
  -DMIRALL_VERSION_SUFFIX="%{prerelease}" \
  -DMIRALL_VERSION_BUILD="1917" \
%endif
  -DKDE_INSTALL_USE_QT_SYS_PATHS=1 \
  -DCMAKE_C_FLAGS:STRING="%{optflags}" \
  -DCMAKE_CXX_FLAGS:STRING="%{optflags}" \
  -DCMAKE_SKIP_RPATH=OFF \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DCMAKE_INSTALL_PREFIX=%{_oc_prefix} \
  -DCMAKE_INSTALL_DATAROOTDIR:PATH=%{_datadir} \
  -DDATA_INSTALL_DIR:PATH=%{_datadir} \
  -DCMAKE_INSTALL_DOCDIR:PATH=%{_docdir} \
  -DSYSCONF_INSTALL_DIR=%{_sysconfdir} \
%if %{_lib} == lib64
  -DLIB_SUFFIX=64 \
%endif
%if ! %{is_owncloud_client}
  -DOEM_THEME_DIR=$PWD/../ownCloud/syncclient \
%endif
  -DQTKEYCHAIN_INCLUDE_DIR=%{_oc_prefix}/include/qt5keychain \
  -DQTKEYCHAIN_LIBRARY=%{_oc_prefix}/%{_lib}/libqt5keychain.so \
  -DGIT_SHA1="HACK FIXME" \
  -DBUILD_SHELL_INTEGRATION=OFF \
  -DPACKAGE="%{_oc_pkg_name_client}" \
  %cmake_args

# documentation here?
if [ -e conf.py ];
then
  # for old cmake versions we need to move the conf.py.
  mv conf.py doc/
fi

env LD_RUN_PATH=%{_libdir}/owncloud:%{_libdir}/owncloud make %{?_smp_mflags} VERBOSE=1

make doc -j1
popd

%install
%if 0%{?use_devtoolset}
source /opt/rh/devtoolset-4/enable
%endif

pushd build
make DESTDIR=%{buildroot} install 

echo suse_version 0%{?suse_version}
echo sle_version 0%{?sle_version}
echo have_doc %have_doc
echo bindir %_bindir

if [ %{have_doc} != 0 ];
then
  rm ${RPM_BUILD_ROOT}%{_docdir}/%{name}/html/unthemed/.buildinfo
  mv ${RPM_BUILD_ROOT}%{_docdir}/%{name}/html/unthemed/* ${RPM_BUILD_ROOT}%{_docdir}/%{name}/html/
  rmdir ${RPM_BUILD_ROOT}%{_docdir}/%{name}/html/unthemed
fi
popd

%if %{have_man}
if [ -d ${RPM_BUILD_ROOT}%{_mandir}/man1 ]; then
%if ! %{is_owncloud_client}
  mkdir -p ${RPM_BUILD_ROOT}%{_mandir}man1
  mv ${RPM_BUILD_ROOT}%{_mandir}/man1/{owncloud.1,owncloud.1}
  mv ${RPM_BUILD_ROOT}%{_mandir}/man1/{owncloudcmd.1,owncloudcmd.1}
%endif
  gzip ${RPM_BUILD_ROOT}%{_mandir}/man1/*.1
fi
%else
rm -f ${RPM_BUILD_ROOT}%{_mandir}/man1/*.1
%endif

# TODO: Move to overlay package if needed at all .. what is it supposed to do?
# %define extdir ${RPM_BUILD_ROOT}%{_datadir}/nautilus-python/extensions
# test -f %{extdir}/ownCloud.py  && mv %{extdir}/ownCloud.py  %{extdir}/owncloud.py  || true
# test -f %{extdir}/ownCloud.pyo && mv %{extdir}/ownCloud.pyo %{extdir}/owncloud.pyo || true
# test -f %{extdir}/ownCloud.pyc && mv %{extdir}/ownCloud.pyc %{extdir}/owncloud.pyc || true

install -d ${RPM_BUILD_ROOT}%{_oc_prefix}/bin
# mv ${RPM_BUILD_ROOT}/%{_bindir}/owncloud* ${RPM_BUILD_ROOT}/%{_oc_prefix}/bin/

install -d ${RPM_BUILD_ROOT}%{_bindir}
install %{SOURCE1} ${RPM_BUILD_ROOT}%{_bindir}/owncloud
install %{SOURCE2} ${RPM_BUILD_ROOT}%{_bindir}/owncloudcmd

install -d ${RPM_BUILD_ROOT}%{_docdir}/%{name}/
install %{_builddir}/*/README.md ${RPM_BUILD_ROOT}%{_docdir}/%{name}/
install %{_builddir}/*/COPYING ${RPM_BUILD_ROOT}%{_docdir}/%{name}/

# https://github.com/owncloud/client/issues/4107
install -m 0755 -D %{SOURCE3} ${RPM_BUILD_ROOT}/etc/sysctl.d/100-sync-inotify.conf

%if %{?suse_version:1}0
%suse_update_desktop_file -n owncloud
# workaround for https://github.com/owncloud/ownbrander/issues/322
for desktop_icon_dir in $RPM_BUILD_ROOT/usr/share/icons/hicolor/*/apps; do
  # copy shortname to executable name, if missing.
  if [ -f $desktop_icon_dir/owncloud.png -a ! -f $desktop_icon_dir/owncloud.png ]; then
    cp $desktop_icon_dir/owncloud.png $desktop_icon_dir/owncloud.png
  fi
done
%endif

%check
## use exit 0 instead of exit 1 to turn this into warnings:
if [ "%{name}" != "testpilotcloud-client" ]; then
  if [ "%{prerelease}" == "" ]; then
    expr match '%{distribution}' '.*:community:\(testing\|nightly\)' && { echo "Warning: Need a prerelease here, not %{version} (okay, if you want to submitpac this as a release today)"; }
  else
    expr match '%{distribution}' '.*:community:desktop' && { echo "Error: Must not have a prerelease here, not %{version}"; exit 1; }
  fi
fi

%if 0%{?fedora_version}
%post
/bin/touch --no-create %{_datadir}/icons/hicolor >/dev/null 2>/dev/null || :

%postun
if [ $1 -eq 0 ] ; then
    /bin/touch --no-create %{_datadir}/icons/hicolor >/dev/null  2>/dev/null
    /usr/bin/gtk-update-icon-cache %{_datadir}/icons/hicolor >/dev/null 2>/dev/null || :
fi
%endif

%posttrans
# fixing https://github.com/owncloud/enterprise/issues/1714
/usr/bin/gtk-update-icon-cache --quiet --force %{_datadir}/icons/hicolor >/dev/null 2>/dev/null || :

%post   -n libowncloudsync0 -p /sbin/ldconfig
%postun -n libowncloudsync0 -p /sbin/ldconfig

%files
%defattr(-,root,root,-)
%dir %{_docdir}/%{name}
%doc %{_docdir}/%{name}/README.md
%doc %{_docdir}/%{name}/COPYING

%{_bindir}/owncloud
%{_bindir}/owncloudcmd
%{_oc_bindir}/owncloud
%{_oc_bindir}/owncloudcmd

%{_datadir}/applications/owncloud.desktop
%{_datadir}/icons/hicolor
%if 0%{have_man}
%{_mandir}/man1/owncloud*
%endif

%config /etc/ownCloud
# https://github.com/owncloud/client/issues/4107
%config /etc/sysctl.d/100-sync-inotify.conf

%files -n %{name}-doc
%defattr(-,root,root,-)
%if 0%{have_doc}
%doc %{_docdir}/%{name}/html
%endif

%files -n %{name}-l10n
%defattr(-,root,root,-)
%if 0%{?fedora_version} != 23
# workaround for https://github.com/owncloud/client/issues/4987
%dir %{_datadir}/owncloud/
%{_datadir}/owncloud/i18n
%endif

%files -n libowncloudsync0
%defattr(-,root,root,-)
%{_oc_libdir}/libowncloudsync.so.*
%{_oc_libdir}/owncloud/libocsync.so.*
%dir %{_oc_libdir}/owncloud

%files -n libowncloudsync-devel
%defattr(-,root,root,-)
%{_oc_libdir}/libowncloudsync.so
%{_oc_libdir}/owncloud/libocsync.so
%{_oc_includedir}/owncloudsync/

%changelog
