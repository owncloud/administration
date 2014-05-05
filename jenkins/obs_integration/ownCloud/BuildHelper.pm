#
# Copyright (c) 2014 Klaas Freitag <freitag@owncloud.com>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
#
################################################################
# Contributors:
#  Klaas Freitag <freitag@owncloud.com>
#
package ownCloud::BuildHelper;

use strict;
use Exporter;

use vars qw( @ISA @EXPORT @EXPORT_OK $d %config);

@ISA        = qw(Exporter);
@EXPORT     = qw( readIniValue doOSC checkoutPackage getFromSpecfile addDebChangelog
                  addSpecChangelog patchAFile oscParams debianDesc oscChangedFiles);

# Read values from a config file in Windows Ini format.
# paramters: 
# 1. full path of the config file
# 2. Name of the section
# 3. Default value
sub readIniValue( $$$ ) {
  my ($file, $sectionName, $value) = @_;

  my $key;
  my $cfg = new Config::IniFiles( -file => $file, -nocase => 1  );

  if( $cfg->SectionExists( $sectionName ) ) {
    $key = $cfg->val( $sectionName, $value );
  }
  return $key;
}

# takes a string for example coming as a command line option
# and returns an array to pass to the doOSC function.
sub oscParams($) {
    my ($p) = @_;

    return split( /\s+/, $p );
}

# fix debian description: replace empty lines by a dot
# and indent everything by one space.
sub debianDesc( $ )  {
    my ($desc) = @_;

    # replace empty lines by a .
    $desc =~ s/\n\s*\n/\n.\n/s;

    # add space at the beginning of a line
    $desc =~ s/^(.)/ $1/mg;

    # Add a trailing newline
    $desc .= "\n" unless( $desc =~/\n\n$/ );

    return $desc;
}

# Compute which files have changed for osc in the current directory.
# The parameter are additional osc parameters to be passed to oscParams
sub oscChangedFiles($)
{
    my ($params) = @_;

    my @osc = oscParams($params);
    push @osc, ('status');

    unshift(@osc, "/usr/bin/osc");

    my $cmd = join ( ' ', @osc );
    print "Status command: $cmd\n";
    my $res = `$cmd`;

    my %r;
    my @ll = split( /\n/, $res );
    foreach my $l ( @ll ) {
	if( $l =~ /(.)\s+(\S.*)$/ ) {
	    $r{$2} = $1;
	}
    }
    return %r;
}

# Execute osc
# Pass an array with parameters, they get appended
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

# Check out a package from a repo via osc
# Note: this only works if current working directory is the directory
# where the checked out packages are
sub checkoutPackage( $$ ) {
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

# Returns the value of a tag from a spec-file
# The first parameter is the path to a spec file with or without
# the extension .spec. The second parameter is the name of the 
# tag to return.
sub getFromSpecfile( $$ ) {
  my ($pack, $tag) = @_;
  my $re;

  return unless( $tag );

  # append the extension spec if it is not there.
  $pack .= ".spec" unless( $pack =~ /\.spec$/ );

  my $specfile = $pack;

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

# Add a changelog entry to a debian changelog in the current working directory
# Parameter:
# 1. name of the package
# 2. Changelog to add
# 3. Package version
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

# Add an entry to a spec Changelog
# Parameters:
# 1. package name
# 2. Changelog entry
sub addSpecChangelog( $$ ) {
  my ($pack, $changelog) = @_;

  my $changesfile = "$pack.changes";

  open( CHANGES, "<$changesfile" ) || die("No changes-file: $changesfile\n");
  my @changes = <CHANGES>;
  close CHANGES;

  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime(time);
  my @mabbr = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
  my @wabbr = qw( Sun Mon Tue Wed Thu Fri Sat );
  my $dateClg = sprintf( "%02d:%02d:%02d", $hour, $min, $sec );
  my $dateline = "$wabbr[$wday] $mabbr[$mon] $mday " . $dateClg . " UTC 2013 - jenkins\@owncloud.org";

  unshift( @changes, "\n$changelog\n\n" );
  unshift( @changes, "\n$dateline\n" );
  unshift( @changes, "-------------------------------------------------------------------");

   # write the new spec file.
  open( CHANGES, ">$changesfile" ) || die("Could not open Changesfile to write!\n");
  print CHANGES @changes; # join("\n", @newspec );
  close CHANGES;

  return 1;
}

#
# patch a file with values from a hash reference
# Parameter: 
# 1. Filename of the file
# 2. Hash reference with values to patch
#    The keys of the hash are appended automatically with a colon
#    ie. "name" => "Klaas" sets the tag name: to Klaas
#
sub patchAFile( $$ ) {
    my ($filename, $rep) = @_;
    # rep is a hash reference.

    return 1 unless( -e $filename );

    open( SPEC, "<$filename" ) || die("Unable to open $filename: $!\n");
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
