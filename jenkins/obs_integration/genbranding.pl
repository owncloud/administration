#!/usr/bin/perl
#
# This script automates package build for jenkins based on OBS
# Copyright Klaas Freitag <freitag@owncloud.com>
#
# Released under GPL V.2.
#
# Requires: perl-Config-IniFiles
# Requires: perl-Template-Toolkit
#
# 2014-06-12 jw@owncloud.com, v1.1
#	- added  OBS_INTEGRATION_VERBOSE, OBS_INTEGRATION_OSC for
#	  debugging and more flexibility when calling osc. Suggested usage:
#	  env OBS_INTEGRATION_OSC='osc -Ahttps://s2.owncloud.com' ./genbranding.pl ...
#       - added OBS_INTEGRATION_PRODUCT to overwrite the default product openSUSE_13.1
#       - added '--download-api-only' per default to avoid issues with download.o.c.
#	- fixed the year in changelog entries.
#	- Deriving the version number from the client tar ball filename, per default.
#	  We can remove the version => ... entries from package.cfg now.
#
# 2014-06-20 jw@owncloud.com, v1.2
#       - option -p destproj added. Default: 'oem:*' Now I can test in home:jw:oem:*
#         without messing with killing official builds.
#       - option -r relid added. Default '<CI_CNT>.<B_CNT>'
#
# 2014-07-11, jw, V1.3
#	- allow absolute path names as parameters, too. Needed for scripting!
#
# 2014-07-25, jw, V1.4
#	- fixed removal of obsolete tar balls. Otherwise all Debians fail!
# 2014-08-19, jw, V1.5
#       - added -P -> [% prerelease %] support for the new universal specfile.
#       - added OBS_INTEGRATION_MSG for a tunneling a 'created by' message.
# 2014-09-15, jw, V1.6
#       - support for upper [% themename_deb %] and [% executable %].
# 2014-10-09, jw, V1.7
#       - support for trailing slash with -p proj_name/ added.
#         Semantics see setup_all_oem_client.pl
# 2015-01-22, jw, V1.7a accept also /syncclient/package.cfg instead of /mirall/package.cfg

use Getopt::Std;
use Config::IniFiles;
use File::Copy;
use File::Basename;
use File::Path;
use File::Find;
use ownCloud::BuildHelper;
use Cwd;
use Template;
use Data::Dumper;

my $msg_def = "created by: $0 @ARGV";

use strict;
use vars qw($clienttar $themetar $templatedir $dir $opt_h $opt_o $opt_b $opt_c $opt_n $opt_f $opt_p $dest_prj $dest_prj_theme $opt_r);

