#
# spec file for package [% PACKNAME %]
#
# Copyright (c) 2012-2016 ownCloud, Inc.
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

# name used as apache alias and topdir for php code.
%define owncloud	owncloud

# CAUTION: keep in sync with debian.rules
### apache variables
%if 0%{?suse_version}
%define apache_serverroot	/srv/www/htdocs
%define apache_confdir /etc/apache2/conf.d
%define oc_user wwwrun
%define oc_group www
%define oc_user_id 30
%define oc_group_id 8
%else
%if 0%{?fedora_version} || 0%{?rhel_version} || 0%{?centos_version}
%define apache_serverroot	/var/www/html
%define apache_confdir /etc/httpd/conf.d
%define oc_user apache
%define oc_group apache
%define oc_user_id 48
%define oc_group_id 48
%else
%error "Unknown platform"
%endif
%endif

# CAUTION: keep in sync with debian.rules
%define oc_dir		%{apache_serverroot}/%{owncloud}
%define oc_config_dir 	%{oc_dir}/config
%define oc_data_dir 	%{oc_dir}/data
%define oc_data_pdir 	%{oc_dir}

Name:           [% PACKNAME %]

## define prerelease % nil, if this is *not* a prerelease. Caution: always lower case beta rc.
%define prerelease [% PRERELEASE %]
%define base_version [% VERSION %]

%if 0%{?centos_version} == 600 || 0%{?fedora_version} || "%{prerelease}" == ""
# For beta and rc versions we use the ~ notation, as documented in
# http://en.opensuse.org/openSUSE:Package_naming_guidelines
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

# http://download.owncloud.org/community/testing/owncloud-8.2.2RC1.tar.bz2
Source0:        [% SOURCE_TAR_URL %]
Source1:        apache_conf_default
Source2:        README
Source4:        README.packaging
Source5:	disable-updatechecker.config.php
Source6:	rpmlintrc
Url:            http://www.owncloud.org
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch
Summary:        The ownCloud Server - Private file sync and share server
License:        AGPL-3.0 and MIT
Group:          Productivity/Networking/Web/Utilities


%if "%{?_repository}" == "openSUSE_Tumbleweed"
# disable rpmlint for Tumbleweed while it is broken.
# It has random errors like these:
#  IOError: [Errno 2] No such file or directory: '/tmp/rpmlint.owncloud-ee-base-8.2.2-1.1.noarch.rpm.zFc3ft/usr/share/owncloud/apps/files_external/tests/env/stop-smb-silvershell.sh'

BuildRequires:        -rpmlint -rpmlint-mini

# useradd, groupadd is needed in pre section
PreReq: shadow
%endif

Obsoletes:	owncloud-server 	<= 9.01.99
Obsoletes:	owncloud-config-apache 	<= 9.01.99
Obsoletes:	owncloud		<= 9.01.99

%description
ownCloud Server provides you a private file sync and share
cloud. Host this server to easily sync business or private documents
across all your devices, and share those documents with other users of
your ownCloud server on their devices.

This package installs as follows:
oc_dir:        %{oc_dir}
oc_data_dir:   %{oc_data_dir}
oc_config_dir: %{oc_config_dir}

ownCloud - Your Cloud, Your Data, Your Way!  www.owncloud.org

#####################################################

%prep
# owncloud-enterprise-*.tar*          has toplevel dir enterprise (do not use here)
# owncloud-enterprise-complete-*.tar* has toplevel dir owncloud   (correct)
%setup -q -n [% SOURCE_TAR_TOP_DIR %]
cp %{SOURCE1} .
cp %{SOURCE2} .
cp %{SOURCE4} .
#%%patch0 -p0

## remove .bower.json .bowerrc .gitattributes .gitmodules
# find . -name .bower\* -print -o -name .git\* -print | xargs -r rm -rf

%build
rm -f Jenkinsfile

%install
# We had silently skipped files under %{_docdir} on both SUSE and CentOS. Do not use that for our
# apache template. Prefer /usr/share/lib, it always installs flawlessly.
%define oc_docdir_base /usr/share/lib
%define oc_docdir %{oc_docdir_base}/%{name}-%{base_version}

# no server side java code contained, alarm is false
export NO_BRP_CHECK_BYTECODE_VERSION=true
idir=$RPM_BUILD_ROOT/%{oc_dir}
mkdir -p $RPM_BUILD_ROOT/%{oc_dir}
mkdir -p $RPM_BUILD_ROOT/%{oc_dir}/etc
mkdir -p $RPM_BUILD_ROOT/%{oc_data_dir}
mkdir -p $RPM_BUILD_ROOT/%{oc_config_dir}
mkdir -p $RPM_BUILD_ROOT/%{oc_dir}/core/skeleton

cp -aRf .htaccess .user.ini * $idir
rm -f $idir/debian.*{install,rules,control}
rm -f $idir/README{,.SELinux,.packaging}
sed -e 's@/var/www/owncloud@%{oc_dir}@' < $idir/apache_conf_default > owncloud-config-apache.conf.default
rm -f $idir/apache_conf_default

mkdir -p $RPM_BUILD_ROOT/%{oc_docdir}
mv README README.packaging owncloud-config-apache.conf.default $RPM_BUILD_ROOT/%{oc_docdir}

## https://github.com/owncloud/core/issues/22257
# disable-updatechecker.config.php
cp %{SOURCE5} $idir/config/

%clean
rm -rf "$RPM_BUILD_ROOT"

%pre
## create apache user and group, so that our files section works.
getent group  %{oc_group} > /dev/null || sh -x -c "groupadd -r -g %{oc_group_id} %{oc_group}"
getent passwd %{oc_user}  > /dev/null || sh -x -c "useradd  -r -u %{oc_user_id} -g %{oc_group} -c 'Dummy for %{name}' %{oc_user}"

%post
## Delete the apache user, if it was the one we created.
## Never delete the apache user, if apache server is installed.
test ! -d %{apache_confdir} && getent passwd %{oc_user} | grep -q "Dummy for %{name}" && sh -x -c "userdel %{oc_user}" || true

%files
%defattr(0644,root,root,0755)
%dir %{oc_docdir_base}
%dir %{oc_docdir}
%{oc_docdir}/*

# is there any security to be gained here? Easier to chown everthing to % {oc_user}
%defattr(0644,root,%{oc_group},0755)
%attr(0755,%{oc_user},%{oc_group}) %{oc_dir}/occ
%attr(0775,%{oc_user},%{oc_group}) %{oc_dir}/apps
%attr(0775,%{oc_user},%{oc_group}) %{oc_data_dir}
%attr(0775,%{oc_user},%{oc_group}) %{oc_config_dir}
# BUMMER: exclude excludes globally, not just below. It cannot be used to avoid duplicate warnings?
# FIXME: only cure against the duplicate warnings is a -f file-list

# https://github.com/owncloud/core/issues/23512
%attr(0755,%{oc_user},%{oc_group}) %{oc_dir}/.htaccess
%attr(0755,%{oc_user},%{oc_group}) %{oc_dir}/.user.ini
%dir %{oc_dir}
%{oc_dir}/*

%changelog

