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

# Extracts the mirall tarball and puts the theme tarball the new dir
sub prepareTarBall( ) {
    print "Preparing tarball...";

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

    print " success: $newname\n";
    return $newname;
}

# Create the final themed tarball 
sub createTar($$)
{
    my ($clientdir, $newname) = @_;
    print "Combining >$clientdir + $newname<\n";
    my $tarName = "$clientdir/$newname.tar.bz2";
    system("/bin/tar", "cjfi", $tarName, $newname);
    rmtree("$newname");
    print " success: Created $tarName\n";
}

# read all files from the template directory and replace the contents
# of the .in files with values from the substition hash ref.
sub createClientFromTemplate($) {
    my ($substs) = @_;

    print "Create client from template\n";
    my $clienttemplatedir = "$templatedir/client";
    my $theme = getFileName( $ARGV[1] );
    mkdir("$theme-client");
    chdir("$theme-client");
    opendir(my $dh, $clienttemplatedir);
    my $source;
    # all files, excluding hidden ones, . and ..
    my $tt = Template->new(ABSOLUTE=>1);
 
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
     chdir("..");
     return cwd();
}


sub getSubsts( $ ) 
{
    my ($subsDir) = @_;

    my %substs;
    # read the file package.cfg from the tarball and also remove it there evtl.
    
    # calculate some subst values, such as 
    $substs{tarball} = $substs{shortname} . "-oem-" . $substs{version} . ".tar.bz2";
    $substs{pkgdescription_debian} = $substs{pkgdescription};
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

my $dirName = prepareTarBall();

# returns hash reference
my $substs = getSubsts($dirName);

my $clientdir = createClientFromTemplate( $substs );

createTar($clientdir, $dirName);
