#! /usr/bin/perl -w
#
# (c) 2014 jw@owncloud.com - GPLv2 or ask.
#
# 
# Iterate over customer-themes github repo, get a list of themes.
# for each theme, 
#  - generate the branding tar ball
#  - run ./setup_oem_client.pl with the dest_prj, (to be created on demand)
#  - run ./genbranding.pl with a build token number.
#
# Poll obs every 5 minutes:
#  For each packge in the obs tree
#   - check all enabled targets for binary packages with the given build token number.
#     if a package has them all ready. Generate the linux package binary tar ball.
#
use Data::Dumper;
use File::Temp ();		# tempdir()
use File::Path;

my $customer_themes_git = 'git@github.com:owncloud/customer-themes.git';
my $TMPDIR_TEMPL = '_oem_XXXXX';
our $verbose = 1;
our $no_op = 0;

sub run()
{
  my ($cmd) = @_;
  print "+ $cmd\n" if $::verbose;
  return if $::no_op;
  system($cmd) and die "failed to run '$cmd': Error $!\n";
}

my $source_tar = shift;
print Dumper $source_tar;
my $tmp = File::Temp::tempdir($TMPDIR_TEMPL, DIR => '/tmp/');

run("git clone --depth 1 $customer_themes_git $tmp");

die("unfinished artwork");
