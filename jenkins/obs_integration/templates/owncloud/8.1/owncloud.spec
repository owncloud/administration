#
# spec file for package owncloud
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
#
# Please submit bugfixes, issues or comments via http://github.com/owncloud/
#

# 0, 1: support nginx as alternative to apache
%define have_nginx 0

# name used as apache alias and topdir for php code.
%define owncloud	owncloud	

%if 0%{?rhel} == 6 || 0%{?rhel_version} == 600 || 0%{?centos_version} == 600
%define statedir	/var/run
%else
%define statedir	/run
%endif

# CAUTION: keep in sync with debian.rules
### apache variables
%if 0%{?suse_version}
%define nginx_confdir /etc/nginx/conf.d
%define apache_serverroot /srv/www/htdocs
%define apache_confdir /etc/apache2/conf.d
%define oc_user wwwrun
%define oc_group www
%else
%if 0%{?fedora_version} || 0%{?rhel_version} || 0%{?rhel} || 0%{?centos_version}
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
## traditional layout
%define oc_dir		%{oc_apache_web_dir}
%define oc_config_dir 	%{oc_apache_web_dir}/config
%define oc_data_dir 	%{oc_apache_web_dir}/data
%define oc_data_pdir 	%{oc_apache_web_dir}

%define ocphp		php
%define ocphp_bin	/usr/bin
%define ochttpd		httpd
%if "%_repository" == "CentOS_6_PHP54" || "%_repository" == "RHEL_6_PHP54"
%define ocphp		php54-php
%define ocphp_bin	/opt/rh/php54/root/usr/bin
%define ochttpd		httpd
%endif
%if "%_repository" == "CentOS_6_PHP55" || "%_repository" == "RHEL_6_PHP55" 
%define ocphp		php55-php
%define ocphp_bin	/opt/rh/php55/root/usr/bin
%define ochttpd		httpd24-httpd
%endif
%if "%_repository" == "CentOS_6_PHP56" || "%_repository" == "RHEL_6_PHP56"
%define ocphp		rh-php56-php
%define ocphp_bin	/opt/rh/php56/root/usr/bin
%define ochttpd		httpd24-httpd
%endif

Name:           owncloud

# Downloaded from http://download.owncloud.org/community/testing/owncloud-8.1.0alpha2.tar.bz2

## define prerelease %nil, if this is *not* a prerelease.
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

Source0:        [% SOURCE_TAR_URL %]
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

%if 0%{?fedora_version} || 0%{?rhel} || 0%{?rhel_version} || 0%{?centos_version}
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
%if 0%{?fedora_version} || 0%{?rhel} || 0%{?rhel_version} || 0%{?centos_version}
Requires:       sqlite
%endif

%if 0%{?fedora_version}
# missing at CentOS/RHEL: do we really need that?
Requires:       php-pear-MDB2-Driver-mysqli
BuildRequires:  php-pear-MDB2-Driver-mysqli
%endif

%if 0%{?suse_version}
# SUSE does not include the fileinfo module in php-common.
Requires:       php-fileinfo
%if 0%{?suse_version} != 1110
# For all SUSEs except SLES 11
## PreReq instead of Requires here, to survive build check for idemnpotent scripts.
## Requires(post):       sqlite3 php5-sqlite
%else
# SLES 11 requires
# require mysql directly for SLES 11
## Requires(post):       mysql php54-sqlite
%endif
%endif

%if 0%{?suse_version}
%if 0%{?suse_version} != 1110
## Recommends:     php5-mysql mysql php5-imagick libreoffice-writer
%else
## Recommends:     php54-mysql mysql php54-imagick
%endif
%endif
Requires:       curl


## not recommended for Linux packages.
Obsoletes:	%{name}-app-updater           < %{version}

# ex-apps:
Obsoletes:	%{name}-app-files_encryption  < %{version}

# migrate from special *-scl-* packages to normal
# https://github.com/owncloud/enterprise/issues/1077
Obsoletes:  owncloud-server-scl-php54 < %{version}

# Finally require all subpackages to make a standalone system.
Requires:       %{name}-server        = %{version}
Requires:	%{name}-config-apache = %{version}

%description
ownCloud Server provides you a private file sync and share
cloud. Host this server to easily sync business or private documents
across all your devices, and share those documents with other users of
your ownCloud server on their devices.

