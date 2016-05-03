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
%define apache_serverroot /srv/www/htdocs
%define apache_confdir /etc/apache2/conf.d
%define oc_user wwwrun
%define oc_group www
%else
%if 0%{?fedora_version} || 0%{?rhel_version} || 0%{?centos_version}
%define apache_serverroot /var/www/html
%define apache_confdir /etc/httpd/conf.d
%define oc_user apache
%define oc_group apache
%define __jar_repack 0
%else
%define apache_serverroot /var/www
%define apache_confdir /etc/httpd/conf.d
%define oc_user www
%define oc_group www
%endif
%endif
## only for backwards compatibility with our 7.0 package layout.
%define oc_apache_web_dir 	%{apache_serverroot}/%{owncloud}

# CAUTION: keep in sync with debian.rules
%define oc_dir		%{oc_apache_web_dir}
%define oc_config_dir 	%{oc_apache_web_dir}/config
%define oc_data_dir 	%{oc_apache_web_dir}/data
%define oc_data_pdir 	%{oc_apache_web_dir}
 
%define ocphp		php
%define ochttpd		httpd
%if "%_repository" == "CentOS_6_PHP54" || "%_repository" == "RHEL_6_PHP54"
%define ocphp		php54-php
%define ochttpd		httpd
%endif
%if "%_repository" == "CentOS_6_PHP55" || "%_repository" == "RHEL_6_PHP55" 
%define ocphp		php55-php
%define ochttpd		htppd24-httpd
%endif
%if "%_repository" == "CentOS_6_PHP56" || "%_repository" == "RHEL_6_PHP56"
%define ocphp		rh-php56-php
%define ochttpd		htppd24-httpd
%endif

Name:           [% PACKNAME %]

# Downloaded from http://download.owncloud.com/internal/8.0.0RC2/owncloud_enterprise-8.0.0RC2.tar.bz2
# http://download.owncloud.com/internal/8.0.1/owncloud_enterprise-8.0.1.tar.bz2
# http://download.owncloud.com/internal/8.0.3RC2/owncloud_enterprise-8.0.3RC2.tar.bz2

## define prerelease % nil, if this is *not* a prerelease.
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

Source0:        http://owncloud:owncloud42@download.owncloud.com/internal/8.2.3/owncloud-enterprise-8.2.3.tar.bz2
Source1:        apache_secure_data
Source2:        README
Source3:        README.SELinux
Source4:        README.packaging
Source5:        README.symlink
Source6:        https://doc.owncloud.org/server/8.2/ownCloud_Server_Administration_Manual.pdf
Source100:      obs_check_deb_spec.sh
Url:            http://www.owncloud.org
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch
Summary:        The ownCloud Server - Private file sync and share server
License:        AGPL-3.0 and MIT
Group:          Productivity/Networking/Web/Utilities

###############################################
## All build requires go into the main package.

BuildRequires:	owncloud >= %{version}

%if 0%{?fedora_version} || 0%{?rhel_version} >= 6 || 0%{?centos_version} >= 6
# BuildRequires:  %{ochttpd}
%endif

%if 0%{?suse_version}
BuildRequires: 	fdupes apache2 unzip
%endif

###############################################

# https://github.com/owncloud/enterprise/issues/549
%if 0%{?fedora_version} || 0%{?rhel_version} || 0%{?centos_version}
%if 0%{?fedora_version} || 0%{?rhel_version} >= 700 || 0%{?centos_version} >= 700
BuildRequires:	php-odbc php-mysql php-pear mariadb-server
Requires:	php-odbc php-mysql php-pear %{nil:mariadb-server}
%else
# BuildRequires:	%{ocphp}-odbc %{ocphp}-mysql %{ocphp}-pear mysql-server
Requires:	%{ocphp}-odbc %{ocphp}-mysql %{ocphp}-pear %{nil:mysql-server}
%endif
%endif

%if 0%{?suse_version}
BuildRequires:	php-odbc php-mysql php-pear mariadb
Requires:	php-odbc php-mysql php-pear %{nil:mariadb}
%endif

Requires:	owncloud >= %{version}
Requires:	%{name}-theme

