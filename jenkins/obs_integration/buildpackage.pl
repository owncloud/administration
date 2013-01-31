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
  print "Building from repo $repo\n";

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
  my $version = $tarball;
  # remove the whole path and base name.
  $version =~ s/^.+\/$pack-//;
  # remove the .tar.bz2
  $version =~ s/\.tar\..*$//;
  print "Package Version: $version\n";

  # Patch the spec file.
  my %patchSpec;
  $patchSpec{Version} = $version;
  patchSpecfile( $packName, \%patchSpec );

  # Get the build param
  my $arch = readIniValue( $pack, "arch" );
  my $b = readIniValue( $pack, "builds" );

  my @builds = split( /\s*,\s*/, $b );

  foreach my $build ( @builds ) {
    # Do the build.
    print " ** Building for $build\n";
    my $buildPackDir = "$packDir/$build";
    mkdir( $buildPackDir, 0755) unless( -d $buildPackDir );
    my @osc = ( "build", "--noservice", "--clean", "-k", $buildPackDir, "-p", $buildPackDir, "$build", "x86_64", "$packName.spec");
    print " ** Starting build with " . join( " ", @osc ) . "\n";
    doOSC( @osc );
  }

}

# main here.

# remember the base dir.
$dir = getcwd;
mkdir("packages") unless( -d "packages" );

$tarball = $dir .'/'. $ARGV[0];
print "Tarball: $tarball\n";

my $pack = getPackName( $ARGV[0] );
my $packName = readIniValue( $pack, "packagename" ) or $pack;

doBuild( $pack, $packName );
my $newDir = getcwd;
print "* Now in $newDir\n";

chdir( $dir );