File system layout here is identical with tar or zip distributions.

This package installs as follows:
oc_dir:        %{oc_dir}
oc_data_dir:   %{oc_data_dir}
oc_config_dir: %{oc_config_dir}

ownCloud - Your Cloud, Your Data, Your Way!  www.owncloud.org

#####################################################

%package server
License:      AGPL-3.0 and MIT
Group:        Development/Libraries/PHP
Summary:      Common code server for ownCloud

# CAUTION: Keep in sync with core/lib/private/util.php: many dependencies are defined there.

# In ownCloud 8.0, we use PHP 5.4 language features that 5.3 does not support
%if 0%{?fedora_version} || 0%{?rhel} || 0%{?rhel_version} || 0%{?centos_version}
Requires:       sqlite
Requires:       %{ocphp} >= 5.4.0
Requires:       %{ocphp} < 7.0.0
Requires:       %{ocphp}-json %{ocphp}-mbstring %{ocphp}-process %{ocphp}-xml %{ocphp}-zip
# core#13357, core#13944
Requires:	%{ocphp}-posix %{ocphp}-gd
%endif

# apps/user_ldap		
Requires:	%{ocphp}-ldap

%if 0%{?fedora_version}
# missing at CentOS/RHEL: do we really need that?
## Requires:       php-pear-Net-Curl
## BuildRequires:  php-pear-Net-Curl
%endif

%if 0%{?fedora_version} || 0%{?rhel} || 0%{?rhel_version} || 0%{?centos_version}
# https://github.com/owncloud/core/issues/11576
# at CentOS6, we need policycoreutils-python for semanage.
Requires:	policycoreutils-python
# at centOS7 to avoid a blank page. Class 'PDO' not found at \/var\/www\/html\/owncloud\/3rdparty\/doctrine
Requires:       %{ocphp}-pdo
%endif

%if 0%{?suse_version}
%if 0%{?suse_version} != 1110
# For all SUSEs except SLES 11
# In ownCloud 8.0, we use PHP 5.4 language features that 5.3 does not support
## Requires:       sqlite3
Requires:       php5 >= 5.4.0 php5-mbstring php5-zip php5-json php5-posix php5-curl php5-gd php5-ctype php5-xmlreader php5-xmlwriter php5-zlib php5-pear php5-iconv
%else
# SLES 11 requires
# require mysql directly for SLES 11
# In ownCloud 8.0, we use PHP 5.4 language features that 5.3 does not support
Requires:       php54 >= 5.4.0 php54-mbstring php54-zip php54-json php54-posix php54-curl php54-gd php54-ctype php54-xmlreader php54-xmlwriter php54-zlib php54-pear php54-iconv
%endif
%endif

# apps merged back into owncloud-server to resolve https://github.com/owncloud/core/issues/18043
Obsoletes:      %{name}-app-activity		< %{version}
Obsoletes:      %{name}-app-files_pdfviewer	< %{version}
Obsoletes:      %{name}-app-files_trashbin	< %{version}
Obsoletes:      %{name}-app-firstrunwizard	< %{version}
Obsoletes:      %{name}-app-templateeditor	< %{version}
Obsoletes:      %{name}-app-user_ldap		< %{version}
Obsoletes:      %{name}-app-external		< %{version}
Obsoletes:      %{name}-app-files_external	< %{version}
Obsoletes:      %{name}-app-files_sharing	< %{version}
Obsoletes:      %{name}-app-files_versions	< %{version}
Obsoletes:      %{name}-app-gallery		< %{version}
Obsoletes:      %{name}-app-user_webdavauth	< %{version}
Obsoletes:      %{name}-app-files		< %{version}
Obsoletes:      %{name}-app-files_locking	< %{version}
Obsoletes:      %{name}-app-files_texteditor	< %{version}
Obsoletes:      %{name}-app-files_videoviewer	< %{version}
Obsoletes:      %{name}-app-provisioning_api	< %{version}
Obsoletes:      %{name}-app-user_external	< %{version}
Obsoletes:      %{name}-app-encryption		< %{version}
# 3rdparty merged back into owncloud-server
Obsoletes:      %{name}-3rdparty		< %{version}