# included subpackages, per oc_app_package macro:
Requires:	%{name}-app-admin_audit		  = %{version}
Requires:	%{name}-app-enterprise_key	  = %{version}
Requires:	%{name}-app-files_antivirus	  = %{version}
Requires:	%{name}-app-files_ldap_home	  = %{version}
Requires:	%{name}-app-files_sharing_log	  = %{version}
Requires:	%{name}-app-firewall		  = %{version}
Requires:	%{name}-app-objectstore		  = %{version}
Requires:	%{name}-app-sharepoint		  = %{version}
Requires:	%{name}-app-user_shibboleth	  = %{version}
Requires:	%{name}-app-windows_network_drive = %{version}
Requires:	%{name}-app-files_drop		  = %{version}
Requires:	%{name}-app-password_policy	  = %{version}
#################
# removed between 8.0.0~RC2 and 8.0.1
# Requires:	%{name}-app-files_drop
# Not ready for 8.0.1
#################


# separate package:
# Requires:	%{name}-app-splunk

Conflicts:      owncloud-enterprise-fhs


%description
ownCloud Server provides you a private file sync and share
cloud. Host this server to easily sync business or private documents
across all your devices, and share those documents with other users of
your ownCloud server on their devices.

This package installs as follows:
oc_dir:        %{oc_dir}
oc_data_dir:   %{oc_data_dir}
oc_config_dir: %{oc_config_dir}
Requires:      %{ocphp}

ownCloud - Your Cloud, Your Data, Your Way!  www.owncloud.org

#####################################################

%package theme
License:      PHP-3.01
Group:        Development/Libraries/PHP
Summary:      The ownCloud enterprise theme
Requires:     %{name} = %{version}
%description theme
The ownCloud enterprise theme.
Branding to distinguish enterprise from community installations.

#####################################################
# oc_app_package
#
# Caution: This macro definition must be below the main package chunk. 
#          Otherwise the specfile parser in obs fails.
#
# Parameters:
#  %%1	appname as seen in the file system
#
%define oc_app_package() 			\
%package app-%{1}				\
Summary:	The ownCloud application %{1} add-on for %{name}-server \
Group:          Productivity/Networking/Web/Utilities		\
Requires:	owncloud-server >= %{version} 	\
%{?2:%{2}} 					\
%description app-%{1} 				\
This package provides the ownCloud application %{1} for %{name}-server \
						\
oc_dir:        %{oc_dir}			\
						\
