#
# spec file for package owncloud-enterprise
#
# Copyright (c) 2012-2014 ownCloud, Inc.
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

# CAUTION: keep in sync with oc-eval-license
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
# switch this to .../owncloud some day?
%define owncloud_serverroot %{apache_serverroot}/owncloud-enterprise


Name:           owncloud-enterprise

# Downloaded from http://download.owncloud.com/internal/7.0.2/owncloud-enterprise-beta2.zip

## define prerelease %nil, if this is *not* a prerelease.
%define prerelease [% PRERELEASE %]
%define base_version [% VERSION %]
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

# CAUTION: keep in sync with enterprise/appliance/refresh_eval_appliance.pl
# FROM:	http://download.owncloud.com/internal/7.0.4/owncloud_enterprise-7.0.4.tar.bz2
Source0:        [% SOURCE_TAR_URL %]
Source1:        apache_secure_data
Source2:        README
Source3:        README.SELinux
Source4:        robots.txt
Url:            http://www.owncloud.com
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch
Summary:        The ownCloud Enterprise Edition - Server 
License:        ownCloud Commercial License
Group:          Productivity/Networking/Web/Utilities

# https://github.com/owncloud/windows_network_drive/issues/20#issuecomment-52514257
Requires: php-soap, php5-libsmbclient >= 0.5.0 

# https://github.com/owncloud/enterprise/issues/391
Requires:	php-soap, php-ftp, php-gmp, samba-client
BuildRequires:	php-soap, php-ftp, php-gmp, samba-client
Requires:	php-ldap
## We build with Webtatic. They don't provide php54-php-ldap 
## FIXME: We should build with SCL or remi. http://github.com/owncloud/enterprise/issues/681
# BuildRequires:	php-ldap
Obsoletes:	owncloud-enterprise-3rdparty <= 7.0.3

# https://github.com/owncloud/core/issues/10532
%if 0%{?suse_version} > 1110
BuildRequires:	php5-APCu
Requires: 	php5-APCu
# needed in in core/lib/private/image.php  ??
# Requires:       php-exif
# BuildRequires:  php-exif
%endif
%if 0%{?centos_version} == 600
# CAUTION: see also Substitutes in meta prjconf!
#          CentOS_6_PHP5{4,5,6} use substitute to php-pecl(APC) / php-pecl(apcu) here.
#          and decide the choice with Prefer: php5{4,5,6}w-pecl-apc(u) 
#          This way we effectivly have 
#          - a webtatic specific BuildRequires: php5{4,5,6}w-pecl-apc(u)
#          - a generic Requires: php-pecl(APC) / php-pecl(apcu)
BuildRequires: 	php-pecl-apc
Requires: 	php-pecl-apc
# does not exist in centos_version == 700
%endif

%if 0%{?fedora_version} || 0%{?rhel_version} >= 600 || 0%{?centos_version} >= 600
# At CentOS6, php includes mod_php5
BuildRequires: httpd 
Requires:      httpd sqlite php >= 5.3.3 php-json php-mbstring php-process php-gd php-xml php-zip php-pdo php-xml

%if 0%{?fedora_version}
# These two are missing at CentOS/RHEL: do we really need them? 
Requires:       php-pear-Net-Curl php-pear-MDB2-Driver-mysqli 
BuildRequires:  php-pear-Net-Curl php-pear-MDB2-Driver-mysqli
%endif
%endif

%if 0%{?rhel_version} == 5 || 0%{?centos_version} == 5
Requires:       httpd sqlite php53 >= 5.3.3 php53-json php53-mbstring php53-process php53-pear-Net-Curl php53-gd php53-pear-MDB2-Driver-mysqli php53-xml php53-zip php53-fileinfo
%endif

%if 0%{?suse_version}
BuildRequires: 	fdupes
%if 0%{?suse_version} != 1110
# For all SUSEs except SLES 11
Requires:       apache2 apache2-mod_php5 php5 >= 5.3.3 sqlite3 php5-sqlite php5-mbstring php5-zip php5-json php5-posix curl php5-curl php5-gd php5-ctype php5-xmlreader php5-xmlwriter php5-zlib php5-pear php5-iconv
BuildRequires:  apache2 unzip
%else
# SLES 11 requires
# require mysql directly for SLES 11
Requires:       apache2 apache2-mod_php53 php53 >= 5.3.3 mysql php53-mbstring php53-zip php53-json curl php53-curl php53-gd php53-ctype php53-xmlreader php53-xmlwriter php53-zlib php53-pear php53-iconv php53-fileinfo
BuildRequires:  apache2 unzip php53-fileinfo
%if "%_repository" == "SLE_11_SP3"
Requires:  php53-sqlite
BuildRequires:  php53-sqlite
%endif	# SLE_11_SP3
%endif	# 1110
%endif  # suse_version

Requires:       curl 
# Requires:       %% {name}-3rdparty
%if 0%{?suse_version}
%if 0%{?suse_version} != 1110
Recommends:     php5-mysql mysql php5-imagick 
# Recommends:	 libreoffice
%else
Recommends:     php53-mysql mysql php53-imagick
%endif
%else
Requires:       mysql
%endif

