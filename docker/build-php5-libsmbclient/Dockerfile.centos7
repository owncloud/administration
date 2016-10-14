# This Dockerfile generates a php5-libsmbclient*.rpm package for both RHEL7 and CentOS7 using php-5.5
#
# (c) 2016 jw@owncloud.com 
#
# Start with a php5 base upgrade according to our documentation
# https://doc.owncloud.com/server/9.1/admin_manual/installation/php_55_installation.html
# https://github.com/owncloud/documentation/issues/2172#issuecomment-188876694
#
# The build environment used here is CentOS7 specific, you cannot use the exact same instructions on a RHEL7 system.
# On RHEL7, you need to use subscription-manager to enable the needed channels for e.g. php55-php-devel.
#
FROM centos:centos7
RUN yum install -y centos-release-scl
RUN yum install -y php55 php55-php php55-php-gd php55-php-mbstring
RUN yum install -y php55-php-mysqlnd php55-php-ldap
RUN yum install -y php55-php-devel
RUN yum groupinstall -y "Development Tools"
RUN yum install -y wget rpm-build yum-utils 
RUN wget http://download.opensuse.org/repositories/isv:ownCloud:community/CentOS_7/isv:ownCloud:community.repo -O /etc/yum.repos.d/isv:ownCloud:community.repo
RUN yum clean all
RUN yum-builddep -y php5-libsmbclient
RUN yumdownloader --source php5-libsmbclient
RUN rpm -ihv php5-libsmbclient*.src.rpm
RUN sed -i -e 's@phpize@source /opt/rh/php55/enable; phpize@' /root/rpmbuild/SPECS/php5-libsmbclient.spec
RUN sed -i -e 's@CentOS_6_PHP55@CentOS_7_PHP55@'              /root/rpmbuild/SPECS/php5-libsmbclient.spec
RUN cd /root/rpmbuild && rpmbuild -D '_repository CentOS_7_PHP55' -ba              SPECS/php5-libsmbclient.spec
CMD bash --rcfile /opt/rh/php55/enable

