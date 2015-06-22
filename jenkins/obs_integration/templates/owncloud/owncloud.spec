# 
# spec file for package owncloud
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
# Please submit bugfixes, issues or comments via http://github.com/owncloud/
#

# 0, 1: switch here to change to an fhs compatible layout.
%define fhs 0	

# 0, 1: support nginx as alternative to apache
%define have_nginx 0

# name used as apache alias and topdir for php code.
%define owncloud	owncloud	

# CAUTION: keep in sync with debian.rules
### apache variables
%if 0%{?suse_version}
%define nginx_confdir /etc/nginx/conf.d
%define apache_serverroot /srv/www/htdocs
%define apache_confdir /etc/apache2/conf.d
%define oc_user wwwrun
%define oc_group www
%else
%if 0%{?fedora_version} || 0%{?rhel_version} || 0%{?centos_version}
%define nginx_confdir /etc/nginx/conf.d
%define apache_serverroot /var/www/html
%define apache_confdir /etc/httpd/conf.d
%define oc_user apache
%define oc_group apache
%define __jar_repack 0
%else
%define nginx_confdir /etc/nginx/conf.d
%define apache_serverroot /var/www
%define apache_confdir /etc/httpd/conf.d
%define oc_user www
%define oc_group www
%endif
%endif
## only for backwards compatibility with our 7.0 package layout.
%define oc_apache_web_dir 	%{apache_serverroot}/%{owncloud}

# CAUTION: keep in sync with debian.rules
%if %{fhs}
%define oc_dir		/usr/share/%{owncloud}
%define oc_config_dir 	/etc/%{owncloud}
%define oc_data_dir 	/var/lib/%{owncloud}/data
%define oc_data_pdir 	/var/lib/%{owncloud}
## Alternative FHS data location:
# %%define oc_data_dir 	/srv/%%{owncloud}/data
# %%define oc_data_pdir /srv/%%{owncloud}
%else
## traditional layout
%define oc_dir		%{oc_apache_web_dir}
%define oc_config_dir 	%{oc_apache_web_dir}/config
%define oc_data_dir 	%{oc_apache_web_dir}/data
%define oc_data_pdir 	%{oc_apache_web_dir}
%endif


%if %{fhs}
Name:           owncloud-fhs
%else
Name:           owncloud
%endif

# Downloaded from http://download.owncloud.org/community/owncloud-8.0.1.tar.bz2
# Downloaded from http://download.owncloud.org/community/testing/owncloud-8.0.3RC3.tar.bz2
# Downloaded from http://download.owncloud.org/community/owncloud-8.0.3.tar.bz2

## define prerelease %nil, if this is *not* a prerelease.
%define prerelease %nil
%define base_version 8.0.4
%define tar_version %{base_version}%{prerelease}


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

# Source0:        http://download.owncloud.org/community/testing/owncloud-%{tar_version}.tar.bz2
Source0:        http://download.owncloud.org/community/owncloud-%{tar_version}.tar.bz2
Source2:        README
Source3:        README.SELinux
Source4:        README.packaging
Source10:       robots.txt
Source11:	apache_secure_data
%if %{have_nginx}
Source12:       nginx_owncloud.conf
%endif
Source100:      obs_check_deb_spec.sh
Url:            http://www.owncloud.org
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch
Summary:        The ownCloud Server - Private file sync and share server
License:        AGPL-3.0 and MIT
Group:          Productivity/Networking/Web/Utilities

###############################################
## All build requires go into the main package.
%if 0%{?fedora_version} || 0%{?rhel_version} || 0%{?centos_version} 
BuildRequires:  httpd
%endif

%if 0%{?fedora_version} || 0%{?rhel_version} || 0%{?centos_version}
# https://github.com/owncloud/core/issues/11576
# at CentOS6, we need policycoreutils-python for semanage.
BuildRequires:	policycoreutils-python
%endif

%if 0%{?suse_version}
BuildRequires: 	fdupes apache2 unzip
%endif

###############################################
## Misc unsorted preview and database requires also go into the main package.
## You can install owncloud-* subpackages only to avoid these dependencies.
%if 0%{?fedora_version} || 0%{?rhel_version} || 0%{?centos_version}
Requires:       sqlite
%endif