%description  server
The %{name}-server package contains the common owncloud server core and all bundled 
community apps.
To run the servers, you either need to also install ${name}-config-* packages
or configure the web server and database yourself.

The package %{name} requires %{name}-server and pulls in all required and recommended
dependencies for running owncloud on a single system. Including webserver config and database.

File system layout here is identical with tar or zip distributions.

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
Requires:     %{name}-server = %{version}

%if 0%{?fedora_version} || 0%{?rhel} || 0%{?rhel_version} || 0%{?centos_version}
Requires:       %{ochttpd}
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

File system layout here is identical with tar or zip distributions.

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
Requires:     %{name}-server = %{version}

%if 0%{?fedora_version} || 0%{?rhel} || 0%{?rhel_version} || 0%{?centos_version}
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

File system layout here is identical with tar or zip distributions.

This package installs as follows:
oc_dir:        %{oc_dir}
oc_data_dir:   %{oc_data_dir}
oc_config_dir: %{oc_config_dir}
apache_confdir:    %{apache_confdir}
apache_serverroot: %{apache_serverroot}
%endif



#####################################################

%prep
%setup -q -n owncloud
cp %{SOURCE2} .
cp %{SOURCE3} .
cp %{SOURCE4} .
cp %{SOURCE10} .
#%%patch0 -p0

# obs_check_deb_spec.sh
pushd $RPM_SOURCE_DIR
# TODO: since merge back of all apps: is this still needed?
sh %{SOURCE100}
popd

echo "repository: |%{_repository}|"
echo "Requires:       %{ocphp} >= 5.4.0"
 echo "Requires:      %{ocphp} < 7.0.0"

# remove .bower.json .bowerrc .gitattributes .gitmodules
find . -name .bower\* -print -o -name .git\* -print | xargs rm
# seen in 8.1.10~rc1 tar:
rm -rf Jenkinsfile

if [ ! -d %{statedir} ]; then
  echo ERROR: %{statedir} does not exist here.
fi
ls -la %{statedir}

%build
# obsolete stuff, to be removed from tar-balls.
rm -f indie.json
rm -f l10n/l10n.pl

# do not build updater app.
rm -rf apps/updater

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
## done in owncloud-server post install script
# ln -s %{oc_data_dir} $idir/data

