#
# spec file for package owncloud-enterprise-app-splunk
#
# Copyright (c) 2012-2015 ownCloud, Inc.
#
# All modifications and additions to the file contributed by third parties
# remain the property of their copyright owners, unless otherwise agreed
# upon. The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package itself (unless the
# license for the pristine package is not an Open Source License, in which
# case the license is the MIT License). An "Open Source License" is a
# license that conforms to the Open Source Definition (Version 1.9)
# published by the Open Source Initiative.
#
# Please submit bugfixes, issues or comments via http://github.com/owncloud

# CAUTION: keep in sync with ee:8.0/owncloud-server

%if 0%{?suse_version}
%define apache_serverroot /srv/www/htdocs
%define apache_confdir /etc/apache2/conf.d
%define apache_user wwwrun
%define apache_group www
%else
%if 0%{?fedora_version} || 0%{?rhel_version} || 0%{?centos_version}
%define apache_serverroot /var/www/html
%define apache_confdir /etc/httpd/conf.d
%define apache_user apache
%define apache_group apache
%define __jar_repack 0
%else
%define apache_serverroot /var/www
%define apache_confdir /etc/httpd/conf.d
%define apache_user www
%define apache_group www
%endif
%endif
######
%define owncloud_serverroot %{apache_serverroot}/owncloud


Name:           owncloud-enterprise-app-splunk
Version:        20150602
Release:        0
Summary:        Splunk for ownCloud
Group:          Development/Libraries/PHP
License:        SUSE-NonFree
Url:            https://github.com/splunk/splunk-sdk-php
Source0:        http://download.owncloud.com/internal/8.0.0alpha2/enterprise-splunk.tar.bz2
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
Requires:	owncloud-server


%description
Splunk app for ownCloud

%prep
%setup -n splunk

%build

%install
idir=$RPM_BUILD_ROOT/%{owncloud_serverroot}
mkdir -p $idir/apps/splunk
cp -a .  $idir/apps/splunk



%clean
%{__rm} -rf %{buildroot}

%files
%defattr(-,root,root,-)
%{owncloud_serverroot}


%changelog
