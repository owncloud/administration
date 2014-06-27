#! /usr/bin/perl -w
#
# check_rpm_keys.pl -- test GPG keys in RPM packages on the downloads, see if they match the repo keys.
# (c) 2014, jw@owncloud.com, GPLv2 or ask
#

my $prj = shift
my $pkg = shift

die "usage: $0 PRJ [PKG]\n" unless $prj;
die "usage: $0 PRJ PKG\n# (prj browsing not impl.)\n" unless $pkg;

die "not impl.";
# All these three responses are equivalent. The keys look different, but the shorter ones are just fragments of the longest. That is fine.
# Note that only the qip query returns the date, when the package was signed.
#
# binpkgurl=http://download.opensuse.org/repositories/isv:/ownCloud:/oem:/polybox/CentOS_CentOS-6/x86_64/polybox-client-1.5.3-7.1.x86_64.rpm
# rpm -K -v $binpkgurl
# V3 DSA/SHA1 Signature, key ID ba684223: OK
# rpm -qip  $binpkgurl
# Signature   : DSA/SHA1, Fri 27 Jun 2014 01:06:33 AM CEST, Key ID 977c43a8ba684223
# rpm -qp --qf '%{SIGGPG}\n' $binpkgurl
# 883f03050053aca779977c43a8ba684223110269a8009f5a0deb9c2a026d1c3d3dcd9d638535b81e906f8500a0837dace2d23cc8ff7f403af766f83904f2412288
#                   977c43a8ba684223
#                           ba684223

# key= http://download.opensuse.org/repositories/isv:/ownCloud:/oem:/polybox/CentOS_CentOS-6/repodata/repomd.xml.key 
# curl -s $key | gpg -vv --no-default-keyring
#
#  hashed subpkt 2 len 4 (sig created 2014-06-18)
#  ...
#  hashed subpkt 9 len 4 (key expires after 4y200d23h59m)
#  ...
#  pub  1024D/BA684223 2012-02-08 isv:ownCloud OBS Project <isv:ownCloud@build.opensuse.org>

