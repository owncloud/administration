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

Name:           [% PACKNAME %]

## define prerelease % nil, if this is *not* a prerelease. Caution: always lower case beta rc.
%define prerelease [% PRERELEASE %]
%define base_version [% VERSION %]
## don't enable support_php7 for now, it takes precendence over scl_php54
%define support_php7 0

%if 0%{?centos_version} == 600 || 0%{?fedora_version} || "%{prerelease}" == ""
# For beta and rc versions we use the ~ notation, as documented in
# http://en.opensuse.org/openSUSE:Package_naming_guidelines
Version:       	%{base_version}
%define oc_version %{base_version}
%if "%{prerelease}" == ""
Release:        0
%else
Release:       	0.<CI_CNT>.<B_CNT>.%{prerelease}
%endif
%else
Version:       	%{base_version}~%{prerelease}
%define oc_version %{base_version}~%{prerelease}
Release:        0
%endif

Url:            http://www.owncloud.org
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch
Summary:        The server - private file sync and share server
License:        AGPL-3.0 and MIT
Group:          Productivity/Networking/Web/Utilities
# No Source0: needed when there are no prep setup build sections.

Requires:	%{name}-deps  >= %{oc_version}
Requires:	%{name}-files >= %{oc_version}

%description
ownCloud Server Enterprise Edition provides you a private file sync and share
cloud. Host this server to easily sync business or private documents
across all your devices, and share those documents with other users of
your ownCloud server on their devices.

ownCloud - Your Cloud, Your Data, Your Way!  www.owncloud.org

#####################################################

%if 0%{?rhel} == 600 || 0%{?rhel_version} == 600 || 0%{?centos_version} == 600
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
%if 0%{?fedora_version} || 0%{?rhel} || 0%{?rhel_version} || 0%{?centos_version}
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
%define oc_apache_web_dir 	%{apache_serverroot}/owncloud

# CAUTION: keep in sync with debian.rules
## traditional layout
%define oc_dir		%{oc_apache_web_dir}
%define oc_config_dir 	%{oc_apache_web_dir}/config
%define oc_data_dir 	%{oc_apache_web_dir}/data
%define oc_data_pdir 	%{oc_apache_web_dir}

%define ocphp		php
%define ocphp_bin	/usr/bin
%define ocphp_deps_name	%{name}-deps-php5
%define ochttpd		httpd

%if "%_repository" == "CentOS_6_SCL_PHP54" || "%_repository" == "RHEL_6_SCL_PHP54" || "%_repository" == "CentOS_6_PHP54" || "%_repository" == "RHEL_6_PHP54"
%define ocphp		php54-php
%define ocphp_bin	/opt/rh/php54/root/usr/bin
%define ocphp_deps_name	%{name}-deps-scl-php54
%define ochttpd		httpd
%endif

%if "%_repository" == "CentOS_6_SCL_PHP55" || "%_repository" == "RHEL_6_SCL_PHP55" || "%_repository" == "CentOS_6_PHP55" || "%_repository" == "RHEL_6_PHP55"
%define ocphp		php55-php
%define ocphp_bin	/opt/rh/php55/root/usr/bin
%define ocphp_deps_name	%{name}-deps-scl-php55
%define ochttpd		httpd24-httpd
%endif

%if "%_repository" == "CentOS_6_SCL_PHP56" || "%_repository" == "RHEL_6_SCL_PHP56" || "%_repository" == "CentOS_6_PHP56" || "%_repository" == "RHEL_6_PHP56"
%define ocphp		rh-php56-php
%define ocphp_bin	/opt/rh/php56/root/usr/bin
%define ocphp_deps_name	%{name}-deps-scl-php56
%define ochttpd		httpd24-httpd
%endif

#####################################################

%package -n %{ocphp_deps_name}
Provides: %{name}-deps

Requires:       curl
# apps/user_ldap		
Requires:	%{ocphp}-ldap

%if 0%{?fedora_version} || 0%{?rhel} || 0%{?rhel_version} || 0%{?centos_version}
Requires:       %{ochttpd}
Requires:       sqlite
Requires:       %{ocphp}-mysql
Requires:       %{ocphp} >= 5.4.0
Requires:       %{ocphp}-json %{ocphp}-mbstring %{ocphp}-process %{ocphp}-xml %{ocphp}-zip
# core#13357, core#13944
Requires:	%{ocphp}-posix %{ocphp}-gd
# https://github.com/owncloud/core/issues/11576
# at CentOS6, we need policycoreutils-python for semanage.
Requires:	policycoreutils-python
# at centOS7 to avoid a blank page. Class 'PDO' not found at \/var\/www\/html\/owncloud\/3rdparty\/doctrine
Requires:       %{ocphp}-pdo
%endif

%if 0%{?suse_version}
Requires:       php-fileinfo
Requires:       php5 >= 5.4.0  php5-mbstring  php5-zip  php5-json  php5-posix  php5-curl  php5-gd  php5-ctype  php5-xmlreader  php5-xmlwriter  php5-zlib php5-pear php5-iconv php5-pdo
Requires:       apache2 apache2-mod_php5
Requires:       sqlite3 php5-sqlite
Recommends:     php5-mysql mysql
%endif