%if 0%{?fedora_version}
# missing at CentOS/RHEL: do we really need that? 
Requires:       php-pear-MDB2-Driver-mysqli 
BuildRequires:  php-pear-MDB2-Driver-mysqli
%endif

%if 0%{?suse_version}
%if 0%{?suse_version} != 1110
# For all SUSEs except SLES 11
Requires:       sqlite3 php5-sqlite 
%else
# SLES 11 requires
# require mysql directly for SLES 11
Requires:       mysql php54-sqlite
%endif
%endif

%if 0%{?suse_version}
%if 0%{?suse_version} != 1110
Recommends:     php5-mysql mysql php5-imagick libreoffice-writer
%else
Recommends:     php54-mysql mysql php54-imagick
%endif
%else
# FIXME: for CentOS7, owncloud-config-mysql should pull mariadb-server
Requires:       mysql
%endif

Requires:       curl 
Requires:	%{name}-server-core   = %{version}
Requires:	%{name}-config-apache = %{version}

# must have nil on the first line to survive source-validator.
%define require_standard_apps %{nil}\
Requires:	%{name}-3rdparty              = %{version} \
Requires:	%{name}-app-activity          = %{version} \
Requires:	%{name}-app-files_encryption  = %{version} \
Requires:	%{name}-app-files_pdfviewer   = %{version} \
Requires:	%{name}-app-files_trashbin    = %{version} \
Requires:	%{name}-app-firstrunwizard    = %{version} \
Requires:	%{name}-app-templateeditor    = %{version} \
Requires:	%{name}-app-user_ldap         = %{version} \
Requires:	%{name}-app-external          = %{version} \
Requires:	%{name}-app-files_external    = %{version} \
Requires:	%{name}-app-files_sharing     = %{version} \
Requires:	%{name}-app-files_versions    = %{version} \
Requires:	%{name}-app-gallery           = %{version} \
Requires:	%{name}-app-user_webdavauth   = %{version} \
Requires:	%{name}-app-files             = %{version} \
Requires:	%{name}-app-files_locking     = %{version} \
Requires:	%{name}-app-files_texteditor  = %{version} \
Requires:	%{name}-app-files_videoviewer = %{version} \
Requires:	%{name}-app-provisioning_api  = %{version} \
Requires:	%{name}-app-user_external     = %{version}

## not recommended for Linux packages.
# Requires:	#{name}-app-updater           = #{version}


%if %{fhs}
Conflicts:      owncloud
%else
Conflicts:      owncloud-fhs
%endif


%description
ownCloud Server provides you a private file sync and share
cloud. Host this server to easily sync business or private documents
across all your devices, and share those documents with other users of
your ownCloud server on their devices.

The owncloud-fhs* packages adhere to the Linux Filesystem Hierarchy Standards 
by installing in the expected locations. The traditional packages install all 
in the web server root.

This package installs as follows:
oc_dir:        %{oc_dir}
oc_data_dir:   %{oc_data_dir}
oc_config_dir: %{oc_config_dir}

ownCloud - Your Cloud, Your Data, Your Way!  www.owncloud.org

#####################################################

%if 0%{?fedora_version} || 0%{?rhel_version} || 0%{?centos_version}
%package server-scl-php54
License:      AGPL-3.0 and MIT
Group:        Development/Libraries/PHP
Summary:      Common code server for ownCloud
%require_standard_apps

# CAUTION: Keep in sync with core/lib/private/util.php: many dependencies are defined there.

# In ownCloud 8.0, we use PHP 5.4 language features that 5.3 does not support
# the php54 from centos6-scl has a wrong version number. 1.1 or so. We cannot require php54 (>= 5.4.0)
Requires:       sqlite php54 php54-php-common php54-php-mbstring php54-php-process php54-php-xml php54-php-zip
# core#13944
Requires:	php54-php-gd
# core#13917, apache module
Requires:	php54-php 
# Class 'PDO' not found at /var/www/html/owncloud/3rdparty/doctrine/dbal/lib/Doctrine/DBAL/DriverManager.php#172
Requires:	php54-php-pdo
# core#13357, occ
Requires:	php54-php-posix

# https://github.com/owncloud/core/issues/11576
# at CentOS6, we need policycoreutils-python for semanage.
Requires:	policycoreutils-python

