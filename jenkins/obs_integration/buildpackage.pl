#!/usr/bin/perl
#
# This script automates package build for jenkins based on OBS
# Copyright Klaas Freitag <freitag@owncloud.com>
#
# Released under GPL V.2.
#
#
use Getopt::Std;
use Config::IniFiles;
use File::Copy;
use ownCloud::BuildHelper;
use Cwd;

use strict;
use vars qw($tarball $dir $opt_p $opt_h);

sub help() {
  print<<ENDHELP

  buildpackage - update nightly builds, build locally and submit to OBS

  Call the script with the name and path to a new tarball. The script extracts
  the new nightly version, patches the version in the spec file, adds changelogs
  and builds locally if required.

  Finally it can push the updated package back to OBS.

  Options:
  -h      this help text.
  -p      do the push to OBS.

ENDHELP
;
  exit 1;
}


# ======================================================================================
sub getPackName( $ ) {
  my ($tarname) = @_;

  print " Tar-Name: $tarname\n";
  $tarname =~ s/-.*$//;
  print "Pack-Name: $tarname\n";
  return $tarname;
}

sub doBuild( $$ ) {
  my ($pack, $packName) = @_;
  my $repo = readIniValue( "$dir/buildpackage.ini", $pack, "repo" );
  print "Building $packName from repo $repo\n";

  # create a build dir
  my $builddir = "osc_build";

  mkdir($builddir, 0755);
  chdir( $builddir );
  print "Building in $builddir\n";

  # create a bin package directory
  my $packDir = "$dir/packages";

  checkoutPackage($repo, $packName);
  chdir( $repo );
  chdir( $packName );

  # now we are in the package directory.
  # Copy the tarball.
  copy( $tarball, '.' );
  die "Source tarball does not exist!\n" unless ( -e $tarball );

  my $version = $tarball;
  # remove the whole path and base name.
  $version =~ s/^.+\/$pack-//;
  my $tarFileName = "$pack-$version";
  # remove the .tar.bz2
  $version =~ s/\.tar\..*$//;
  print "Package Version: $version\n";

  my $oldVersion = getFromSpecfile( $packName, 'Version' );

  if( $oldVersion ne $version ) {
    print(" >> Adding tarball $tarFileName\n");
    my @osca = ("add", $tarFileName);
    doOSC( @osca );

    # Get remove the old tarball.
    if( $oldVersion ) {
      my $remFile = "$pack-$oldVersion.tar.bz2";
      print "  >> Removing old source file $remFile\n";
      if( -e $remFile ) {
	my @oscr = ("remove", $remFile);
	doOSC( @oscr );
      }
    }
  }

  # Patch the spec file with the new version.
  my %patchSpec;
  $patchSpec{Version} = $version;
  my $specFile = $packName .".spec";
  patchAFile( $specFile, \%patchSpec );

  # Patch the debian files.
  %patchSpec = ();
  my $debversion = $version;
  $debversion =~ s/_/-/;

  $patchSpec{Version} = $debversion;
  my $dscFile = $packName . ".dsc";
  patchAFile( $dscFile, \%patchSpec );

  # Get the build param
  my $arch = readIniValue( "$dir/buildpackage.ini", $pack, "arch" );
  my $b = readIniValue( "$dir/buildpackage.ini", $pack, "builds" );

  my @builds = split( /\s*,\s*/, $b );

  my $re = 1;

  my $changelog = "  * Update to nightly version $debversion";
  addDebChangelog( $packName, $changelog, $debversion );

  # Do the local builds.
  foreach my $build ( @builds ) {
    # Do the build.
    print " ** Building for $build\n";
    my $buildPackDir = "$packDir/$build";
    my $buildDescExt = 'spec';
    $buildDescExt = 'dsc' if( $build =~ /ubuntu/i );

    mkdir( $buildPackDir, 0755) unless( -d $buildPackDir );
    my @osc = ( "build", "--noservice", "--clean", "-k", $buildPackDir, "-p", $buildPackDir, "$build", "x86_64", "$packName.$buildDescExt");
    print " ** Starting build with " . join( " ", @osc ) . "\n";
    unless( doOSC( @osc ) ) {
      print "Build Job failed for $build => exiting!\n";
      $re = 0;
      last;
    }
  }

  if( $re && $opt_p) {
    my @osc = ( "commit", "-m", "Update by Mr. Jenkins nightly build." );
    print("DOING the push to OBS\n");
    doOSC( @osc );
  }

  return $re;
}

# main here.
getopts('hp');

help() if( $opt_h );

# remember the base dir.
$dir = getcwd;
mkdir("packages") unless( -d "packages" );

$tarball = $dir .'/'. $ARGV[0];
print "Tarball: $tarball\n";

my $pack = getPackName( $ARGV[0] );
my $packName = readIniValue( "$dir/buildpackage.ini", $pack, "packagename" ) or $pack;

if( ! doBuild( $pack, $packName ) ) {
  print "Building failed -> EXIT!\n";
  exit 1;
}

chdir( $dir );