%files app-%{1}					\
%defattr(0644,%{oc_user},%{oc_group},0755)	\
%dir %{oc_dir}/apps/%{1}			\
%{oc_dir}/apps/%{1}/*				\
%{nil}


%prep
%setup -q -n enterprise
cp %{SOURCE2} .
cp %{SOURCE3} .
cp %{SOURCE4} .
# README.symlink
sed -e"s|@@OC_BASEDIR_8@@|%{oc_dir}|g" -e"s|@@OC_BASEDIR_7@@|%{oc_dir}-enterprise|g" < %{SOURCE5} > README.symlink
cp %{SOURCE6} .
#%%patch0 -p0

# obs_check_deb_spec.sh
sh %{SOURCE100} rpm

# remove .bower.json .bowerrc .gitattributes .gitmodules
find . -name .bower\* -print -o -name .git\* -print | xargs rm

%build
# obsolete stuff, to be removed from tar-balls.
rm -f indie.json
rm -f l10n/l10n.pl

%install
# no server side java code contained, alarm is false
export NO_BRP_CHECK_BYTECODE_VERSION=true
idir=$RPM_BUILD_ROOT/%{oc_dir}
mkdir -p $RPM_BUILD_ROOT/%{oc_dir}
mkdir -p $RPM_BUILD_ROOT/%{oc_data_dir}
mkdir -p $RPM_BUILD_ROOT/%{oc_config_dir}
mkdir -p $RPM_BUILD_ROOT/%{oc_dir}/core/skeleton

cp -aRf * $idir
# CAUTION: when moving PDfs to skeleton 
# The User Manual exists in owncloud-server and must not be present here to avoid file conflicts.
# Currently ownCloudServerAdminManual.pdf only. 
mv $idir/*.pdf $idir/core/skeleton/ && true
rm -f $idir/debian.*{install,rules,control}
rm -f $idir/README{,.SELinux,.packaging}

%if 0%{?suse_version}
# link duplicate doc files
%fdupes -s $RPM_BUILD_ROOT/%{oc_dir}
%endif

# create the AllowOverride directive
# apache_secure_data
# install -p -D -m 644 %{SOURCE1}   $RPM_BUILD_ROOT/%{apache_confdir}/owncloud.conf
# sed -i -e"s|@@OC_DIR@@|%{oc_dir}|g" $RPM_BUILD_ROOT/%{apache_confdir}/owncloud.conf



%clean
rm -rf "$RPM_BUILD_ROOT"

%oc_app_package admin_audit
%oc_app_package enterprise_key
%if 0%{?suse_version}
%oc_app_package files_antivirus		Recommends:clamav
%else
%oc_app_package files_antivirus
%endif
%oc_app_package files_ldap_home
%oc_app_package files_sharing_log
%oc_app_package firewall
%oc_app_package objectstore
%oc_app_package sharepoint		Requires:%{ocphp}-soap
%oc_app_package user_shibboleth
%oc_app_package windows_network_drive	Requires:php5-libsmbclient
%oc_app_package files_drop
%oc_app_package password_policy

%pretrans
if [ -d "%{oc_dir}-enterprise" ]; then
  echo Existing %{oc_dir}-enterprise seen ...
fi
exit 0

%post
# http://fedoraproject.org/wiki/Packaging:ScriptletSnippets#Syntax
if [ $1 -gt 1 -a -d "%{oc_dir}" -a -d "%{oc_dir}-enterprise" ]; then
  echo touch "%{apache_serverroot}/_oc_upgrade_running"
  touch "%{apache_serverroot}/_oc_upgrade_running"
fi
exit 0

## posttrans is available in rpm 4.4 or later. Its $1 is always 0.
%posttrans
if [ -f "%{apache_serverroot}/_oc_upgrade_running" -a -d "%{oc_dir}" -a -d "%{oc_dir}-enterprise" ]; then
  echo You have both %{oc_dir} and %{oc_dir}-enterprise in an update scenario
  p1=$(readlink -f "%{oc_dir}/.")
  p2=$(readlink -f "%{oc_dir}-enterprise/.")
  if [ "$p1" = "$p2" ]; then
    echo Good, they are linked. Please consult %{oc_dir}/README.symlink later.
  else
    # when we are in an update case, and the installation in %{oc_dir}
    # is uninitialized, then we have the oc7 -> oc8 migration case.
    # The directory is there and populated, because we and all our 
    # dependencies just arrived.
    #
    # Uninitialized is: data folder empty and config.php missing.
    if [ ! -f "%{oc_dir}/config/config.php" -a -z "$(ls %{oc_dir}/data)" ]; then
      echo Good, your %{oc_dir} installation is uninitialized.
      echo "We will link that into %{oc_dir}-enterprise now." 
      echo Please consult %{oc_dir}/README.symlink later.

      cp -a %{oc_dir}/*    %{oc_dir}-enterprise/
      cp -a %{oc_dir}/.??* %{oc_dir}-enterprise/
      rm -rf %{oc_dir}
      ln -s %{oc_dir}-enterprise %{oc_dir}

      cat %{oc_dir}/README.symlink || true

    else
      rm -f %{oc_dir}/README.symlink || true
      echo ... looks like you have two independant ownCloud installations.
      echo Error: Cannot decide which one to upgrade. 
      echo Hint: Please remove one and try again.
      exit 1
    fi
  fi
else
  rm -f %{oc_dir}/README.symlink || true
fi
rm -f "%{apache_serverroot}/_oc_upgrade_running"
exit 0

%files
%defattr(-,root,root,-)
%doc README README.packaging


# openSUSE needs the dir entries for top and apps, all others dont need them. Sigh.
%defattr(0644,root,%{oc_group},0755)
%dir %{oc_dir}
%{oc_dir}/core/skeleton/*
%{oc_dir}/README.symlink

# must match user and group and modes as set in owncloud-server package, where a data folder also exists.
%defattr(0664,%{oc_user},%{oc_group},0775)
%dir %{oc_config_dir}
%{oc_config_dir}/*
%dir %{oc_dir}/apps
%dir %{oc_data_dir}


%files theme
# must match user and group and modes as set in owncloud-server package, where a themes folder also exists.
# https://github.com/owncloud/core/issues/16132
%defattr(0644,%{oc_user},%{oc_group},0775)
%dir %{oc_dir}/themes
%{oc_dir}/themes/*


%changelog