# The server core is common code
Provides:	owncloud-enterprise-server = %{version}
Provides:	owncloud-enterprise-server
# 
Provides:	owncloud-server-core = %{version}
Provides:	owncloud-server-core

%description  server-scl-php54
The %{name}-server package contains the common owncloud server core.
To run the servers, you either need to also install an ${name}-config-* package
or configure the server yourself for your system.

%{name}-server-scl-php54 provides an %{name}-server that is suitable for 
centos6 with php54 installed via software collections.

The owncloud-fhs* packages adhere to the Linux Filesystem Hierarchy Standards 
by installing in the expected locations. The traditional packages install all 
in the web server root.

This package installs as follows:
oc_dir:        %{oc_dir}
oc_data_dir:   %{oc_data_dir}
oc_config_dir: %{oc_config_dir}

%endif

#####################################################

%package server
License:      AGPL-3.0 and MIT
Group:        Development/Libraries/PHP
Summary:      Common code server for ownCloud
%require_standard_apps

# CAUTION: Keep in sync with core/lib/private/util.php: many dependencies are defined there.

# In ownCloud 8.0, we use PHP 5.4 language features that 5.3 does not support
%if 0%{?fedora_version} || 0%{?rhel_version} >= 6 || 0%{?centos_version} >= 6
Requires:       sqlite php >= 5.4.0 php-json php-mbstring php-process php-xml php-zip
# core#13357
Requires:	php-posix
# core#13944
Requires:	php-gd
%endif

%if 0%{?fedora_version}
# missing at CentOS/RHEL: do we really need that? 
## Requires:       php-pear-Net-Curl
## BuildRequires:  php-pear-Net-Curl
%endif

%if 0%{?fedora_version} || 0%{?rhel_version} || 0%{?centos_version}
# https://github.com/owncloud/core/issues/11576
# at CentOS6, we need policycoreutils-python for semanage.
Requires:	policycoreutils-python
# at centOS7 to avoid a blank page. Class 'PDO' not found at \/var\/www\/html\/owncloud\/3rdparty\/doctrine
Requires:       php-pdo
%endif

%if 0%{?suse_version}
%if 0%{?suse_version} != 1110
# For all SUSEs except SLES 11
# In ownCloud 8.0, we use PHP 5.4 language features that 5.3 does not support
Requires:       php5 >= 5.4.0 sqlite3 php5-mbstring php5-zip php5-json php5-posix php5-curl php5-gd php5-ctype php5-xmlreader php5-xmlwriter php5-zlib php5-pear php5-iconv
%else
# SLES 11 requires
# require mysql directly for SLES 11
# In ownCloud 8.0, we use PHP 5.4 language features that 5.3 does not support
Requires:       php54 >= 5.4.0 php54-mbstring php54-zip php54-json php54-posix php54-curl php54-gd php54-ctype php54-xmlreader php54-xmlwriter php54-zlib php54-pear php54-iconv
%endif
%endif

# The server core is common code
Provides:	owncloud-enterprise-server = %{version}
Provides:	owncloud-enterprise-server
Provides:	owncloud-server-core = %{version}
Provides:	owncloud-server-core

%description  server
The %{name}-server package contains the common owncloud server core.
To run the servers, you either need to also install an ${name}-config-* package
or configure the server yourself for your system.

The owncloud-fhs* packages adhere to the Linux Filesystem Hierarchy Standards 
by installing in the expected locations. The traditional packages install all 
in the web server root.

This package installs as follows:
oc_dir:        %{oc_dir}
oc_data_dir:   %{oc_data_dir}
oc_config_dir: %{oc_config_dir}


#####################################################
%package config-apache
Obsoletes:    %{name} < 7.9.9
License:      AGPL-3.0 and MIT
Group:        Development/Libraries/PHP
Summary:      Apache setup for ownCloud
Requires:     %{name}-server-core = %{version}

%if 0%{?fedora_version} || 0%{?rhel_version} >= 6 || 0%{?centos_version} >= 6
Requires:       httpd
%endif

%if 0%{?suse_version}
%if 0%{?suse_version} != 1110
# For all SUSEs except SLES 11
Requires:       apache2 apache2-mod_php5 
%else
# SLES 11 requires
Requires:       apache2 apache2-mod_php54
%endif
%endif

