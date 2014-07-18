#! /usr/bin/perl -w
# 
# check_packed_client_oem.pl -- an integrety tester for our monster tar balls.
#
# (C) 2014, jw@owncloud.com

use Data::Dumper;

my $tarball = shift;
my ($brandname,$version) = ($1,$2) if $tarball =~ m{(.*)-(\d[\d\.]+)[-\.]};
die "cannot parse version number from tarball name '$tarball'\n" unless defined $version;

$brandname =~ s{.*/}{};
print "testing $tarball against version '$version' of branding '$brandname'...\n";

open(my $ifd, "tar tf '$tarball'|") or die "cannot run tar tf $tarball: $!\n";

my %topdirs;
my %main_pkg_versions;
while(defined(my $line = <$ifd>))
  {
    chomp $line;
    my $topdir = $1 if $line =~ m{^[\./]*([^/]+)/};
    $topdirs{$topdir}++;
    my $pkg = $line;
    $pkg =~ s{.*/}{};
    if ($pkg =~ m{^(lib)?\Q$brandname\E})
      {
        # tubcloud-client-doc-1.6.1-1.1.jw_20140716.x86_64.rpm
        if ($pkg =~ m{[vV\._-](\d[\d\.]+)[\._-]})
          {
            my $vers = $1;
	    push @{$main_pkg_versions{$vers}}, $line;
          }
        else
          {
	    push @{$main_pkg_versions{'?'}}, $line;
          }
      }
    else
      {
	push @{$main_pkg_versions{'/'}}, $line;
      }
  }

# ignore what we expect, talk about the rest.
delete $topdirs{"$brandname-$version"};
delete $main_pkg_versions{$version};
delete $main_pkg_versions{'?'};
delete $main_pkg_versions{'/'};

if (%topdirs)
  {
    print "$tarball contains toplevel folders that do not match its name:\n" . Dumper \%topdirs;
  }
if (%main_pkg_versions)
  {
    print Dumper \%main_pkg_versions;
    my @vers = keys %main_pkg_versions;
    warn "All the above have '$brandname' in their name but a different version than '$version':\n";
    die "  @vers\n";
  }

exit(0);
