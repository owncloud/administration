#! /usr/bin/perl -w
#
# (c) 2015, jw@owncloud.com 
#
# setup_build_targets.pl controls which linux clients are built in obs.
# Used by ownbrander, motivated by ownbrander#225
#
# v0.1, 2015-03-06, jw, initial draught.
# v0.2, 2015-03-08, jw, option parser, done, obs meta pkg parser done, meta pkg setter todo.
# v0.3, 2015-03-09, jw, meta pkg setter done. wipebinaries option added.
# v0.4, 2015-03-31, jw, allow _x86 suffix in set32.
# v0.5, 2015-07-15, jw, always sync list of available repositories from TEMPLATE_PRJ.
#                       Fixing https://github.com/owncloud/ownbrander/issues/393
# v0.6, 2015-08-26, jw, No CentOS_7 or RHEL_7 for 32bit when expanding wildcards.

use Data::Dumper;
use XML::Simple;

my $version = '0.6';
my $verbose = 1;
my $obs_api = $ENV{'OBS_API'} || 'https://s2.owncloud.com';
my $osc_cmd = $ENV{'OSC_CMD'} || 'osc';
my $template_prj = $ENV{'TEMPLATE_PRJ'} || 'desktop';

my $obs_proj = $ARGV[0];
$obs_proj = '' if $obs_proj =~ m{^-};	# someone tried --help, or so?

die qq{
Usage: $0 OBS_PROJ [set32='list,of,target,names' set64='list,of,target,names']
       $0 OBS_PROJ [set='list,of,target,names']

CAUTION: This command affects all packages in the given project. 
When no command is given, the current setup is listed (using target/arch 
syntax per package).

The command set32 enables a comma separated list of 32bit build targets.
The command set64 enables a comma separated list of 64bit build targets, 
and the set command enables one list for both.

The project must have the needed targets pre-configured in its meta prj xml.
Wildcards (shell globbing style) are supported. E.g. 'set=*' enables all 
packages to build for all targets that are currently configured in the project.

Targets listed with set* commands must be configured repositories in the template project
'$template_prj'.
Lower case spelling for targets is accepted. Characters _, :, - are considered equal.

Environment variables:
 OSC_CMD	 current default: $osc_cmd
 OBS_API	 current default: $obs_api
 TEMPLATE_PRJ	 current default: $template_prj
 NO_WIPEBINARIES current default: 0

} unless $obs_proj;

my @existing_pkg = list_obs_pkg($obs_proj);
update_obs_repos($obs_proj) if $ARGV[1] and length($template_prj);	 # we are going to set something...
my $configured_repos = list_obs_repos($obs_proj);
# die Dumper $configured_repos;

my $repo_aliases = mk_repo_aliases(keys %{$configured_repos->{32}},
				   keys %{$configured_repos->{64}});

delete $repo_aliases->{'centos_7'};	# no such 32bit platform. centos_7_x86 only!
delete $repo_aliases->{'rhel_7'};	# no such 32bit platform. rhel_7_x86 only!
# print Dumper expand_alias_wild($repo_aliases, ['centos*', 'xubuntu-14.04']);

unless ($ARGV[1])
  {
    my $last_setting = '';
    my $setting = '';
    for my $pkg (@existing_pkg)
      {
        my $targets = list_enabled_targets($obs_proj, $pkg);
        if ($targets->{'ena'})
          {
	    $setting="enabled=".join(',', @{$targets->{ena}});
          }
        elsif ($targets->{'dis'})
          {
	    $setting="disabled=".join(',', @{$targets->{dis}});
          }
	else
	  {
	    $setting="default";
	  }

	if ($setting eq $last_setting)
	  {
	    printf "%20s: ... same\n", $pkg;
	  }
	else
	  {
	    printf "%20s: %s\n", $pkg, $setting;
	    $last_setting = $setting;
	  }
      }
    exit 0;
  }

my $set32;
my $set64;

