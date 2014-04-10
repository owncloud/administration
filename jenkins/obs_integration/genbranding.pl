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
use File::Basename;
use File::Path;
use ownCloud::BuildHelper;
use Cwd;
use Template;

use strict;
use vars qw($miralltar $themetar $templatedir $dir $opt_h);

sub help() {
  print<<ENDHELP

  genbranding - Generates a branding from mirall sources and a branding

  Call the script with the tar ball of a branding

  Options:
  -h      this help text.

ENDHELP
;
  exit 1;
}


# ======================================================================================
sub getFileName( $ ) {
  my ($tarname) = @_;
  $tarname = basename($tarname);
  $tarname =~ s/\.tar.*//;
  return $tarname;
}

sub createTarBall( $ ) {
  my ($clientdir) = @_;
  system("/bin/tar", "xif", $miralltar);
  print "Extract mirall...\n";
  my $mirall = getFileName( $ARGV[0] );
  my $theme = getFileName( $ARGV[1] );
  my $newname = $mirall;
  $newname =~ s/-/-$theme-/;
  move($mirall, $newname);
  chdir($newname);
  print "Extracting theme...\n";
  system("/bin/tar", "--wildcards", "-xif", "$themetar", "*/mirall/*");
  chdir("..");
  print "Combining...\n";
  system("/bin/tar", "cfi", "$clientdir/$newname.tar.bz2", "$newname");
  rmtree("$newname");
}


sub createClientFromTemplate() {
  my $clienttemplatedir = "$templatedir/client";
  my $theme = getFileName( $ARGV[1] );
  mkdir("$theme-client");
  chdir("$theme-client");
  opendir(my($dh), $clienttemplatedir);
  my $source;
  # all files, excluding hidden ones, . and ..
  my $tt = Template->new(ABSOLUTE=>1);
  my $substs =
     {
        shortname => "owncloud", #lowercase, e.g. as in owncloud-client
        displayname => "ownCloud Client",
        version => "1.5.3",
        summary => "The ownCloud Client - Private file sync and share client",
        projecturl => "https://github.com/owncloud/mirall",
        tarball => "mirall-oem-1.5.3.tar.bz2",
        pkgdescription => "Such summary\n\nMuch Text!\nVery product!",
        pkgdescription_debian => "Such summary\n.\n Much Text!\n Very product!",
        sysconfdir => "etc/ownCloud", #(etc/ownCloud, but lowercase for all OEMs...), without a leading slash
        maintainer => "ownCloud Inc.",
        maintainer_person => "Markus Rex <msrex@owncloud.com>",
        desktopdescription => "ownCloud desktop sync client",

     };
  foreach my $source (grep ! /^\./,  readdir($dh)) {
    my $target = $source;
    $target =~ s/BRANDNAME/$theme/;
    if($source =~ /\.in$/) {
      $target =~ s/\.in$//;
      $tt->process("$clienttemplatedir/$source", $substs, $target) or die $tt->error();
    } else {
      copy("$clienttemplatedir/$source", $target);
    }
  }
  closedir($dh);
  return cwd();
}

# main here.
getopts('h');

help() if( $opt_h );

# remember the base dir.
$dir = getcwd;
mkdir("packages") unless( -d "packages" );

$miralltar = $dir .'/'. $ARGV[0];
$themetar = $dir .'/'. $ARGV[1];
$templatedir = $dir .'/'. "templates";
print "Mirall Tarball: $miralltar\n";
print "Theme Tarball: $themetar\n";

my $clientdir = createClientFromTemplate();
createTarBall($clientdir);