# make oc_apache_web_dir a compatibility symlink
mkdir -p $RPM_BUILD_ROOT/%{apache_serverroot}

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
%if 0%{?fedora_version} || 0%{?rhel} || 0%{?rhel_version} || 0%{?centos_version}
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
%if 0%{?fedora_version} || 0%{?rhel} || 0%{?rhel_version} || 0%{?centos_version}
if [ -x /usr/sbin/sestatus ] ; then \
  sestatus | grep -E '^(SELinux status|Current).*(enforcing|permissive)' > /dev/null && {
    semanage fcontext -l | grep '%{oc_data_dir}' && {
      semanage fcontext -d -t httpd_sys_rw_content_t '%{oc_data_dir}'
      restorecon '%{oc_data_dir}'
    }
    semanage fcontext -l | grep '%{oc_config_dir}' && {
      semanage fcontext -d -t httpd_sys_rw_content_t '%{oc_config_dir}'
      restorecon '%{oc_config_dir}'
    }
    semanage fcontext -l | grep '%{oc_dir}/apps' && {
      semanage fcontext -d -t httpd_sys_rw_content_t '%{oc_dir}/apps'
      restorecon '%{oc_dir}/apps'
    }
    semanage fcontext -l | grep '%{oc_dir}/assets' && {
      semanage fcontext -d -t httpd_sys_rw_content_t '%{oc_dir}/assets'
      restorecon '%{oc_dir}/assets'
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
if [ $1 -gt 1 -a ! -s %{statedir}/apache_stopped_during_owncloud_install ]; then	
  echo "%{name} update: Checking for running Apache"
  # FIXME: this above should make it idempotent -- a requirement with openSUSE.
  # it does not work.
%if 0%{?suse_version} && 0
%if 0%{?suse_version} <= 1110
  rcapache2 status       | grep running > %{statedir}/apache_stopped_during_owncloud_install
  rcapache2 stop || true
%else
  service apache2 status | grep running > %{statedir}/apache_stopped_during_owncloud_install
  service apache2 stop || true
%endif
%endif
%if 0%{?fedora_version} || 0%{?rhel} || 0%{?rhel_version} || 0%{?centos_version}
  service %{ochttpd} status | grep running > %{statedir}/apache_stopped_during_owncloud_install
  service %{ochttpd} stop
%endif
fi
if [ -s %{statedir}/apache_stopped_during_owncloud_install ]; then
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

if [ -s %{statedir}/apache_stopped_during_owncloud_install ]; then
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
%if 0%{?fedora_version} || 0%{?rhel} || 0%{?rhel_version} || 0%{?centos_version}
  service %{ochttpd} start
%endif
fi

if [ ! -s %{statedir}/apache_stopped_during_owncloud_install ]; then
  echo "%{name}-config-apache: Reloading"
%if 0%{?suse_version}
%if 0%{?suse_version} <= 1110 || 0%{?suse_version} == 1320
  rcapache2 reload || true
%else
  service apache2 reload || true
%endif
%endif
%if 0%{?fedora_version} || 0%{?rhel} || 0%{?rhel_version} || 0%{?centos_version}
  service %{ochttpd} status && service %{ochttpd} reload || service %{ochttpd} start
%endif
fi
rm -f %{statedir}/apache_stopped_during_owncloud_install

%pre server
#pre_oc_7_8_upgrade

if [ $1 -eq 1 ]; then
    echo "%{name}-server: First install starting"
else
    echo "%{name}-server: Upgrade starting"
fi
# https://github.com/owncloud/core/issues/12125
if [ -x %{ocphp_bin}/php -a -f %{oc_dir}/occ ]; then
  echo "%{name}-server: occ maintenance:mode --on"
  su %{oc_user} -s /bin/sh -c "cd %{oc_dir}; PATH=%{ocphp_bin}:$PATH php ./occ maintenance:mode --on" || true
  echo yes > %{statedir}/occ_maintenance_mode_during_owncloud_install
fi

%preun server

%post server
if [ $1 -eq 1 ]; then
    echo "%{name}-server First install complete"
else
    echo "%{name}-server Upgrade complete"
fi

# must ignore errors with e.g.  '|| true' or we die in openSUSEs horrible post build checks.
# https://github.com/owncloud/core/issues/12125 needed occ calls.
# https://github.com/owncloud/core/issues/17583 correct occ usage.
if [ -s %{statedir}/occ_maintenance_mode_during_owncloud_install ]; then
  # https://github.com/owncloud/core/pull/19508
  # https://github.com/owncloud/core/pull/19661
  echo  "Leaving server in maintenance mode. Please run occ upgrade manually."
  echo  ""
  echo  "See https://doc.owncloud.org/server/8.1/admin_manual/maintenance/upgrade.html"
  echo  ""
fi
rm -f %{statedir}/occ_maintenance_mode_during_owncloud_install

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

%files
%defattr(-,root,root,-)
%doc README README.packaging

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
%{oc_dir}/ocs-provider
%{oc_dir}/public.php
%{oc_dir}/remote.php
%{oc_dir}/settings
%{oc_dir}/status.php
%{oc_dir}/cron.php
%{oc_dir}/robots.txt
%{oc_dir}/index.html
%{oc_dir}/console.php
%{oc_dir}/version.php

%defattr(0755,%{oc_user},%{oc_group},0775)
%{oc_dir}/themes
%{oc_dir}/occ
%dir %{oc_dir}/assets
%dir %{oc_dir}/apps
%{oc_dir}/apps/*
%{oc_config_dir}/*
%{oc_config_dir}/.htaccess
%{oc_dir}/.htaccess
%dir %{oc_data_dir}
%dir %{oc_config_dir}

%dir %{oc_dir}/3rdparty
%{oc_dir}/3rdparty/*

%files config-apache
%defattr(-,%{oc_user},%{oc_group},0775)
%config %attr(0644,root,root) %{apache_confdir}/owncloud.conf


%if %{have_nginx}
%files config-nginx
%defattr(-,%{oc_user},%{oc_group},0775)
# CentOS: /etc/nginx/conf.d/
%config %attr(0644,root,root) /etc/nginx/conf.d/owncloud.conf
%dir /etc/nginx
%dir /etc/nginx/conf.d
%endif


%changelog