%description
ownCloud Enterprise Edition provides an Enterprise class file sync and share
solution that is controlled and managed by you. Hosted on your servers or
private cloud, ownCloud integrates with your existing infrastructure - from
authentication and databases, to existing document storage repositories and
log management - and is highly extensible via the ownCloud App Architecture.


At the same time, ownCloud provides employees and end users anywhere,
anytime access to the files they need to get the job done - via mobile apps,
desktop sync clients, WebDAV clients and the web. With ownCloud, employees
can easily view and share documents and information critical to the
business, in a secure, flexible and controlled architecture - one that is
consistent with IT policies, procedures and regulatory requirements. 

For more information, visit www.owncloud.com

#package 3rdparty
# License:      AGPL-3.0 and MIT and PHP-3.01 and LGPL-2.1 and GPL-3.0 and BSD-3c
# Group:        Development/Libraries/PHP
# Summary:      3rdparty libraries for ownCloud Enterprise
# Requires:     %% {name} = %% {version}
# %% description 3rdparty
# 3rdparty libraries needed for running ownCloud Enterprise.
# Contained in separate package due to different source code licenses.


%prep
%setup -q -n owncloud
cp %{SOURCE2} .
cp %{SOURCE3} .
cp %{SOURCE4} .
#%%patch0 -p0
echo Building for Target %_repository
%if 0%{?suse_version}
echo suse_version = %suse_version
%endif
%if 0%{?centos_version}
echo centos_version = %centos_version
%endif

%build
rm -f Jenkinsfile

%install
# no server side java code contained, alarm is false
export NO_BRP_CHECK_BYTECODE_VERSION=true
idir=$RPM_BUILD_ROOT/%{owncloud_serverroot}
mkdir -p $idir
mkdir -p $idir/data
cp -aRf * $idir
cp -aRf .htaccess $idir
## $idir/l10n to disappear in future
rm -f $idir/l10n/l10n.pl

if [ ! -f $RPM_BUILD_ROOT/%{apache_serverroot}/%{name}/robots.txt ]; then
  install -p -D -m 644 %{SOURCE4} $idir/robots.txt
fi

## https://github.com/owncloud/enterprise/issues/366
rm -rf $idir/indie.json

# create the AllowOverride directive
install -p -D -m 644 %{SOURCE1} $RPM_BUILD_ROOT/%{apache_confdir}/owncloud.conf
sed -i -e"s|DATAPATH|%{owncloud_serverroot}|g" $RPM_BUILD_ROOT/%{apache_confdir}/owncloud.conf

# clean sources of odfviewer
rm -rf ${idir}/apps/files_odfviewer/src
rm -rf ${idir}/3rdparty/phpass/c
rm -rf ${idir}/3rdparty/phpdocx/pdf/lib/ttf2ufm
rm -rf ${idir}/3rdparty/phpdocx/pdf/tcpdf/fonts/utils/ttf2ufm
rm -rf ${idir}/3rdparty/phpdocx/pdf/tcpdf/fonts/utils/pfm2afm

%if 0%{?suse_version}
# link duplicate doc files
%fdupes $RPM_BUILD_ROOT/%{owncloud_serverroot}
%endif

%pre
# avoid fatal php errors, while we are changing files
# https://github.com/owncloud/core/issues/10953
#
# We don't do this for new installs. Only for updates.
# If the first argument to pre is 1, the RPM operation is an initial installation. If the argument is 2, 
# the operation is an upgrade from an existing version to a new one.
if [ $1 -gt 1 -a ! -s /tmp/apache_stopped_during_owncloud_install ]; then	
  echo "%{name} update: Checking for running Apache"
  # FIXME: this above should make it idempotent -- a requirement with openSUSE.
  # it does not work.
%if 0%{?suse_version} && 0
%if 0%{?suse_version} <= 1110
  rcapache2 status       | grep running > /tmp/apache_stopped_during_owncloud_install
  rcapache2 stop
%else
  service apache2 status | grep running > /tmp/apache_stopped_during_owncloud_install
  service apache2 stop
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

%post
if [ $1 -eq 1 ]; then
    echo "%{name} First install complete"
else
    echo "%{name} Upgrade complete"
fi

%if 0%{?suse_version}
# make sure php5 is not in APACHE_MODULES, so that we don't create dups.
perl -pani -e 's@^(APACHE_MODULES=".*)\bphp5\b@$1@' /etc/sysconfig/apache2
# add php5 to APACHE_MODULES
perl -pani -e 's@^(APACHE_MODULES=")@${1}php5 @' /etc/sysconfig/apache2
%endif

if [ -s /tmp/apache_stopped_during_owncloud_install ]; then
  echo "%{name} post-install: Restarting Apache"
  ## If we stopped apache in pre section, we now should restart. -- but *ONLY* then!
  ## Maybe delegate that task to occ upgrade? They also need to handle this, somehow.