%description config-apache
This sub-package configures an apache webserver for owncloud.
Install only, if you us to make changes to your webserver setup.

The owncloud-fhs* packages adhere to the Linux Filesystem Hierarchy Standards 
by installing in the expected locations. The traditional packages install all 
in the web server root.

This package installs as follows:
oc_dir:        %{oc_dir}
oc_data_dir:   %{oc_data_dir}
oc_config_dir: %{oc_config_dir}
apache_confdir:    %{apache_confdir}
apache_serverroot: %{apache_serverroot}



#####################################################
%if %{have_nginx}
%package config-nginx
Obsoletes:    %{name} < 7.9.9
License:      AGPL-3.0 and MIT
Group:        Development/Libraries/PHP
Summary:      Apache setup for ownCloud
Requires:     %{name}-server-core = %{version}

%if 0%{?fedora_version} || 0%{?rhel_version} >= 6 || 0%{?centos_version} >= 6
# nginx is in the epel repository, register that first.
# Oops: this fails at build time: PreReq:	epel-release
Requires:       nginx
%endif

%if 0%{?suse_version}
%if 0%{?suse_version} != 1110
# For all SUSEs except SLES 11
Requires:       nginx
%else
# SLES 11 requires
Requires:       nginx
%endif
%endif

%description config-nginx
This sub-package configures an nginx webserver for owncloud.
Install only, if you us to make changes to your webserver setup.

The owncloud-fhs* packages adhere to the Linux Filesystem Hierarchy Standards 
by installing in the expected locations. The traditional packages install all 
in the web server root.

This package installs as follows:
oc_dir:        %{oc_dir}
oc_data_dir:   %{oc_data_dir}
oc_config_dir: %{oc_config_dir}
apache_confdir:    %{apache_confdir}
apache_serverroot: %{apache_serverroot}
%endif



#####################################################

%package 3rdparty
Obsoletes:    %{name} < 7.9.9
License:      AGPL-3.0 and MIT and others
Group:        Development/Libraries/PHP
Summary:      3rdparty libraries for ownCloud
Requires:     %{name}-server-core = %{version}
%description 3rdparty
3rdparty libraries needed for running ownCloud. 
Contained in separate package due to different source code licenses.

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
Obsoletes:      %{name} < 7.9.9 		\
Summary:	The ownCloud application %{1} add-on for %{name}-server \
Group:          Productivity/Networking/Web/Utilities	\
Requires:	%{name}-server-core = %{version} \
%{?2:%{2}} 					\
%description app-%{1} 				\
This package provides the ownCloud application %{1} for %{name}-server \
						\
oc_dir:        %{oc_dir} 			\
						\
