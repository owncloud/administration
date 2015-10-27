#!/usr/bin/perl
#
# This script automates package build for jenkins based on OBS
# Copyright Klaas Freitag <freitag@owncloud.com>
#
# used by rotor.owncloud.com, mirall-linux-master like this:
#  cd jenkins/obs_integration
#  ./buildpackage.pl -p *.tar.bz2
#
# Released under GPL V.2.
#
# 2014-08-05, jw@owncloud.com -- adapted to proper prerelease versioning.
#	interface: prerelease, base_version, tar_version, and/or Version
#
# 2014-08-06: remove *all* old tar balls to make deb happy.
# 
use Getopt::Std;
use Config::IniFiles;
use File::Copy;
use ownCloud::BuildHelper;
use Cwd;

use strict;
use vars qw($tarball $dir $opt_p $opt_h $opt_n);

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
  -n      no local build attempts.

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

  ## This no longer works since we use macros:
  # my $oldVersion = getFromSpecfile( $packName, 'Version' );

  opendir DIR, ".";
  my @f = grep { /\.tar\./ } readdir DIR;
  closedir DIR;

  my $do_add = 1;

  for my $f (@f) {
    if ($f eq $tarFileName)
      {
        $do_add = 0;	# just keep it.
      }
    else
      {
        # remove an old tarball.
        my $remFile = $f;
        print "  >> Removing old source file $remFile\n";
        if( -e $remFile ) {
  	  my @oscr = ("remove", $remFile);
	  doOSC( @oscr ) or return 0;
      }
    }
  }

  if (1) {	# $do_add) {      
    print(" >> Adding tarball $tarFileName ...\n");
    doOSC( "del", $tarFileName);	 # make readding the same file not an error.
    print(" >> Adding tarball $tarFileName\n");
    doOSC( "add", $tarFileName) or return 0;
  }


  my $specFile = $packName .".spec";
  my $debversion = $version;
  $debversion =~ s/_/-/;
  # prerelease numbers need a '~'
  $debversion =~ s{[_.-]*(nightly|daily|alpha|beta|rc)}{~$1};
  if ($debversion =~ m{^(.*)~(.*)$})
    {
      my ($base_version, $prerelease) = ($1,$2);
      my $n = patchAFile($specFile, 
        {
	  base_version 	=> $base_version, 
	  prerelease 	=> $prerelease, 
	  tar_version 	=> $version 
	});
      if ($n < 2) 
        {
	  warn "Yor $specFile is not prepared for prerelease config. Trying tar_version + Version in debian '~' style.\n";
	  if (patchAFile($specFile, 
	        { 
		  Version => $debversion, 
		  tar_version => $version 
	        } ) < 2)
	    {
	      warn "Your $specFile has no tar_version define. Trying simple Version directly from the tar ball. This may spoil package updates.\n";
	    }
	}
    }
  else
    {
      ## we use prerelease %nil to signal to the specfile that this is not a prerelease
      patchAFile($specFile, 
        { 
	  Version 	=> $version, 
	  base_version 	=> $version, 
	  tar_version 	=> $version, 
	  prerelease 	=> '%nil' 
	});
    }

  # Patch the debian files.

  my $dscFile = $packName . ".dsc";
  patchAFile( $dscFile, { Version => $debversion } );

  # Get the build param
  my $arch = readIniValue( "$dir/buildpackage.ini", $pack, "arch" );
  my $b = readIniValue( "$dir/buildpackage.ini", $pack, "builds" );

  my @builds = split( /\s*,\s*/, $b );

  my $re = 1;	# 1 ok. 0 error

  my $changelog = "  * Update to nightly version $debversion";
  addDebChangelog( $packName, $changelog, $debversion );

  unless ($opt_n) {
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
  }

  if( $re && $opt_p) {
    my @osc = ( "commit", "-m", "Update by Mr. Jenkins nightly build.", "--noservice" );
    print("DOING the push to OBS\n");
    doOSC( @osc ) or return 0;
  }

  return $re;
}

# main here.
getopts('hpn');
my $argc = @ARGV;

help() if( $opt_h || $argc == 0 );

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