%if 0%{?suse_version}
%if 0%{?suse_version} <= 1110
  rcapache2 start
%else
  service apache2 start
%endif
%endif
%if 0%{?fedora_version} || 0%{?rhel_version} || 0%{?centos_version}
  service httpd start
%endif
fi
rm -f /tmp/apache_stopped_during_owncloud_install

# CAUTION: keep in sync with https://doc.owncloud.com/server/7.0EE/admin_manual/enterprise/windows-network-drive.html
#
# relabel data directory for SELinux to allow ownCloud write access on redhat platforms
%if 0%{?fedora_version} || 0%{?rhel_version} || 0%{?centos_version}
if [ -x /usr/sbin/sestatus ] ; then \
  sestatus | grep -E '^(SELinux status|Current).*(enforcing|permissive)' > /dev/null && { 
    semanage fcontext -a -t httpd_sys_rw_content_t '%{owncloud_serverroot}/data'
    restorecon '%{owncloud_serverroot}/data'
    semanage fcontext -a -t httpd_sys_rw_content_t '%{owncloud_serverroot}/config'
    restorecon '%{owncloud_serverroot}/config'
    semanage fcontext -a -t httpd_sys_rw_content_t '%{owncloud_serverroot}/apps'
    restorecon '%{owncloud_serverroot}/apps'
  }
fi
true
%endif

%postun
# remove SELinux ownCloud label if not updating
[ $1 -eq 0 ] || exit 0
%if 0%{?fedora_version} || 0%{?rhel_version} || 0%{?centos_version}
if [ -x /usr/sbin/sestatus ] ; then \
  sestatus | grep -E '^(SELinux status|Current).*(enforcing|permissive)' > /dev/null && { 
    semanage fcontext -l | grep '%{owncloud_serverroot}/data' && {
      semanage fcontext -d -t httpd_sys_rw_content_t '%{owncloud_serverroot}/data'
      restorecon '%{owncloud_serverroot}/data'
    }
    semanage fcontext -l | grep '%{owncloud_serverroot}/config' && {
      semanage fcontext -d -t httpd_sys_rw_content_t '%{owncloud_serverroot}/config'
      restorecon '%{owncloud_serverroot}/config'
    }
    semanage fcontext -l | grep '%{owncloud_serverroot}/apps' && {
      semanage fcontext -d -t httpd_sys_rw_content_t '%{owncloud_serverroot}/apps'
      restorecon '%{owncloud_serverroot}/apps'
    }
  }
fi
true
%endif

%clean
rm -rf "$RPM_BUILD_ROOT"

%files
%defattr(0644,%{apache_user},%{apache_group},0755)
%exclude %{owncloud_serverroot}/3rdparty/PEAR*
%exclude %{owncloud_serverroot}/3rdparty/System.php

%dir %{owncloud_serverroot}/
%{owncloud_serverroot}/3rdparty
%doc %{owncloud_serverroot}/AUTHORS
%doc %{owncloud_serverroot}/COPYING-AGPL
%{owncloud_serverroot}/core
%{owncloud_serverroot}/db_structure.xml
%{owncloud_serverroot}/index.php
## $idir/l10n to disappear in future
%{owncloud_serverroot}/l10n
%{owncloud_serverroot}/lib
%{owncloud_serverroot}/ocs
%{owncloud_serverroot}/public.php
%doc %{owncloud_serverroot}/README*
%{owncloud_serverroot}/remote.php
%{owncloud_serverroot}/search
%{owncloud_serverroot}/settings
%{owncloud_serverroot}/status.php
%{owncloud_serverroot}/themes
%{owncloud_serverroot}/cron.php
%{owncloud_serverroot}/.htaccess
## FIXME: daily stable7 had a robots.txt, beta2 has none.
# we bring our own as Source4
%{owncloud_serverroot}/robots.txt
%{owncloud_serverroot}/index.html
%{owncloud_serverroot}/console.php
%{owncloud_serverroot}/version.php

%defattr(0755,%{apache_user},%{apache_group},0775)
%{owncloud_serverroot}/occ
%defattr(-,%{apache_user},%{apache_group},0775)
%{owncloud_serverroot}/data
# config can be chown-ed to root:www after the initial DB config is done.
%dir %{owncloud_serverroot}/config
%dir %{owncloud_serverroot}/apps

%defattr(0640,root,%{apache_group},0750)
%{owncloud_serverroot}/apps/*
%{owncloud_serverroot}/config/*
%{owncloud_serverroot}/config/.htaccess

%config %attr(0644,root,root) %{apache_confdir}/owncloud.conf

%doc README README.SELinux

# files 3rdparty
%defattr(0640,root,%{apache_group},0750)
%{owncloud_serverroot}/3rdparty/PEAR/
%{owncloud_serverroot}/3rdparty/PEAR.php
%{owncloud_serverroot}/3rdparty/PEAR5.php
%{owncloud_serverroot}/3rdparty/PEAR-LICENSE
%{owncloud_serverroot}/3rdparty/System.php

%changelog
