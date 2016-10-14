# FROM https://github.com/owncloud/documentation/issues/2172#issuecomment-188876694
#
docker run -ti -v /tmp:/mnt rhel:7.2 /bin/bash
subscription-manager register --username ... --password ... --auto-attach
subscription-manager list --available | grep 'Pool ID'
subscription-manager attach --pool=...
subscription-manager attach --pool=...
yum repolist all | egrep 'rhscl|samba'
  ...
subscription-manager repos --enable rhel-server-rhscl-7-rpms              # for rhel7 with php56
# subscription-manager repos --enable rhel-server-rhscl-7-eus-rpms        # for rhel7 with php55
subscription-manager repos --enable rh-gluster-3-samba-for-rhel-7-server-rpms    # libsmbclient-devel is there.
# subscription-manager repos --disable rhel-sjis-for-rhel-7-server-rpms     # broken, unneeded, causes errors, if there

yum groupinstall "Development Tools"
yum install wget rpm-build yum-utils rh-php56-php-devel libsmbclient-devel
wget http://download.opensuse.org/repositories/isv:/ownCloud:/community/CentOS_7/isv:ownCloud:community.repo -O /etc/yum.repos.d/isv:ownCloud:community.repo
yum clean all
yumdownloader --source php5-libsmbclient
rpm -ihv php5-libsmbclient-*.src.rpm
cd ~/rpmbuild