sub help() {
  print<<ENDHELP

  genbranding - Generates a branding from client sources and a branding

  Both the client and the branding tarball have to be passed ot this
  script. It combines both and creates a new branded source pack. It also
  creates packaging input files (spec-file and debian packaging files).

  This script reads the following input files
  - OEM.cmake from the branding tarball
  - a file mirall/package.cfg from the branding dir.
    or a file syncclient/package.cfg from the branding dir.
  - templates for the packaging files from the local templates directory

  Options:
  -h:           help, displays help text
  -b:           build the package locally before uploading
  -o:           osc mode, build against ownCloud obs
  -c "params":  additional osc paramters
  -n:           don't recreate the tarball, use an existing one.
  -f:           force upload, upload even if nothing changed.
  -p "project":	obs (p)roject used for -o and -b. Default: '$dest_prj'
  -r "relid":	specify a build release identifier. This number will be part of the binary file names built by osc.

  Call example:
  ./genbranding.pl client-1.7.1.tar.bz2 testpilotcloud.tar.bz2
  ./genbranding.pl owncloudclient-1.5.3.tar.bz2 cern.tar.bz2

  Output will be in directory cern-client.
  Build directory (with -b) will be oem:cern-client.

  Options:
  -h      this help text.

  Environment variables and their defaults:
    OBS_INTEGRATION_MSG='$msg_def'
    OBS_INTEGRATION_VERBOSE=''
    OBS_INTEGRATION_OSC='/usr/bin/osc'
    OBS_INTEGRATION_PRODUCT='openSUSE_13.1'
    OBS_INTEGRATION_ARCH='x86_64'

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

sub buildOwnCloudTheme( $ )
{
   my( $theme ) = @_;

   return 1 if( $theme eq 'ownCloud' );
   return 0;
}

# Extracts the client tarball and puts the theme tarball the new dir
sub prepareTarball($$) {
    my ($argv0, $argv1) = @_;
    print "Preparing tarball...";

    system("/bin/tar", ("xif", $clienttar, "--force-local") );
    print "Extract client...\n";
    my $client = getFileName( $argv0 );
    my $theme  = getFileName( $argv1 );

    # client is owncloudclient-1.8.0pre1
    # theme is cernbox => cernbox-client-1.8.0pre1

    my $newname = $client;
    if( buildOwnCloudTheme($theme) ) {
        print "Creating the original ownCloud package tarball!\n";
        $newname = lc $client; # all small letters
    } else {
        $newname =~ s/^client/$theme/i; # note: no -client suffix. works with setup_all_oem_clients.pl
        $newname =~ s/^owncloud/$theme/i; # note that we add a - here.
    }

    if( $newname ne $client ) {
        move($client, $newname);
    }
    chdir($newname);

    print "Extracting theme...\n";

    my @args = ("--wildcards", "--force-local", "-xif", "$themetar");
    print "Create branded tarball in $newname\n";

    # Do try to extract both directory names mirall and syncclient because
    # at one point of time we were forced to rename mirall -> client
    my $r1 = system("/bin/tar", @args, '*/mirall/*');
    my $r2 = system("/bin/tar", @args, '*/syncclient/*');
    die "Error: tar @args ... : $@ $!"        if $r1 and $r2;
    warn "One tar error is expected above.\n" if $r1  or $r2;
    chdir("..");

    print " success: $newname\n";
    return $newname;
}

# read all files from the template directory and replace the contents
# of the .in files with values from the substition hash ref.
sub createPackageMetaFromTemplate($$) {
    my ($substs, $packName) = @_;

    print "Create client from template\n";
    foreach my $log( keys %$substs ) {
	print "  - $log => $substs->{$log}\n";
    }

    my $clienttemplatedir = "$templatedir/client";
    my $theme = getFileName( $ARGV[1] );

    my $targetDir = "$theme-client";

    if( $opt_o ) {
	$targetDir = "$dest_prj_theme/$packName";
    } else {
	mkdir("$theme-client");
    }

    my $versdir = 'v'.$1 if $substs->{version} =~ m{^([^-]+)};
    $versdir =~ s{\.}{_}g;
    print "versdir=$clienttemplatedir/$versdir\n";
    my $dh;
    unless (opendir($dh, "$clienttemplatedir/$versdir")) {
        opendir DIR, $clienttemplatedir;
        my @have_vdirs = grep { -d "$clienttemplatedir/$_" and /^v/ } readdir DIR;
        closedir DIR;
	my $have_vdirs = join(' ', sort @have_vdirs);
        die qq{$0: missing a $versdir subdirectory in $clienttemplatedir/.
There we expect to find all the templates for this $substs->{version} version.
All we have is: $have_vdirs

Please do the following steps (or similar):
 \$ git clone git\@github.com:owncloud/administration.git
 \$ cd jenkins/obs_integration/templates/client
 \$ mkdir $versdir;
 # Chosse a v... dir that is similar.
 \$ cp v.../* $versdir;
 # Peek at nightly or testing obs projects to see what needs merging here.
 # Edit/add files as needed. Ha!
 \$ vi $versdir/*
 \$ git add $versdir/*
 \$ git commit -a
 \$ git push
 # Then try again. Good luck!
};
      }

    my @tmpl_files = grep { ! /^\./ } readdir($dh);
    closedir($dh);

    my $source;
    # all files, excluding hidden ones, . and ..
    my $tt = Template->new(ABSOLUTE=>1);

    foreach my $source (@tmpl_files) {
        my $target = $source;
        $target =~ s/BRANDNAME_DEB/$substs->{themename_deb}/;	# longer subst first. We have no delimiters.
        if( buildOwnCloudTheme($theme) ) {
            # for owncloud we need the lowercase variant.
	    $target =~ s/BRANDNAME/$substs->{themename_deb}/;
	} else {
	    $target =~ s/BRANDNAME/$substs->{themename}/;
	}
        $target =~ s/SHORTNAME/$substs->{shortname}/;

        if($source =~ /\.in$/) {
            print "process $clienttemplatedir/$versdir/$source to $targetDir/$target\n";
            $target =~ s/\.in$//;
            $tt->process("$clienttemplatedir/$versdir/$source", $substs, "$targetDir/$target") or die $tt->error();
        } else {
            print "copy $clienttemplatedir/$versdir/$source ...\n";
            copy("$clienttemplatedir/$versdir/$source", "$targetDir/$target");
        }
     }

     return cwd();
}

# Create the final themed tarball
sub createTar($$)
{
    my ($clientdir, $newname) = @_;

    my $tarName = "$clientdir/$newname.tar.bz2";

    if( $opt_n ) {
	die( "Option -n given, but no tarball $tarName exists\n") unless( -e $tarName );
	return;
    }
    my $cwd = cwd();

    die( "Can not find directory to tar: $newname\n" ) unless( -d $newname );

    print "Creating tar $tarName from $newname, in cwd $cwd\n";

    # check to create a backup file
    if( -e $tarName ) {
      my $bakname = $tarName . ".bak";
      unlink( $bakname ) if( -e $bakname );
      move( $tarName, $bakname );
      unlink( $tarName );
    }

    # remove the package.cfg in the target tarball.

    my @args = ("cjfi", $tarName, $newname, "--force-local") ;
    system("/bin/tar", @args);
    rmtree("$newname");
    print " success: Created $tarName\n";
}

# open the OEM.cmake
sub readOEMcmake( $ )
{
    my ($file) = @_;
    my %substs;

    print "Reading OEM cmake file: $file\n";

    die("Could not open <$file>\n") unless open( OEM, "$file" );
    my @lines = <OEM>;
    close OEM;

    foreach my $l (@lines) {
        chop $l;
	if( $l =~ /^\s*set\(\s*(\S+)\s*"*(.+?)"*\s*\)\s*$/i ) {
	    my $key = $1;
	    my $val = $2;
	    print "  * found <$key> => $val\n";
	    $substs{$key} = $val;
	} else {
            print "  * OEM.cmake PARSE error: $l\n";
        }
    }

    unless( $substs{APPLICATION_SHORTNAME} ) {
      # needed to have a shortname for the packaging templates
      $substs{APPLICATION_SHORTNAME} = $substs{APPLICATION_NAME};
    }

    if( $substs{APPLICATION_SHORTNAME} ) {
	$substs{shortname} = $substs{APPLICATION_SHORTNAME};
	$substs{displayname} = $substs{APPLICATION_SHORTNAME};
    }
    if( $substs{APPLICATION_NAME} ) {
	$substs{displayname} = $substs{APPLICATION_NAME};
    }
    if( $substs{APPLICATION_DOMAIN} ) {
	$substs{projecturl} = $substs{APPLICATION_DOMAIN};
    }
    if( $substs{APPLICATION_EXECUTABLE} ) {
	$substs{executable} = $substs{APPLICATION_EXECUTABLE};
    }
    # more tags: APPLICATION_EXECUTABLE, APPLICATION_VENDOR, APPLICATION_REV_DOMAIN, THEME_CLASS, WIN_SETUP_BITMAP_PATH
    return %substs;
}

sub getSubsts( $ )
{
    my ($subsDir) = @_;
    my $cfgFile;
    my $oem_sub_dir;

    find( { wanted => sub {
	if( $_ =~ /(mirall|syncclient)\/package.cfg/ ) {
	    print "Substs from $File::Find::name\n";
	    $cfgFile = $File::Find::name;
	    $oem_sub_dir = $1;
          }
        },
	no_chdir => 1 }, "$subsDir");

    die("Please provide a syncclient/package.cfg file in the custom dir!\n") unless( $cfgFile );

    print "Reading substs from $cfgFile\n";

    my $oemFile = $cfgFile;
    $oemFile =~ s/package\.cfg/OEM.cmake/;

    unless( -e $oemFile ) {
      $oemFile = "$subsDir/OWNCLOUD.cmake";
    }
    my %substs = readOEMcmake( $oemFile );
    $substs{'oem_sub_dir'} = $oem_sub_dir;

    # read the file package.cfg from the tarball and also remove it there evtl.
    my %s2;
    if( -r "$cfgFile" ) {
	%s2 = do $cfgFile;
    } else {
	die "ERROR: Could not read package config file $cfgFile!\n";
    }

    # now remove the cfg file as we do not need it later
    unlink $cfgFile;

    foreach my $k ( keys %s2 ) {
	$substs{$k} = $s2{$k};
    }

    # calculate some subst values, such as
    $substs{tarball} = $subsDir unless( $substs{tarball} );
    $substs{pkgdescription_debian} = debianDesc( $substs{pkgdescription} );
    $substs{sysconfdir} = "/etc/". $substs{shortname} unless( $substs{sysconfdir} );
    $substs{maintainer} = "ownCloud Inc." unless( $substs{maintainer} );
    $substs{maintainer_person} = "ownCloud packages <packages\@owncloud.com>" unless( $substs{maintainer_person} );
    $substs{desktopdescription} = $substs{displayname} . " desktop sync client" unless( $substs{desktopdescription} );

    # try to substitute variables
    foreach my $key (keys %substs) {
        my $value = $substs{$key};
        if( $value =~ /^\$\{(.+)\}$/ ) {
            if( exists $substs{$1} ) {
                my $newVal = $substs{$1};
                $substs{$key} = $newVal;
                print " * Substituted $key = $value => $newVal\n";
            } else {
                print " * Could not substitute $value\n";
            }
        }
    }
    return \%substs;
}


# main here.
$dest_prj = 'oem';
getopts('fnbohc:p:r:');
$dest_prj = $opt_p if defined $opt_p;
$dest_prj =~ s{:$}{};

my $create_msg = $ENV{OBS_INTEGRATION_MSG} || $msg_def;

# The tarball of the "raw" onwcloud client tarball is owncloudclient-<version>.tar.bz2
# The branding tarball is <brandingname>.tar.bz2
# The name of the resulting tarball is <branding>-client-<version>.tar.bz2
# If the branding is ownCloud.tar.bz2, the tarball name stays owncloudclient-<version>.tar.bz2


help() if( $opt_h );
help() unless( defined $ARGV[0] && defined $ARGV[1] );

# remember the base dir.
$dir = getcwd;

# Not used currently
# mkdir("packages") unless( -d "packages" );

$clienttar = ($ARGV[0] =~ m{^/}) ? $ARGV[0] : $dir .'/'. $ARGV[0];
$themetar  = ($ARGV[1] =~ m{^/}) ? $ARGV[1] : $dir .'/'. $ARGV[1];
$templatedir = $dir .'/'. "templates";
print "Client Tarball: $clienttar\n";
print "Theme Tarball: $themetar\n";

# if -o (osc mode) check if an oem directory exists
my $theme = getFileName( $ARGV[1] );

my $packName = "$theme-client";

if( buildOwnCloudTheme($theme) ) {
    $dest_prj_theme = $dest_prj;
    $packName = 'owncloud-client'; # historical reason, not ownCloud-client
} else {
    $dest_prj_theme = "$dest_prj:$theme";
    $dest_prj_theme = $dest_prj if $dest_prj =~ m{/$};
    $dest_prj_theme =~ s{/$}{}; # Remove trailing slash
}

if( $opt_o ) {
    my $cwd = Cwd::getcwd;
    unless( -d "./$dest_prj_theme" && -d "./$dest_prj_theme/.osc" ) {
	print "Checking out package $dest_prj_theme/$packName\n";
	checkoutPackage( "$dest_prj_theme", "$packName", $opt_c );
    } else {
	# Update the checkout
	my @osc = oscParams($opt_c);
	push @osc, 'up';
	chdir( "$dest_prj_theme/$packName");
	doOSC( @osc );
    }
    chdir($cwd);
}

my $dirName = prepareTarball($ARGV[0], $ARGV[1]);

# returns hash reference
my $substs = getSubsts($dirName);
$substs->{themename} = $theme;
$substs->{themename_deb} = lc $theme;	# debian packagin guide allows no upper case. (e.g. SURFdrive).
$substs->{create_msg} = $create_msg || '' unless defined $substs->{create_msg};
$substs->{summary} = "The $theme client";	# prevent shdbox to die with empty summary.

# Automatically derive version number from the client tarball.
# It is used in the spec file to find the tar ball anyway, so this should be safe.
unless( defined $substs->{version} )
  {
    my $vers = getFileName($clienttar);
    my $prerel;

    print "parsing version from '$vers' ...\n";

    if( $vers =~ /(\d+\.\d+\.\d+)(\w+\d+)$/ ) {
        $vers = $1;
        $prerel = $2;
        $substs->{version_deb} = $vers . '~' . $prerel;
    } elsif( $vers =~ /(\d+\.\d+\.\d+)/ ) {
        $vers = $1;
        $prerel = '%nil';
        $substs->{version_deb} = $vers;
    } else {
        die "\n\nOops: client filename $vers does not match {-(\\d[\\d\\.]\*)\$}.\n Cannot exctract version number from here.\n Please add 'version' to package.cfg in $themetar\n";
    }
    print " ... version='$vers' prerelease='$prerel'\n";
    $substs->{version} = $vers;
    $substs->{prerelease} = $prerel;
  }

unless (defined $substs->{buildrelease} )
  {
    if (defined $opt_r)
      {
        $substs->{buildrelease} = "<CI_CNT>.<B_CNT>.$opt_r";
        $substs->{buildrelease_deb} = "0.$opt_r";
	$substs->{buildrelease_deb} =~ s{[^a-zA-Z0-9\.]}{}g;	# sanitized
      }
    else
      {
        $substs->{buildrelease} = '0';
        $substs->{buildrelease_deb} = '0';
      }
  }

createPackageMetaFromTemplate( $substs, $packName );

my $clientdir = ".";


if( $opt_o ) {
    $clientdir = "$dest_prj_theme/$packName";
}
createTar($clientdir, $dirName);

# Check if really files were added and if the tarball was already added
# to the osc repo
my $changeCnt = 0;

if( $opt_o ) {
    chdir( $clientdir );
    print "==== oscChangedFiles: Clientdir: $clientdir\n";
    my %changes = oscChangedFiles($opt_c);

    foreach my $changed_file (keys %changes) {
	# print " * Checking $changed_file => $changes{$changed_file} ($dirName.tar.bz2)\n";
	if( $changes{$changed_file} =~ /[A\?M]/ ) {
	    my @osc = oscParams($opt_c);
	    if( $changes{$changed_file} eq '?' ) { # Add the new tarball to obs
		push @osc, ('add', $changed_file);
		doOSC(@osc);
		$changeCnt++;
	    }

	    # remove the previous tarball!
	    # search for the old tarball
	    if( $changed_file eq $dirName . ".tar.bz2" ) {
	      my $oldTar = $dirName; # something like client-cernbox-1.6.0nightly20140505
	      $oldTar =~ s/(.+)-.*?$/$1/;   # remove the version	(aka chop at the last '-')

	      opendir(my $dh, '.') || die "can't opendir '.': $!";
	      my @f = readdir($dh);
	      closedir $dh;
	      my @obsoleted = grep { /\Q$oldTar\E-.*\.tar\.bz2/ && $_ ne $changed_file } @f;

	      foreach my $begone (@obsoleted)
		{
		  if( -e $begone ) {
		      print "Removing obsolete source tar file $begone\n";
		      @osc = oscParams($opt_c);
		      push @osc, ('rm', $begone);
		      doOSC(@osc);
		      $changeCnt++;
		  }
		}
	    }
	} else {
	    print "  Status of $changed_file: $changes{$changed_file}\n";
	    # count files with real changes
	    if( $changes{$changed_file} !~ /[MD]/ ) {
		print "Error: An unexpected file <$changed_file> was found in the osc package.\n";
		die("Please remove or osc add and try again!\n");
	    }
	    $changeCnt++;
	}
    }
    chdir( "../.." );
    print "----\n";
}

# Finished if nothing changed.
if( $changeCnt == 0 && ! $opt_f && $opt_o ) {
    print "No changes to the package, exit!\n";
    exit(0);
}

# Add changelog entries
if( $opt_o ) {
    chdir( $clientdir );
    # create and osc add changelog files if they do not exist yet.
    foreach my $f ( ('debian.changelog', "$packName.changes") ) {
      unless( -e $f ) {
	system( "touch $f" );
	my @osc = oscParams($opt_c);
	push @osc, ('add', $f);
	doOSC(@osc);
      }
    }

    my $change = "  Automatically generated branding added. Version=$substs->{version}";
       $change .= ", release_id=$opt_r" if defined $opt_r;
       $change .= "\n  $create_msg"  if length $create_msg;
       $change .= "\n";

    # FIXME: themename_deb
    my $debpackname = lc $packName;
    addDebChangelog(  $debpackname, $change, $substs->{version_deb} );
    addSpecChangelog( $packName, $change );
    chdir( "../.." );
}

# Build the package
my $buildOk = 0;
if( $opt_b ) {
    my @osc = oscParams($opt_c);
    my $product = $ENV{OBS_INTEGRATION_PRODUCT} || 'openSUSE_13.1';
    my $arch =    $ENV{OBS_INTEGRATION_ARCH}    || 'x86_64';
    push @osc, ('build', '--no-service', '--clean', '--download-api-only', '--local-package', $product, $arch, "$packName.spec");
    print "+ osc " . join( " ", @osc ) . "\n";
    chdir( $clientdir );
    $buildOk = doOSC( @osc );
    chdir( "../.." );
}

# push to obs.
if( $opt_o ) {
    if( $opt_b ) {
	die( "Local build failed, no uplaod!" ) unless ( $buildOk );
    }
    chdir( $clientdir );

    my @osc = oscParams($opt_c);
    push @osc, ('diff');
    doOSC( @osc );

    @osc = oscParams($opt_c);
    push @osc, ('commit', '-m', 'Pushed by genbranding.pl; ' . $create_msg);

    $buildOk = doOSC( @osc );
    chdir( "../.." );
}

print "buildOk=$buildOk\n";
print " Finished!\n\n";
