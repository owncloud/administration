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

sub addDebChangelog( $$$ ) {
  my ($pack, $changelog, $version) = @_;

  my $changesfile = "debian.changelog";

  return 1 unless( -e $changesfile );

  open( CHANGES, "<$changesfile" ) || die("No changes-file: $changesfile\n");
  my @changes = <CHANGES>;
  close CHANGES;

  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime(time);
  my @mabbr = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
  my @wabbr = qw( Sun Mon Tue Wed Thu Fri Sat );

  my $timestr = sprintf("%02d:%02d:%02d +0000", $hour, $min, $sec);
  my $datestr = sprintf("%s, %02d %s %d", $wabbr[$wday], $mday, $mabbr[$mon], 1900+$year);
  # print "XXXXXXXXX $datestr $timestr\n";

  unshift( @changes, "\n -- ownCloud Jenkins <jenkins\@owncloud.com>  $datestr $timestr\n\n" );

  unshift( @changes, "\n$changelog\n" );
  unshift( @changes, sprintf( "%s (%s) stable; urgency=low\n", $pack, $version ));

   # write the new spec file.
  open( CHANGES, ">$changesfile" ) || die("Could not open Changesfile to write!\n");
  print CHANGES @changes; # join("\n", @newspec );
  close CHANGES;

  return 1;
}


sub patchChangesFile( $$ ) {
  my ($pack, $changelog) = @_;

  my $changesfile = "$pack.changes";

  open( CHANGES, "<$changesfile" ) || die("No changes-file: $changesfile\n");
  my @changes = <CHANGES>;
  close CHANGES;

  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime(time);
  my @mabbr = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
  my @wabbr = qw( Sun Mon Tue Wed Thu Fri Sat );
  my $dateline = "$wabbr[$wday] $mabbr[$mon] $mday $hour:$min:$sec UTC 2013 - jenkins\@owncloud.org";

  unshift( @changes, "\n$changelog\n\n" );
  unshift( @changes, "\n$dateline\n" );
  unshift( @changes, "-------------------------------------------------------------------");

   # write the new spec file.
  open( CHANGES, ">$changesfile" ) || die("Could not open Changesfile to write!\n");
  print CHANGES @changes; # join("\n", @newspec );
  close CHANGES;

  return 1;
}

sub patchAFile( $$ ) {
    my ($filename, $rep) = @_;
    # rep is a hash reference.

    return 1 unless( -e $filename );

    open( SPEC, "<$filename" ) || die("No spec-file: $filename\n");
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
    open( SPEC, ">$filename" ) || die("Could not open $filename to write!\n");
    print SPEC @newspec;
    close SPEC;

    return 1;
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
  my $arch = readIniValue( $pack, "arch" );
  my $b = readIniValue( $pack, "builds" );

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
my $packName = readIniValue( $pack, "packagename" ) or $pack;

if( ! doBuild( $pack, $packName ) ) {
  print "Building failed -> EXIT!\n";
  exit 1;
}

chdir( $dir );