%files app-%{1}					\
%defattr(0644,%{oc_user},%{oc_group},0755)	\
%dir %{oc_dir}/apps/%{1}			\
%{oc_dir}/apps/%{1}/*				\
%{nil}


%prep
%setup -q -n owncloud
cp %{SOURCE2} .
cp %{SOURCE3} .
cp %{SOURCE4} .
cp %{SOURCE10} .
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
# fix https://github.com/owncloud/enterprise/issues/570
mkdir -p $RPM_BUILD_ROOT/%{oc_dir}/assets
mkdir -p $RPM_BUILD_ROOT/%{oc_data_dir}
mkdir -p $RPM_BUILD_ROOT/%{oc_config_dir}
cp -aRf * $idir
rm -rf $idir/debian.*{install,rules,control}
mv $idir/config/* $idir/config/.??* $RPM_BUILD_ROOT/%{oc_config_dir} || true
cp -aRf .htaccess $idir
%if %{fhs}
rm -rf $idir/config $idir/data
ln -s %{oc_config_dir} $idir/config
%endif
## done in owncloud-server post install script
# ln -s %{oc_data_dir} $idir/data

# make oc_apache_web_dir a compatibility symlink
mkdir -p $RPM_BUILD_ROOT/%{apache_serverroot}
%if %{fhs}
ln -s %{oc_dir} $RPM_BUILD_ROOT/%{apache_serverroot} || true
%endif

if [ ! -f $idir/robots.txt ]; then
  install -p -D -m 644 %{SOURCE10} $idir/robots.txt
fi

%if 0%{?suse_version}
# link duplicate doc files
%fdupes -s $RPM_BUILD_ROOT/%{oc_dir}
%endif

# create the AllowOverride directive
# apache_secure_data
install -p -D -m 644 %{SOURCE11}   $RPM_BUILD_ROOT/%{apache_confdir}/owncloud.conf
sed -i -e"s|@@OC_DIR@@|%{oc_dir}|g" $RPM_BUILD_ROOT/%{apache_confdir}/owncloud.conf

%if %{have_nginx}
# nginx_owncloud.conf
install -p -D -m 644 %{SOURCE12}   $RPM_BUILD_ROOT/%{nginx_confdir}/owncloud.conf
sed -i -e"s|@@OC_DIR@@|%{oc_dir}|g" $RPM_BUILD_ROOT/%{nginx_confdir}/owncloud.conf
%endif

# relabel data directory for SELinux to allow ownCloud write access on redhat platforms
%if 0%{?fedora_version} || 0%{?rhel_version} || 0%{?centos_version}
if [ -x /usr/sbin/sestatus ] ; then \
  sestatus | grep -E '^(SELinux status|Current).*(enforcing|permissive)' > /dev/null && { 
    semanage fcontext -a -t httpd_sys_rw_content_t '%{oc_data_dir}'
    restorecon '%{oc_data_dir}'
    semanage fcontext -a -t httpd_sys_rw_content_t '%{oc_config_dir}'
    restorecon '%{oc_config_dir}'
    semanage fcontext -a -t httpd_sys_rw_content_t '%{oc_dir}/apps'
    restorecon '%{oc_dir}/apps'
    semanage fcontext -a -t httpd_sys_rw_content_t '%{oc_dir}/assets'
    restorecon '%{oc_dir}/assets'
  }
fi
true
%endif


%postun config-apache
# remove SELinux ownCloud label if not updating
[ $1 -eq 0 ] || exit 0
%if 0%{?fedora_version} || 0%{?rhel_version} || 0%{?centos_version}
if [ -x /usr/sbin/sestatus ] ; then \
  sestatus | grep -E '^(SELinux status|Current).*(enforcing|permissive)' > /dev/null && { 
    semanage fcontext -l | grep '%{oc_data_dir}' && {
      semanage fcontext -d -t httpd_sys_rw_content_t '%{oc_data_dir}'
      restorecon '%{oc_data_dir}'
    }
    semanage fcontext -l | grep '%{oc_dir}/assets' && {
      semanage fcontext -d -t httpd_sys_rw_content_t '%{oc_dir}/assets'
      restorecon '%{oc_dir}/assets'
    }
    semanage fcontext -l | grep '%{oc_config_dir}' && {
      semanage fcontext -d -t httpd_sys_rw_content_t '%{oc_config_dir}'
      restorecon '%{oc_config_dir}'
    }
    semanage fcontext -l | grep '%{oc_dir}/apps' && {
      semanage fcontext -d -t httpd_sys_rw_content_t '%{oc_dir}/apps'
      restorecon '%{oc_dir}/apps'
    }
  }
fi
true
%endif

%pre config-apache
# avoid fatal php errors, while we are changing files
# https://github.com/owncloud/core/issues/10953
#
# TBD: https://github.com/owncloud/core/issues/12125
#  The code below is bad user experience.  We should 
#  put the existing owncloud in maintenance mode, 
#  apply our changes, reload (not restart!) apache, then 
#  exit maintenance mode.
# 
# We don't do this for new installs. Only for updates.
# If the first argument to pre is 1, the RPM operation is an initial installation. 
# If the argument is 2, the operation is an upgrade from an existing version to a new one.
if [ $1 -gt 1 -a ! -s /tmp/apache_stopped_during_owncloud_install ]; then	
  echo "%{name} update: Checking for running Apache"
  # FIXME: this above should make it idempotent -- a requirement with openSUSE.
  # it does not work.
%if 0%{?suse_version} && 0
%if 0%{?suse_version} <= 1110
  rcapache2 status       | grep running > /tmp/apache_stopped_during_owncloud_install
  rcapache2 stop || true
%else
  service apache2 status | grep running > /tmp/apache_stopped_during_owncloud_install
  service apache2 stop || true
%endif
%endif
%if 0%{?fedora_version} || 0%{?rhel_version} || 0%{?centos_version}
  service httpd status | grep running > /tmp/apache_stopped_during_owncloud_install
  service httpd stop
%endif
fi
if [ -s /tmp/apache_stopped_during_owncloud_install ]; then
  echo "%{name} pre-install: Stopping Apache"
fi

%post config-apache
if [ $1 -eq 1 ]; then
    echo "%{name}-config-apache: First install complete"
else
    echo "%{name}-config-apache: Upgrade complete"
fi

# pre/postinstall/uninstall script of owncloud-config-apache-8.0.0~beta2-13.1.noarch.rpm modifies filelist!
#[  206s] filelist diff:
#[  206s] --- //.build_patchrpmcheck1	2015-01-28 19:09:33.903497088 +0000
#[  206s] +++ //.build_patchrpmcheck2	2015-01-28 19:09:34.391497077 +0000
#[  206s] @@ -4694,9 +4694,8 @@
#[  206s] -.....U...    /srv/www/htdocs/owncloud/config
#[  206s] -.M...U...    /srv/www/htdocs/owncloud/config/.htaccess
#[  206s] -.M...U...    /srv/www/htdocs/owncloud/config/config.sample.php
#[  206s] +.M.......    /srv/www/htdocs/owncloud/config/.htaccess
#[  206s] +.M.......    /srv/www/htdocs/owncloud/config/config.sample.php
#
## FIXME: probably we have no chance to chmod the files when apache comes in.
## config can be chown-ed to root:www after the initial DB config is done.
# if [ -e %{oc_data_dir} ]; then 
#   chown -R %{oc_user}:%{oc_group} %{oc_data_dir}
# fi
# if [ -e %{oc_config_dir} ]; then 
#   chown -R %{oc_user}:%{oc_group} %{oc_config_dir}
# fi

%if 0%{?suse_version}
# make sure php5 is not in APACHE_MODULES, so that we don't create dups.
perl -pani -e 's@^(APACHE_MODULES=".*)\bphp5\b@$1@' /etc/sysconfig/apache2
# add php5 to APACHE_MODULES
perl -pani -e 's@^(APACHE_MODULES=")@${1}php5 @' /etc/sysconfig/apache2
%endif

if [ -s /tmp/apache_stopped_during_owncloud_install ]; then
  echo "%{name}-config-apache: Restarting"
  ## If we stopped apache in pre section, we now should restart. -- but *ONLY* then!
  ## Maybe delegate that task to occ upgrade? They also need to handle this, somehow.
%if 0%{?suse_version}
%if 0%{?suse_version} <= 1110 || 0%{?suse_version} == 1320
  rcapache2 start || true
%else
  # FIXME: openSUSE_13.2: apache2 is neither service nor target!?
  service apache2 start || true
%endif
%endif
%if 0%{?fedora_version} || 0%{?rhel_version} || 0%{?centos_version}
  service httpd start
%endif
fi

if [ ! -s /tmp/apache_stopped_during_owncloud_install ]; then
  echo "%{name}-config-apache: Reloading"
%if 0%{?suse_version}
%if 0%{?suse_version} <= 1110 || 0%{?suse_version} == 1320
  rcapache2 reload || true
%else
  service apache2 reload || true
%endif
%endif
%if 0%{?fedora_version} || 0%{?rhel_version} || 0%{?centos_version}
  service httpd status && service httpd reload || service httpd start
%endif
fi
rm -f /tmp/apache_stopped_during_owncloud_install

%pre server
#pre_oc_7_8_upgrade

if [ $1 -eq 1 ]; then
    echo "%{name}-server: First install starting"
else
    echo "%{name}-server: Upgrade starting"
fi
# https://github.com/owncloud/core/issues/12125
if [ -x /usr/bin/php -a -f %{oc_dir}/occ ]; then
  echo "%{name}-server}: occ maintenance:mode --on"
  su %{oc_user} -s /bin/sh -c "%{oc_dir}/occ maintenance:mode --on"
  echo yes > /tmp/occ_maintenance_mode_during_owncloud_install
fi

%if %{fhs}
# Assert that oc_apache_web_dir is available to become a symlink.
# We move the folder out of the way, and place a symlink
# at oc_data_pdir/data to link back to the moved contents.
# Unless it is already a symlink.
#
# later in %post, the data folder is either created as a folder
# or taken as the exising symlink. 
if [ ! -L "%{oc_apache_web_dir}" ]; then
  if [ -e "%{oc_apache_web_dir}" ]; then
    echo "moving existing %{oc_apache_web_dir} out of the way"
    save=%{oc_apache_web_dir}.save
    if [ -e "$save" ]; then
      save=%oc_apache_web_dir.$(date +%Y%m%d%H%M%S)
    fi
    mv %{oc_apache_web_dir} $save
    mkdir -p %{oc_data_pdir}
    ln -s $save %{oc_data_dir} || true
  fi
fi
%endif
   
%preun server
%if %{fhs}
## downgrade ... ?
if [ ! -L "%{oc_apache_web_dir}" ]; then
  echo "Your webroot folder is a symbolic link. This may need manual adjustment now.\n"
  ls -lL %{oc_apache_web_dir}
fi
if [ ! -L "%{oc_data_dir}" ]; then
  echo "Your data folder is a symbolic link. This may need manual adjustment now."
  ls -lL %{oc_data_dir}
fi
%endif


%post server
if [ $1 -eq 1 ]; then
    echo "%{name}-server First install complete"
else
    echo "%{name}-server Upgrade complete"
fi
%if %{fhs}
if [ ! -d "%{oc_data_dir}" ]; then
  mkdir -p %{oc_data_dir}
fi

if [ -L "%{oc_data_dir}" ]; then
  echo > %{oc_data_pdir}/README.upgrade <<EOF
An existing owncloud installation was detected while installing %{name}-server %{version} .
Your data folder was preserved where the symbolic link 'data' points to.
This location may or may not agree with the linux Filesystem Hierarchy Standards.
We suggest to resolve the symbolic link and physically move your data folder here. 
EOF
fi
ln -s %{oc_data_dir} %{oc_dir}/data || true
chown -R %{oc_user}:%{oc_group} %{oc_data_dir}/ || true
chmod 775 %{oc_data_dir}/ || true
%endif

# https://github.com/owncloud/core/issues/12125
if [ -s /tmp/occ_maintenance_mode_during_owncloud_install ]; then
  if [ -x /usr/bin/php -a -f %{oc_dir}/occ ]; then
    # https://github.com/owncloud/core/issues/14351
    su %{oc_user} -s /bin/sh -c "%{oc_dir}/occ maintenance:mode --off"
    echo "%{name}-server}: occ upgrade"
    su %{oc_user} -s /bin/sh -c "%{oc_dir}/occ upgrade"
    su %{oc_user} -s /bin/sh -c "%{oc_dir}/occ maintenance:mode --off"
  fi
fi
rm -f /tmp/occ_maintenance_mode_during_owncloud_install

%postun
if [ 0$1 -eq 0 ]; then
  echo "An ownCloud installation consists of multiple packages."
  echo "You just uninstalled %{name} . This is what remains installed:"
  rpm -qa 'owncloud-*'
fi

%if %{have_nginx}
%post config-nginx
# ownCloud installs with user and group permissions suitable for apache
# We cannot have more than one oc_user and one oc_group
# let nginx access via group.
#
# FIXME: We should try to add acl's and only resort to chmod/chgrp
# if nothing else helps.
# CAUTION: openSUSE bails out on this postinstall script at build time. 
# Running the scripts is pointless at build time, but obs still wants to do that.
chgrp -R nginx %{oc_dir}/apps/ %{oc_config_dir}/ %{oc_data_dir}/ || true
chmod -R a+w   %{oc_dir}/apps/ %{oc_config_dir}/ %{oc_data_dir}/ || true
%endif


%clean
rm -rf "$RPM_BUILD_ROOT"

%oc_app_package activity
%oc_app_package files_encryption	Requires:php-openssl
%oc_app_package files_pdfviewer
%oc_app_package files_trashbin
%oc_app_package firstrunwizard
%oc_app_package templateeditor
%if "%_repository" == "CentOS_6_PHP54" || "%_repository" == "RHEL_6_PHP54"
# FIXME: should have the same for _PHP55 and _PHP56 ? Or make Substitute: work in prjconf ?
%oc_app_package user_ldap		Requires:php54-php-ldap
%else
%oc_app_package user_ldap		Requires:php-ldap
%endif
%oc_app_package external
%oc_app_package files_external
%oc_app_package files_sharing
%oc_app_package files_versions
%oc_app_package gallery
%oc_app_package updater
%oc_app_package user_webdavauth
%oc_app_package files
%oc_app_package files_locking
%oc_app_package files_texteditor
%oc_app_package files_videoviewer
%oc_app_package provisioning_api
%oc_app_package user_external		Requires:owncloud-app-external


%files
%defattr(-,root,root,-)
%doc README README.packaging


%if 0%{?fedora_version} || 0%{?rhel_version} || 0%{?centos_version}
%files server-scl-php54
%defattr(0644,root,%{oc_group},0755)
%doc README README.SELinux
%dir %{oc_dir}
%doc %{oc_dir}/AUTHORS
%doc %{oc_dir}/COPYING-AGPL
%doc %{oc_dir}/README*
%{oc_dir}/core
%{oc_dir}/db_structure.xml
%{oc_dir}/index.php
%{oc_dir}/lib
%{oc_dir}/ocs
%{oc_dir}/public.php
%{oc_dir}/remote.php
%{oc_dir}/settings
%{oc_dir}/status.php
%{oc_dir}/themes
%{oc_dir}/cron.php
%{oc_dir}/robots.txt
%{oc_dir}/index.html
%{oc_dir}/console.php
%{oc_dir}/version.php
%if %{fhs}
## symlink. Only included if it is a link.
%{oc_dir}/config
%endif
%defattr(0755,%{oc_user},%{oc_group},0775)
%{oc_dir}/occ
%dir %{oc_dir}/apps
%exclude %{oc_dir}/apps/*
%{oc_config_dir}/*
%{oc_config_dir}/.htaccess
%if %{fhs}
## data is a symlink?
%dir %{oc_data_pdir}
%else
%dir %{oc_data_dir}
%endif
%dir %{oc_config_dir}
%endif


%files server
%defattr(0644,root,%{oc_group},0755)
%doc README README.SELinux
%dir %{oc_dir}
%doc %{oc_dir}/AUTHORS
%doc %{oc_dir}/COPYING-AGPL
%doc %{oc_dir}/README*
%{oc_dir}/core
%{oc_dir}/db_structure.xml
%{oc_dir}/index.php
%{oc_dir}/lib
%{oc_dir}/ocs
%{oc_dir}/public.php
%{oc_dir}/remote.php
%{oc_dir}/settings
%{oc_dir}/status.php
%{oc_dir}/themes
%{oc_dir}/cron.php
%{oc_dir}/robots.txt
%{oc_dir}/index.html
%{oc_dir}/console.php
%{oc_dir}/version.php
%if %{fhs}
## symlink. Only included if it is a link.
%{oc_dir}/config
%endif
%defattr(0755,%{oc_user},%{oc_group},0775)
%{oc_dir}/occ
%dir %{oc_dir}/assets
%dir %{oc_dir}/apps
%exclude %{oc_dir}/apps/*
%{oc_config_dir}/*
%{oc_config_dir}/.htaccess
%if %{fhs}
## data is a symlink?
%dir %{oc_data_pdir}
%else
%dir %{oc_data_dir}
%endif
%dir %{oc_config_dir}


%files config-apache
%defattr(-,%{oc_user},%{oc_group},0775)
%config %attr(0644,root,root) %{apache_confdir}/owncloud.conf
%{oc_dir}/.htaccess
%if %{fhs}
# backwards compat symlink, (only included, if it is a link :-))
%{oc_apache_web_dir}
%endif


%if %{have_nginx}
%files config-nginx
%defattr(-,%{oc_user},%{oc_group},0775)
# CentOS: /etc/nginx/conf.d/
%config %attr(0644,root,root) /etc/nginx/conf.d/owncloud.conf
%dir /etc/nginx
%dir /etc/nginx/conf.d
%endif


%files 3rdparty
%defattr(0644,%{oc_user},%{oc_group},0755)
%dir %{oc_dir}/3rdparty
%{oc_dir}/3rdparty/*

%changelog

