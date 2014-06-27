#! /usr/bin/perl -w
#
# (c) 2014, jw@owncloud.com 
#
# setup_oem_client.pl expects that the subproject package already exists.
# it adds a list of known dependencies, so that we can have all relevant binaries 
# in one repo per oem branding.
#
use Data::Dumper;
sub list_obs_pkg;

my @src_pkgs = qw{ neon libqt4 cmake libqt4 libqt4-sql-plugins qtwebkit qtkeychain };
my $src_prj = 'desktop';
my $dest_prj_prefix = 'oem:';
my $obs_api = 'https://s2.owncloud.com';

my $client_name = $ARGV[0];
die "Usage: $0 oem:brandname [DESTPROJ:]\nDefault destination project: $dest_prj_prefix\n" unless $client_name;
if ($ARGV[1])
  {
    $dest_prj_prefix = $ARGV[1];
    warn "submitting package $client_name to nonstandard project prefix '$dest_prj_prefix'\n";
  }
$client_name =~ s{^\Q$dest_prj_prefix\E}{};

my $dest_prj = $dest_prj_prefix . $client_name;
my @existing_pkg = list_obs_pkg($obs_api, $dest_prj);
my %existing_pkg = map { $_ => 1 } @existing_pkg;


for my $pkg (@src_pkgs)
  {
    if ($existing_pkg{$pkg})
      {
        print STDERR "exists: $dest_prj $pkg\n";
	next;
      }
    my $cmd = "osc -A$obs_api copypac $src_prj $pkg $dest_prj";
    print STDERR "+ $cmd\n";
    system($cmd);
  }


exit(0);

sub list_obs_pkg()
{
  my ($api, $prj) = @_;
  my $cmd = "osc -A$api ls $prj";
  open(my $ifd, "$cmd 2>/dev/null|") or die "list_obs_pkg: cannot read from '$cmd'";
  my @pkgs = <$ifd>;
  chomp @pkgs;
  return @pkgs;
}
