#! /usr/bin/perl -w
#
# (c) 2015, jw@owncloud.com 
#
# setup_build_targets.pl controls which linux clients are built in obs.
# Used by ownbrander, motivated by ownbrander#225
#
# v0.1, 2015-03-08, jw, initial draught.
# 

use Data::Dumper;
use XML::Simple;

my $version = '0.1';
my $verbose = 1;
my $obs_api = $ENV{'OBS_API'} || 'https://s2.owncloud.com';
my $osc_cmd = $ENV{'OSC_CMD'} || 'osc';

my $obs_proj = $ARGV[0];
die qq{
Usage: $0 OBS_PROJ [set32 'list,of,target,names']
       $0 OBS_PROJ [set64 'list,of,target,names']
       $0 OBS_PROJ [set 'list,of,target,names']

When no command is given, the current setup is listed.

The command set32 defines the list of 32bit build targets, for packages in the named project.
The command set64 defines the list of 32bit build targets, and the set command defines both.

Missing targets are enabled, excessive targets are removed. 
Targets listed with set* commands must be configured repositories in OBS_PROJ. Lower case 
spelling is accepted. Characters _, :, - are considered equal.

} unless $obs_proj;

my @existing_pkg = list_obs_pkg($obs_proj);
my $configured_repos = list_obs_repos($obs_proj);

my $repo_aliases = mk_repo_aliases(keys %{$configured_repos->{32}},
				   keys %{$configured_repos->{64}});

# print Dumper expand_alias_wild($repo_aliases, ['xubuntu-14.04');

unless ($ARGV[1])
  {
     print Dumper \@existing_pkg;
     print Dumper $configured_repos;
     print Dumper $repo_aliases;
     print Dumper expand_alias_wild($repo_aliases, ['centos*', 'xubuntu-14.04']);
     exit 0;
  }


exit(0);
######################################################################################

sub list_obs_pkg
{
  my ($prj) = @_;
  my $cmd = "$osc_cmd -A$obs_api ls $prj";
  print "+ $cmd\n" if $verbose;
  open(my $ifd, "$cmd 2>/dev/null|") or die "list_obs_pkg: cannot read from '$cmd'";
  my @pkgs = <$ifd>;
  chomp @pkgs;
  return @pkgs;
}

sub list_obs_repos
{
  #<project>
  #   ...
  #   <repository name="CentOS_6">
  #    <path project="openSUSE.org:CentOS:CentOS-6" repository="standard"/>
  #    <arch>i586</arch>
  #    <arch>x86_64</arch>
  #  </repository>
  #</project>

  # returns as
  # { '32' => { 'Debian_6' => 1, ...}, '64' => {} };

  my ($prj) = @_;
  my $cmd = "$osc_cmd -A$obs_api meta prj $prj";
  print "+ $cmd\n" if $verbose;
  open(my $ifd, "$cmd 2>/dev/null|") or die "configured_repos: cannot read from '$cmd'";
  my $xml = XML::Simple::XMLin($ifd, ForceArray => 1);
  my $repo = {'32' => {}, '64' => {}};	# assert keys present, to keep mk_repo_aliases happy.
  for my $r (keys %{$xml->{'repository'}})
    {
      my $arch_32 = 0;
      my $arch_64 = 0;
      for my $a (@{$xml->{'repository'}{$r}{'arch'}})
        {
           $arch_64++ if $a =~ m{x86_64}i;
           $arch_32++ if $a =~ m{i[3456]86}i;
        } 
      $repo->{32}{$r} = 1 if $arch_32;
      $repo->{64}{$r} = 1 if $arch_64;
    }
  return $repo;
}

sub mk_repo_aliases
{
  my @all_names = @_;
  my %a;
  for my $n (@all_names)
    {
      $a{lc $n} = $n;

      # CAUTION: keep in sync with expand_alias_wild
      my $n_ = $n;
      $n_ =~ s{[-:]}{_}g;

      $a{lc $n_} = $n;
    }

  # hack to allow obsoleting the x in front of Ubuntu some day.
  for my $n (keys %a)
    {
      $a{'x'.$n} = $a{$n} if $n =~ m{^ubuntu} and not exists $a{'x'.$n};
    }
  return \%a;
}

sub expand_alias_wild
{
  my ($alias_mapping, $names) = @_;
  my %exp;
  for my $name (@$names)
    {
      my $there = 0;
      # CAUTION: keep in sync with mk_repo_aliases
      $name = lc $name;
      $name =~ s{[-:]}{_}g;

      if (exists $alias_mapping->{$name})
        {
          $exp{$alias_mapping->{$name}} = 1;
          $there = 1;
          next;
        }
      $name =~ s{\?}{.}g; $name =~ s{\*}{.*}g;	# glob 2 re
      for $k (keys %$alias_mapping)
        {
          if ($k =~ m{^$name$})
            {
              $exp{$alias_mapping->{$k}} = 1;
              $there = 1;
            }
        }
      unless ($there)
        {
          my %have = map { $_ => 1 } values %$alias_mapping;
          my $have = join ' ', sort keys %have;
          die "Error: Build target '$name' not found. Please try one of these:\n $have\n";
        }
    }
  return [sort keys %exp];
}