while ($ARGV[1])
  {
    if ($ARGV[1] =~ m{^set64(=.*)?$})
      {
        shift @ARGV;
	$set64=$1;
	if (defined $set64)
          {
	    $set64 =~ s{^=}{};
	  }
	else
	  {
	    $set64 = $ARGV[1];
	    shift @ARGV;
	  }
	$set64 = [ split(/[,\s]+/, $set64) ];
      }
    elsif ($ARGV[1] =~ m{^set32(=.*)?$})
      {
        shift @ARGV;
	$set32=$1;
	if (defined $set32)
          {
	    $set32 =~ s{^=}{};
	  }
	else
	  {
	    $set32 = $ARGV[1];
	    shift @ARGV;
	  }
	$set32 = [ split(/[,\s]+/, $set32) ];
      }
    elsif ($ARGV[1] =~ m{^set(=.*)?$})
      {
        shift @ARGV;
	$set32=$1;
	if (defined $set32)
          {
	    $set32 =~ s{^=}{};
	  }
	else
	  {
	    $set32 = $ARGV[1];
	    shift @ARGV;
	  }
	$set64 = $set32 = [ split(/[,\s]+/, $set32) ];
      }
    else
      {
        die "unknown command: $ARGV[1]\n";
      }
  }

my $repo_aliases_32 = { map { $_ => $repo_aliases->{$_} } grep { ! /_x86$/ } keys %$repo_aliases };
my $repo_aliases_64 = { map { my $n = $_; $n =~ s/_x86$//; $n => $repo_aliases->{$_} } grep {   /_x86$/ } keys %$repo_aliases };
$set32 = expand_alias_wild($repo_aliases_32, $set32);
$set64 = expand_alias_wild($repo_aliases_64, $set64);
# die Dumper [ $set32, $set64 ];
print "set32: @$set32\n" if $verbose;
print "set64: @$set64\n" if $verbose;

for my $pkg (@existing_pkg)
  {
    print "$pkg ... ";
    set_enabled($obs_proj, $pkg, $set32, $set64);
    
    unless ($ENV{NO_WIPEBINARIES})
      {
        my $cmd = "$osc_cmd -A$obs_api wipebinaries --all $obs_proj $pkg";
        print STDERR "+ $cmd\n" if $verbose > 2;
        print "wipe ... ";
        system $cmd;
      }
  }


exit(0);
######################################################################################

sub list_obs_pkg
{
  my ($prj) = @_;
  my $cmd = "$osc_cmd -A$obs_api ls $prj";
  print STDERR "+ $cmd\n" if $verbose > 1;
  open(my $ifd, "$cmd 2>/dev/null|") or die "list_obs_pkg: cannot read from '$cmd'";
  my @pkgs = <$ifd>;
  chomp @pkgs;
  return @pkgs;
}

sub set_enabled
{
  my ($obs_proj, $pkg, $set32, $set64) = @_;
  my $cmd = "$osc_cmd -A$obs_api meta pkg $obs_proj $pkg";
  print STDERR "+ $cmd\n" if $verbose > 2;
  # read the meta pkg xml
  open(my $ifd, "$cmd 2>/dev/null|") or die "set_enabled: cannot read from '$cmd'";
  my $meta_pkg_xml = join('', <$ifd>);
  close($ifd);

  # remove build container from meta pkg
  $meta_pkg_xml =~ s{[ \t]*<build/>([ \t]*\n)?}{};
  $meta_pkg_xml =~ s{[ \t]*<build\b.*</build>([ \t]*\n)?}{}s;

  # create a new build xml structure like this: All disabled, except for explicit enable
  #   <build>
  #     <disable/>
  #     <enable arch="i586" repository="Fedora_20"/>
  #     <enable arch="x86_64" repository="ScientificLinux_6"/>
  #   </build>
  my $build = "  <build>\n    <disable/>\n";
  for my $repo (@$set32) { $build .= qq{    <enable arch="i586"   repository="$repo"/>\n}; }
  for my $repo (@$set64) { $build .= qq{    <enable arch="x86_64" repository="$repo"/>\n}; }
  $build .= "  </build>\n";

  # merge the new build structure into the meta pkg
  $meta_pkg_xml =~ s{(</package>)}{$build$1};
  
  # write back the new build structure
  $cmd = "$osc_cmd -A$obs_api meta pkg -F - $obs_proj $pkg";
  print STDERR "+ $cmd\n" if $verbose > 2;
  open($ifd, "|$cmd") or die "set_enabled: cannot write to '$cmd'";
  print $ifd $meta_pkg_xml;
  close($ifd) or die "set_enabled: could not write to '$cmd'";
}

sub list_enabled_targets
{
  my ($obs_proj, $pkg) = @_;
  my $cmd = "$osc_cmd -A$obs_api meta pkg $obs_proj $pkg";
  print STDERR "+ $cmd\n" if $verbose > 2;
  open(my $ifd, "$cmd 2>/dev/null|") or die "list_enabled_targets: cannot read from '$cmd'";
  my $xml = XML::Simple::XMLin($ifd, ForceArray => 1);
  my $ena = $xml->{'build'}[0]{'enable'}  || [];
  my $dis = $xml->{'build'}[0]{'disable'} || [];

  my $l;

  for my $r (@$ena)
    {
      my $t = $r->{'repository'};
      $t .= "/$r->{'arch'}" if $t and $r->{'arch'};
      push @{$l->{'ena'}}, $t if $t;
    }

  for my $r (@$dis)
    {
      my $t = $r->{'repository'};
      $t .= "/$r->{'arch'}" if $t and $r->{'arch'};
      push @{$l->{'dis'}}, $t if $t;
    }
  return $l;
}

sub update_obs_repos
{
  #<project>
  #   ...
  #   <repository name="CentOS_6">
  #    <path project="openSUSE.org:CentOS:CentOS-6" repository="standard"/>
  #    <arch>i586</arch>
  #    <arch>x86_64</arch>
  #  </repository>
  #</project>
  my ($prj) = @_;

  my $cmd = "$osc_cmd -A$obs_api meta prj $prj";
  print STDERR "+ $cmd\n" if $verbose > 1;
  open(my $ifd, "$cmd 2>/dev/null|") or die "configured_repos: cannot read from '$cmd'";
  my $meta_prj_xml = join('', <$ifd>);
  close($ifd);

  $cmd = "$osc_cmd -A$obs_api meta prj $template_prj";
  print STDERR "+ $cmd\n" if $verbose > 1;
  open($ifd, "$cmd 2>/dev/null|") or die "configured_repos: cannot read from '$cmd'";
  my $meta_prj_xml_t = join('', <$ifd>);
  close($ifd);

  # remove all that is not repository definition
  $meta_prj_xml_t = $1 if $meta_prj_xml_t =~ m{(<repository\b.*</repository>)}s;
  $have_repos     = $1 if $meta_prj_xml   =~ m{(<repository\b.*</repository>)}s;

  if ($meta_prj_xml_t eq $have_repos)
     {
       print "Good: $obs_proj and $template_prj have same repos.\n";
       return;
     }
  print "Template project '$template_prj' differs, pulling changes...\n";

  # merge into $meta_prj_xml
  $meta_prj_xml =~ s{<repository\b.*</repository>}{<!-- merged from $template_prj -->$meta_prj_xml_t<!-- end merge -->}s;

  # write back the new build structure
  $cmd = "$osc_cmd -A$obs_api meta prj -F - $prj";
  print STDERR "+ $cmd\n" if $verbose > 2;
  open($ifd, "|$cmd") or die "update_obs_repos: cannot write to '$cmd'";
  print $ifd $meta_prj_xml;
  close($ifd) or die "update_obs_repos: could not write to '$cmd'";
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
  print STDERR "+ $cmd\n" if $verbose > 1;
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
  # hack to allow _x86 suffix from ownbrander.
  for my $n (keys %a)
    {
      $a{'x'.$n} = $a{$n} if $n =~ m{^ubuntu} and not exists $a{'x'.$n};
      $a{$n.'_x86'} = $a{$n} if not exists $a{$n.'_x86'};
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
          die "Error: Build target '$name' not found. Please try one of these:\n $have\n\nOr configure '$name' using 'osc -A$obs_api meta prj -e $obs_proj'\n";
        }
    }
  return [sort keys %exp];
}
