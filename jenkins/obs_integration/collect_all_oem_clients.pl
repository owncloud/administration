#! /usr/bin/perl -w
#
# (c) 2014 jw@owncloud.com - GPLv2 or ask.
#
# 
# 

use Getopt::Std;
use Data::Dumper;

my $osc_cmd             = 'osc -Ahttps://s2.owncloud.com';
my $out_dir 		= '/tmp/';
my $container_project   = 'oem';	 #'home:jw:oem';
use vars qw($opt_p $opt_f $opt_r $opt_h $opt_o $opt_k);
getopts('hp:f:r:o:k');

$container_project = $opt_p if defined $opt_p;
$container_project =~ s{:$}{};

$out_dir = $opt_o if defined $opt_o;

$client_filter		= $opt_f || "";
my @client_filter	= split(/[,\|\s]/, $client_filter);

sub help() {
  print<<ENDHELP

  collect_all_oem_clients - harvest from the build service, what setup_all_oem_clients started there.

  Options:
  -h                 help, displays help text
  -p "project"	     obs project to pull from. Default: '$container_project'
  -r "relid"	     specify a build release identifier to look for. Default: grab any.
  -f "clients,..."   A filter to select only a few matching brandings. Default all.
  -o "outdir"        Directory where to write collected packages to. Default: "$out_dir";
  -k                 Keep going. Default: Abort if we have failed or still building packages.

ENDHELP
;
  exit 1;
}
help() if $opt_h;

print "project=$container_project, osc='$osc_cmd', client_filter='$client_filter' out_dir='$out_dir'\n";

my @oem_projects;

if (@client_filter)
  {
    @oem_projects = map { "$container_project:$_" } @client_filter;
  }
else
  {
    open(my $ifd, "$osc_cmd ls|") or die "cannot list projects: $!\n";
    my $info = join("",<$ifd>);
    close $ifd;
    my @all_prj = split(/\s+/, $info);
    for my $p (@all_prj)
      {
        push @oem_projects, $p if $p =~ m{^\Q$container_project\E:};
      }
  }

# die Dumper \@oem_projects;
my %failed;
my %building;
my %succeeded;
for my $prj (@oem_projects)
  {
    my $pkg = $prj;
    $pkg =~ s{^\Q$container_project\E:}{};
    $pkg .= '-client';

    # check for failed builds
    open(my $ifd, "$osc_cmd r -v $prj $pkg|") or die "cannot get build results for $prj $pkg: $!\n";
    my $info = join("",<$ifd>);
    close $ifd;

    ## handle continuation lines....
    my @results;
    for my $r (split(/\n/, $info))
      {
        if ($r =~ m{^\s+(.*)})
	  {
	    $results[-1] .= ', ' . $r;
	  }
	else
	  {
            push @results, $r;
	  }
      }

    ## now we have proper records.
    for my $r (@results)
      {
	my ($target,$arch,$status) = ($1,$2,$3) if $r =~ m{^(\S+)\s+(\S+)\s+(.*)$};
	die Dumper $r unless defined $status;
	if ($status =~ m{(failed|broken|unresolvable)})
	  {
	    $failed{"$prj/$target/$arch"} = $status;
	  }
	elsif ($status =~ m{(scheduled|building|finished|signing)})
	  {
	    $building{"$prj/$target/$arch"} = $status;
	  }
	else
	  {
	    $succeeded{"$prj/$target/$arch"} = $status;
	  }
      }
  }

if (%building)
  {
    my @k = keys %building;
    printf("%d packages currently building.\n $k[0] $building{$k[0]}\n  Wait a bit?\n", scalar keys %building);
    exit(1) unless $opt_k;
  }

## trigger all that failed.
my %prj_meta_visited;
for my $f (keys %failed)
  {
    my ($prj,$target,$arch) = split /\//, $f;
    my $pkg = $prj;
    $pkg =~ s{^\Q$container_project\E:}{};
    $pkg .= '-client';

    unless ($prj_meta_visited{$prj})
      {
        ## if we have a status of broken: interconnect error: api.opensuse.org: no such host
	## then a simple rebuildpac does not help. We have to touch the meta data of the project
	## to trigger the rebuild.
        my $cmd = "$osc_cmd meta $prj ...";
	$prj_meta_visited{$prj}++;
	warn "$cmd trigger not implemented\n";
      }
    my $cmd = "$osc_cmd rebuildpac $prj $pkg $target $arch";
    print "retrying $failed{$f}\n+ $cmd\n";
    system($cmd);
  }

if (%failed)
  {
    printf("%d packages retriggered\n", scalar keys %failed);
    exit(1) unless $opt_k;
  }

printf("%d packages succeeded.\n", scalar keys %succeeded);
die Dumper \%succeeded;

