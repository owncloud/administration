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
use Cwd;

use strict;
use vars qw($tarball $dir);

sub readIniValue( $$ ) {
  my ($prjName, $value) = @_;

  my $key;
  my $cfg = new Config::IniFiles( -file => "$dir/buildpackage.ini", -nocase => 1  );

  if( $cfg->SectionExists( $prjName ) ) {
    $key = $cfg->val( $prjName, $value );
  }
  return $key;
}


# ======================================================================================
sub getPackName( $ ) {
  my ($tarname) = @_;

  print " Tar-Name: $tarname\n";
  $tarname =~ s/-.*$//;
  print "Pack-Name: $tarname\n";
  return $tarname;
}

sub doOSC {
    system( "/usr/bin/osc", @_ );
    my $re = 0;

    if ($? == -1) {
      print "failed to execute: $!\n";
    } elsif ($? & 127) {
      printf "child died with signal %d, %s coredump\n",
      ($? & 127), ($? & 128) ? 'with' : 'without';
    } else {
      printf "child exited with value %d\n", $? >> 8;
      $re = 1 if( ($? >> 8) == 0 );
    }
    return $re;
}


sub checkout_package( $$ ) {
  my( $repo, $pack ) = @_;

  if( -d $repo ) {
    chdir $repo;
    doOSC("up", $pack);
  } else {
    doOSC( "checkout", $repo, $pack );
    chdir $repo;
  }
  chdir $pack;
}

sub getFromSpecfile( $$ ) {
  my ($pack, $tag) = @_;
  my $re;

  return unless( $tag );

  my $specfile = "$pack.spec";

  open( SPEC, "<$specfile" ) || die("No spec-file: $specfile\n");
  my @spec = <SPEC>;
  close SPEC;

  foreach my $s ( @spec ) {
    if( $s =~ /^$tag:\s*(\S+)\s*$/ ) {
      $re = $1;
      last;
    }
  }
  return $re;
}

sub patchSpecfile( $$ ) {
    my ($pack, $rep) = @_;
    # rep is a hash reference.
    my $specfile = "$pack.spec";

    open( SPEC, "<$specfile" ) || die("No spec-file: $specfile\n");
    my @spec = <SPEC>;
    close SPEC;

    my $line = 0;
    my @newspec;
    foreach my $s ( @spec ) {
      $line++;

      foreach my $key ( keys %$rep ) {
        if( $s =~ /^$key:/ ) {
          $s = "$key: " . $rep->{$key} . "\n";
	  print "Replacing in line $line: $key -> $rep->{$key}\n";
	  last;
        }
      }
      push @newspec, $s;
    }

    # write the new spec file.
    open( SPEC, ">$specfile" ) || die("Could not open Specfile to write!\n");
    print SPEC @newspec; # join("\n", @newspec );
    close SPEC;

}

sub doBuild( $$ ) {
  my ($pack, $packName) = @_;
  my $repo = readIniValue( $pack, "repo" );
  print "Building $packName from repo $repo\n";

  # create a build dir
  my $builddir = "osc_build";

  mkdir($builddir, 0755);
  chdir( $builddir );
  print "Building in $builddir\n";

  # create a bin package directory
  my $packDir = "$dir/packages";

  checkout_package($repo, $packName);
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
  patchSpecfile( $packName, \%patchSpec );

  # Get the build param
  my $arch = readIniValue( $pack, "arch" );
  my $b = readIniValue( $pack, "builds" );

  my @builds = split( /\s*,\s*/, $b );

  my $re = 1;

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

  if( $re ) {
    my @osc = ( "commit", "-m", "Update by Mr. Jenkins nightly build." );
    doOSC( @osc );
  }

  return $re;
}

# main here.

# remember the base dir.
$dir = getcwd;
mkdir("packages") unless( -d "packages" );

$tarball = $dir .'/'. $ARGV[0];
print "Tarball: $tarball\n";

my $pack = getPackName( $ARGV[0] );
my $packName = readIniValue( $pack, "packagename" ) or $pack;

if( ! doBuild( $pack, $packName ) ) {
  print "Building failed -> EXIT!\n";
  exit 1;
}

chdir( $dir );