Summary: Dependencies for php5
%description -n %{ocphp_deps_name}
%{summary}.


#####################################################

%package -n %{name}-deps-php7
Provides: %{name}-deps
Requires: php7
Summary: Dependencies for php7
%description -n %{name}-deps-php7
%{summary}.

#####################################################

%prep
# setup -q -n owncloud

%build
echo build

%install
# We had silently skipped files under %{_docdir} on both SUSE and CentOS. Do not use that for our
# apache template. Prefer /usr/share/lib, it always installs flawlessly.
%define oc_docdir_base /usr/share/lib
%define oc_docdir %{oc_docdir_base}/%{name}-files-%{base_version}

echo install

%clean
rm -rf "$RPM_BUILD_ROOT"

%pre -n %{ocphp_deps_name}
# avoid fatal php errors, while we are changing files
# https://github.com/owncloud/core/issues/10953
#
# https://github.com/owncloud/core/issues/12125
#  We put the existing owncloud in maintenance mode,
#  apply our changes, reload (not restart!) apache, then
#  exit maintenance mode.

## server upgrade
if [ $1 -eq 1 ]; then
    echo "%{name} pre-install: First install starting"
else
    echo "%{name} pre-install: installing upgrade ..."
fi
# https://github.com/owncloud/core/issues/12125
if [ -x %{ocphp_bin}/php -a -s %{oc_dir}/config/config.php ]; then
  echo "%{name} pre-install: occ maintenance:mode --on"
  su %{oc_user} -s /bin/sh -c "cd %{oc_dir}; PATH=%{ocphp_bin}:$PATH php ./occ maintenance:mode --on" || true
  echo yes > %{statedir}/occ_maintenance_mode_during_owncloud_install
fi



%post -n %{ocphp_deps_name}
if [ -f /etc/sysconfig/apache2 ]; then
%if 0%{?suse_version}
## FIXME: use a2enmod instead??
# a2enmod php5
# a2enmod rewrite
## make sure php5 is not in APACHE_MODULES, so that we don't create dups.
perl -pani -e 's@^(APACHE_MODULES=".*)\bphp5\b@$1@' /etc/sysconfig/apache2
# add php5 to APACHE_MODULES
perl -pani -e 's@^(APACHE_MODULES=")@${1}php5 @' /etc/sysconfig/apache2
%endif
  :
fi

# install our apache config
if [ -f "%{oc_docdir}/owncloud-config-apache.conf.default" ]; then
  echo "install owncloud.conf into apache, if missing"
  if [ -d %{apache_confdir} -a ! -f %{apache_confdir}/owncloud.conf ]; then
    cp %{oc_docdir}/owncloud-config-apache.conf.default %{apache_confdir}/owncloud.conf
    chown root:root %{apache_confdir}/owncloud.conf
    chmod 644 %{apache_confdir}/owncloud.conf
  fi
fi

if [ ! -s %{statedir}/need_apache_reload_after_owncloud_install ]; then	
%if 0%{?suse_version}
  (service apache2 status | grep running > %{statedir}/need_apache_reload_after_owncloud_install) || true
%endif
%if 0%{?fedora_version} || 0%{?rhel} || 0%{?rhel_version} || 0%{?centos_version}
  (service %{ochttpd} status | grep running > %{statedir}/need_apache_reload_after_owncloud_install) || true
%endif
fi

if [ -s %{statedir}/need_apache_reload_after_owncloud_install ]; then
  echo "%{name} post-install: apache: Reloading"
%if 0%{?suse_version}
  service apache2 reload || true
%endif
%if 0%{?fedora_version} || 0%{?rhel} || 0%{?rhel_version} || 0%{?centos_version}
  service %{ochttpd} status && service %{ochttpd} reload || service %{ochttpd} start || true
%endif
fi
rm -f %{statedir}/need_apache_reload_after_owncloud_install

# must ignore errors with e.g.  '|| true' or we die in openSUSEs horrible post build checks.
# https://github.com/owncloud/core/issues/12125 needed occ calls.
# https://github.com/owncloud/core/issues/17583 correct occ usage.
if [ -s %{statedir}/occ_maintenance_mode_during_owncloud_install ]; then
    # https://github.com/owncloud/core/pull/19508
    # https://github.com/owncloud/core/pull/19661
    echo  "Leaving server in maintenance mode. Please run occ upgrade manually."
    echo  ""
    echo  "See https://doc.owncloud.org/server/9.0/admin_manual/maintenance/upgrade.html"
    echo  ""
fi
rm -f %{statedir}/occ_maintenance_mode_during_owncloud_install

if [ $1 -eq 1 ]; then
    echo "Asserting file permission during first install"
    # CAUTION: if owncloud-files was installed before httpd, everything belongs to root:root.
    # Mimic here again, what the files section there would have done:
    chown -R %{oc_user}:%{oc_group} %{oc_config_dir} %{oc_data_dir} %{oc_dir}/apps || true
fi


# no binary packages are generated without a files section.
%files
%files -n %{ocphp_deps_name}
%if 0%{?support_php7}
%files -n %{name}-deps-php7
%endif

%changelog

