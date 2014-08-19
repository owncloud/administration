#! /usr/bin/perl -w
#
# studio2obs.pl -- converts an export from susestudio.com into a package for the open build service
#
# 2014-08-19, 0.1 jw@owncloud.com
#		-- initial draught

use Data::Dumper;
my $version = '0.1';
my $verbose = 1;


my $studio_tar = shift;
my $default_obs_api = 'https://api.opensuse.org';

unless (-f $studio_tar)
  {
    die qq{studio2obs.pl Version $version

Usage: 
       $0 ~/Download/*-kiwi_src.tar.gz [PACK_NAME]
       osc vc
       osc ci

If PACK_NAME is specified, an implict 'osc mkpac PACK_NAME; cd PACK_NAME' is done.
Otherwise the PACK_NAME is taken from the current directory, which should be a 
working directory of an obs package.
};
  }

sub run
{
  my ($cmd) = @_;
  print "+ $cmd\n" if $verbose;
  system($cmd) and die "$cmd failed: $@ $!\n";
}

open IN, "<", ".osc/_apiurl" or die "cannot read .osc/_apiurl: $!\n";
my $api_url = <IN>; chomp $api_url; close IN;

open IN, "<", ".osc/_project" or die "cannot read .osc/_project: $!\n";
my $prj_name = <IN>; chomp $prj_name; close IN;

die "Error: Not an obs project directory here.\n" unless defined $prj_name;

my $outdir='.';
my $pkg_name = shift;
if (open IN, "<", ".osc/_package")
  {
    my $p = <IN>; chomp $p;
    die "both, .osc/_package (='$p') present, and PACK_NAME=$pkg_name specified.\n" 
      if defined $pkg_name and $p ne $pkg_name;
    $pkg_name = $p;
  }
else 
  {
    run("osc mkpac '$pkg_name' || true") if defined $pkg_name;
    $outdir = $pkg_name;
  }

die "Error: no PACK_NAME specified and not inside a package directory\n" unless defined $pkg_name;

# die Dumper "studio_tar=$studio_tar api_url=$api_url prj_name=$prj_name pkg_name=$pkg_name\n";
# die Dumper "outdir=$outdir\n";

chdir($outdir); $outdir='.';

$tmpdir .= "./_studio2obs_$$";
mkdir($tmpdir) or die "mkdir $tmpdir failed: $!\n";

run("tar zxf '$studio_tar' -C $tmpdir");
run("mv $tmpdir/*/source/* '$outdir/'");
run("rm -rf '$tmpdir'");

if (-d "root")
  {
    run("tar zcf root.tar.gz -C root .");
    run("rm -rf root");
  }

my $kiwifile = "$pkg_name.kiwi";
rename("config.xml", $kiwifile) if -f "config.xml";
kiwi_studio2obs($kiwifile) if -f $kiwifile;
run("touch '$pkg_name.changes'");
run("osc add *");
run("ls -la .");

exit(0);
# ------------------------------------------------------

sub kiwi_studio2obs
{
  my ($kiwifile,$obs_api) = @_;
  $obs_api ||= $default_obs_api;
  open IN, "<", $kiwifile or die "cannot read $kiwifile: $!\n";
  my $kiwi = join("", <IN>);
  close IN;

  # postprocess 

  open OUT, ">", $kiwifile or die "cannot write $kiwifile: $!\n";
  print OUT $kiwi;
  close OUT or die "could not write $kiwifile: $!\n";
}
