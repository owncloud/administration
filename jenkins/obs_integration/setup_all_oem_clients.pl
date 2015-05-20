#! /usr/bin/perl -w
#
# (c) 2014 jw@owncloud.com - GPLv2 or ask.
#
# 
# Iterate over customer-themes github repo, get a list of themes.
# for each theme, 
#  - generate the branding tar ball
#  - generate project hierarchy (assert that ...:oem:BRANDINGNAME exists)
#  - assert the client package exists, (empty or not)
#  - checkout the client package
#  - run ./genbranding.pl with a build token number.
#  - checkin (done by genbranding)
#  - Remove the checkout working dir. It is not in the tmp area.
#  - run ./setup_oem_client.pl with the dest_prj, (packages to be created on demand)
#
# This replaces:
#  https://rotor.owncloud.com/view/mirall/job/mirall-source-master (rolled into
#  https://rotor.owncloud.com/job/customer-themes		   (we pull ourselves)
#  https://rotor.owncloud.com/view/mirall/job/mirall-linux-custom  (another genbranding.pl wrapper)
#
# TODO: Poll obs every 5 minutes:
#  For each packge in the obs tree
#   - check all enabled targets for binary packages with the given build token number.
#     if a package has them all ready. Generate the linux package binary tar ball.
#   - run administration/s2.owncloud.com/bin pack_client_oem (including check_packed_client_oem.pl)
#     to consistently publish the client.
#
# CAUTION:
# genbranding.pl only works when its cwd is in its own directory. It needs to find its 
# ownCloud/BuildHelper.pm and templates/clinet/* files.
# -> disadvantage, it creates a temporary working directory there.
#
#
# 2014-08-15, jw, added support for testpilotcloud at obs.
# 2014-08-19, jw, calling genbranding.pl with -P if prerelease and with OBS_INTEGRATION_MSG 
# 2014-08-20, jw, split prerelease from branch where [abr-]...
# 2014-09-03, jw, template named in create_msg, so that the changelogs (at least) refers to the relevant changelog.
# 2014-09-09, jw, dragged in OSC_CMD to infuse additional osc parameters. Needed for jenkins mirall-linux-oem job
# 2014-10-09, jw, trailing slash after project name means: no automatic subproject please.
# 2015-01-22, jw, accept /syncclient/package.cfg instead of /mirall/package.cfg (seen with testpilotclient)
# 2015-02-03, jw, option -P got removed from genbranding. We prepare the client tar ball with the prerelease tag now.
# 2015-02-15, jw, added make_dummy_package_cfg() using OEM.cmake -- it does not get any better.
# 2015-03-18, jw, moved subroutines at the end. Allow both, client and branding to be provided as tar-files, instead
#                 as git-branch and branding name in cusomer-themes. This feature is neeed for ownbrander.

use Data::Dumper;
use File::Copy;
use File::Path;
use File::Temp ();	# tempdir()
use POSIX;		# strftime()
use Cwd ();

# used only by genbranding.pl -- but better crash here if missing:
use Config::IniFiles;	# Requires: perl-Config-IniFiles
use Template;		# Requires: perl-Template-Toolkit


my $build_token         = 'oc_'.strftime("%Y%m%d", localtime);
my $source_tar          = shift;

if (!defined $source_tar or $source_tar =~ m{^-})
  {
    die qq{
Usage: $0 v1.6.2 [home:jw:oem[/] [filterbranding,... [api [tmpl]]]]

       $0 v1.8.1 isv:ownCloud:community:testing testpilotcloud https://api.opensuse.org  isv:ownCloud:desktop
       osc copypac isv:ownCloud:community:testing:testpilotcloud testpilotcloud-client isv:ownCloud:community:testing
       osc rdelete isv:ownCloud:community:testing:testpilotcloud --recursive

... or similar.

Special case example without accessing github:

       $0 owncloudclient-1.8.0.tar.xz home:jw:oem rzg.tar.xz [api [tmpl]]

The build service project name is normally constructed from second and third 
 parameter. I.e.  the brandname is appended to the specified 'parent project 
 name' to form the complete subproject name.
 This is useful to create one subproject per branding.

If you specify the projectname with a trialing slash, it is taken as the 
 subproject name as is.  This is useful to have all brandings in the same 
 project, or if only one branding is intended.

If you specify a client tar-file as first and a branding tar-file as third parameter, 
no github is accessed.  These tar files are used directly. 
The branding tar-file must have a top level directory named like the branding.
The client tar-file must have a top level directory exactly name as the tar-file 
but without the tar.* extension.
};
  }

my $container_project   = shift || 'oem';	#'home:jw:oem';	'ownbrander';

my $client_filter	= shift || "";
my @client_filter	= split(/[,\|\s]/, $client_filter);
my %client_filter = map { $_ => 1 } @client_filter;

my $obs_api             = shift || 'https://s2.owncloud.com';
my $template_prj 	= shift || 'desktop';
my $template_pkg 	= shift || 'owncloud-client';
my $create_msg 		= $ENV{OBS_INTEGRATION_MSG} || "created by: $0 @ARGV; template=$template_prj/$template_pkg";


my $TMPDIR_TEMPL = '_oem_XXXXX';
our $verbose = 1;
our $no_op = 0;
my $skipahead = 0;	# 4 = all checkouts done. 5 = all tarballs created.

my $customer_themes_git = $ENV{CUSTOMER_THEMES_GIT} || 'git@github.com:owncloud/customer-themes.git';
my $source_git          = 'https://github.com/owncloud/client.git';
my $osc_cmd             = "osc -A$obs_api";
my $genbranding         = "./genbranding.pl -c '-A$obs_api' -p '$container_project' -r '$build_token' -o -f";
if ($ENV{'OSC_CMD'})
  {
    $osc_cmd = "$ENV{'OSC_CMD'} -A$obs_api";
    $osc_param = $ENV{'OSC_CMD'};
    $osc_param =~ s{^\S+\s+}{};	# cut away $0
    $genbranding        = "./genbranding.pl -c '$osc_param -A$obs_api' -p '$container_project' -r '$build_token' -o -f";
  }

unless ($ENV{CREATE_TOP} || obs_prj_exists($osc_cmd, $container_project))
  {
    print "container_project $container_project does not exist.\n";
    print "Check your command line: version container pkgfilter ...\n";
    print "If you want to creat it, run again with 'env CREATE_TOP=1 ...'\n";
    exit(1);
  }

print "osc_cmd='$osc_cmd';\ngenbranding='$genbranding';\n";

my $scriptdir = $1 if Cwd::abs_path($0) =~ m{(.*)/};

my $tmp;
if ($skipahead)
  {
    $tmp = '/tmp/_oem_Rjc9m';
    print "re-using tmp=$tmp\n";
  }
else
  {
    $tmp = File::Temp::tempdir($TMPDIR_TEMPL, DIR => '/tmp/');
  }
my $tmp_t = "$tmp/customer_themes_git";

print "source_tar=$source_tar\n";
my $version = undef;
my $prerelease = undef;
($source_tar,$version,$prerelease) = fetch_client_from_branch($source_git, $source_tar, $tmp);
$source_tar = Cwd::abs_path($source_tar);	# we'll chdir() around. Take care.
print "source_tar=$source_tar\n";
die "need a source_tar path name or version number matching /^v[\\d\\.]+/\n" unless defined $source_tar and -e $source_tar;

print "prerelease=$prerelease\n" if defined $prerelease;
print "\nwaiting 5 sec. Press CTRL-C now if this looks odd.\n";
sleep 5;


my @candidates = ();

if (scalar(@client_filter) and -f $client_filter[0])
  {
    for my $f (@client_filter)
      {
        $f = Cwd::abs_path($f);		# we'll chdir() around. Take care.
        push @candidates, $f;
      }
    %client_filter = map { $_ => 1 } @client_filter;	# refresh the hash with full path names.
  }
else
  {
    # checkout customer_themes_github unless we have a tar file name passed as third parameter (or a list of file names)
    run("git clone --depth 1 $customer_themes_git $tmp_t") 
      unless $skipahead > 3;

    opendir(DIR, $tmp_t) or die("cannot opendir my own $tmp: $!");
    my @d = grep { ! /^\./ } readdir(DIR);
    closedir(DIR);

    for my $dir (sort @d)
      {
	my $linuxdir = 'syncclient';
	$linuxdir = 'mirall' unless -d "$tmp_t/$dir/$linuxdir";
	next unless -d "$tmp_t/$dir/$linuxdir";
	next if @client_filter and not $client_filter{$dir};
	#  - generate the branding tar ball
	# CAUTION: keep in sync with jenkins jobs customer_themes
	# https://rotor.owncloud.com/view/mirall/job/customer-themes/configure

	if ( @client_filter and -f "$tmp_t/$dir/$linuxdir/OEM.cmake" and not -f "$tmp_t/$dir/$linuxdir/package.cfg")
	  {
	    # we asked for this via a filter, the OEM.cmake is there, but no package.cfg
	    make_dummy_package_cfg("$tmp_t/$dir/$linuxdir");
	  }

	chdir($tmp_t);
	run("tar cjf ../$dir.tar.bz2 ./$dir")
	  unless $skipahead > 4;

	push @candidates, $dir if -f "$tmp_t/$dir/$linuxdir/package.cfg";
      }
  }

print Dumper \@candidates;

## make sure the top project is there in obs
obs_prj_from_template($osc_cmd, $template_prj, $container_project, "OwnCloud Desktop Client OEM Container project");
chdir($scriptdir) if defined $scriptdir;

for my $branding (@candidates)
  {
    # branding is either a tar file name or the brandname.
    if (@client_filter)
      {
        unless ($client_filter{$branding})
	  {
	    print "Branding $branding skipped: not in client_filter\n";
	    next;
	  }
	delete $client_filter{$branding};
      }

    my $branding_tar = undef;
    ($branding_tar,$branding) = ($branding,$2) if $branding =~ m{^(.*/)?(.*)(\.tar\..*?)$};
    # die Dumper [$branding_tar, $branding];
    my $project = "$container_project:$branding";
    my $container_project_colon = "$container_project:";
    if ($container_project =~ m{/$})
      {
        $project = $container_project;
	$project =~ s{/$}{};
        $container_project_colon = $container_project;
      }

    ## generate the individual container projects
    obs_prj_from_template($osc_cmd, $template_prj, $project, "OwnCloud Desktop Client project $branding");

    ## create an empty package, so that genbranding is happy.
    obs_pkg_from_template($osc_cmd, $template_prj, $template_pkg, $project, "$branding-client", "$branding Desktop Client");

    $branding_tar = "$tmp/$branding.tar.bz2" unless defined $branding_tar;	# when branding comes from git checkout.
      
    # checkout branding-client, update, checkin.
    run("rm -rf '$project'");
    run("$osc_cmd checkout '$project' '$branding-client'");
    # we run in |cat, so that git diff not open less with the (useless) changes 
    run("env PAGER=cat OBS_INTEGRATION_MSG='$create_msg' $genbranding '$source_tar' '$branding_tar'");	
    # FIXME: abort, if this fails. Pipe cat prevents error diagnostics here. Maybe PAGER=cat helps?

    run("rm -rf '$project'");

    ## fill in all the support packages.
    ## CAUTION: trailing colon is important when catenating. 
    ## We use trailing slash here again to avoid catenating.
    run("./setup_oem_client.pl '$branding' '$container_project_colon' '$obs_api' '$template_prj'");

    # inspection code below commented out. It assumes shortname == executable name.
    ## babble out the diffs. Just for the logfile.
    ## This helps catching outdated *.in files in templates/client/* -- 
    ## genbranding uses them. Mabye it should use files from the template package as template?
    # for my $f ('%s-client.spec', '%s-client.dsc', 'debian.control', '%s-client.desktop')
    #   {
    #     my $template_file = sprintf "$f", 'owncloud';
    #     my $branding_file = sprintf "$f", $branding;
    # 	run("$osc_cmd cat $template_prj $template_pkg $template_file > $tmp/$template_file || true");
    # 	run("$osc_cmd cat '$project' '$branding-client' '$branding_file'> $tmp/$branding_file || true");
    # 	run("diff -ub '$tmp/$template_file' '$tmp/$branding_file' || true");
    # 	unlink("$tmp/$template_file");
    # 	unlink("$tmp/$branding_file");
    #      }
  }

if (@client_filter and scalar(keys %client_filter))
  {
    print "ERROR: branding not found: unused filter terms: ", Dumper \%client_filter;
    print "\tAvailable candidates: @candidates\n";
    print "Check your spelling!\n";
    exit(1);
  }

if ($skipahead)
  {
    die("leaving around $tmp");
  }
else
  {
    run("sleep 3; rm -rf $tmp");
  }

$obs_api =~ s{api\.opensuse\.org}{build.opensuse.org};	# special case them; with our s2 the names match.
print "Wait an hour or so, then check if things have built.\n";

for my $branding (@candidates)
  {
    my $branding_tar = undef;
    ($branding_tar,$branding) = ($branding,$2) if $branding =~ m{^(.*/)?(.*)(\.tar\..*?)$};
    my $suffix = ":$branding/";
    $suffix = '' if $container_project =~ m{/$};
    print " $obs_api/package/show/$container_project$suffix$branding-client\n";
  }

print "To check for build progress and publish the packages, try (repeatedly) the following command:\n";
print "\n internal/collect_all_oem_clients.pl -f ".join(',',@candidates)." -r $build_token\n";

print "(If $build_token is not part of the version number seen in the client.dsc version number. Try to call collect_all_oem_clients.pl with out -r.\n";
print "If this happens, please investigate, why. Seen in job/publish-oem-client-linux/42/console output.)\n";

exit 0;
#################################################################################

sub run
{
  my ($cmd) = @_;
  print "+ $cmd\n" if $::verbose;
  return if $::no_op;
  system($cmd) and die "failed to run '$cmd': Error $!\n";
}

sub pull_VERSION_cmake
{
  my ($file) = @_;
  my ($maj,$min,$pat,$so) = (0,0,0,0);

  open(my $fd, "<$file") or die "cannot read $file\n";
  while (defined(my $line = <$fd>))
    {
      chomp $line;
      $maj = $1 if $line =~ m{MIRALL_VERSION_MAJOR\s+(\d+)};
      $min = $1 if $line =~ m{MIRALL_VERSION_MINOR\s+(\d+)};
      $pat = $1 if $line =~ m{MIRALL_VERSION_PATCH\s+(\d+)};
      $so  = $1 if $line =~ m{MIRALL_SOVERSION\s+(\d+)};
      $pr  = $1 if $line =~ m{MIRALL_VERSION_SUFFIX\s+\"(\w+)};
    }
  close $fd;
  return ("$maj.$min.$pat", "$pr");
}

# pull a branch from git, place it into destdir, packaged as a tar ball.
# This also double-checks if the version in VERSION.cmake matches the name of the branch.
#
# If passed a tar-file name as second parameter, nothing is pulled from github.
# the tar-file is simply copied to destdir then.
sub fetch_client_from_branch
{
  my ($giturl, $branch, $destdir) = @_;
  
  if ($branch =~ m{\.tar\.})
    {
      die "tar file $branch does not exist.\n" unless -f $branch;
    
      # owncloudclient-1.8.0.tar.xz
      my $prerelease = undef;
      my $version = "v$1" if $branch =~ m{.*-(\d[\.\d]+.*?)\.tar\.};
      # CAUTION: keep regexp identical to below
      ($version,$prerelease) = ($1,$2) if $version =~ m{^v([\d\.]+)[-~]?([abr]\w+)?$}i;
      my $source_tar = $branch; $source_tar =~ s{.*/}{};

      File::Copy::copy($branch, "$destdir/$source_tar");
      return ("$destdir/$source_tar", $version, $prerelease);
    }

  my $gitsubdir = "$destdir/client_git";
  # CAUTION: keep in sync with
  # https://rotor.owncloud.com/view/mirall/job/mirall-source-master/configure

  run("git clone --depth 1 --branch $branch $source_git $gitsubdir")
    unless $skipahead > 1;

  # v1.7.0-alpha1
  # v1.6.2-themefix is a valid branch name.
  # CAUTION: keep regexp identical to above.
  my ($version,$prerelease) = ($1,$2) if $branch =~ m{^v([\d\.]+)[~-]?([abr]\w+)?$}i;
  #a git tag does not necessarily qualify the prerelease name
  #$prerelease =~ s{^-}{} if defined $prerelease;

  my ($v_git, $pr_git) = pull_VERSION_cmake("$gitsubdir/VERSION.cmake");
  $prerelease = $pr_git;

  if (defined $version)
    {
      if ($v_git ne $version)
	{
	  warn "oops: asked for git branch v$version, but got version $v_git\n";
	  $version = $v_git;
	}
      else
	{
	  print "$version == $v_git, yeah!\n";
	}
    }
  else
    {
      $version = $v_git;
      print "branch=$branch contains VERSION.cmake version=$version\n";
    }

  # no - or ~ before prerelease, the specfile template constructs tarversion without 
  # any delimiter between version and prerelease.
  my $pkgname = "client-${version}"; $pkgname .= $prerelease if defined $prerelease;
  $source_tar = "$destdir/$pkgname.tar.bz2";
  run("cd $gitsubdir && git archive HEAD --prefix=$pkgname/ --format tar | bzip2 > $source_tar")
    unless $skipahead > 2;
  return ($source_tar, $version, $prerelease);
}

sub make_dummy_package_cfg
{
   my ($dir) = @_;
   my $cmakefile = "$dir/OEM.cmake";
   my $cfgfile = "$dir/package.cfg";

   my %set;

   open IN, "<$cmakefile" or die "make_dummy_package_cfg: cannot read $cmakefile: $!\n";
   while (defined(my $line = <IN>))
     {
       # set( APPLICATION_NAME "DataBird" )
       chomp $line;
       if ($line =~ m{^set.*?(\w+)\s+"([^"]*)"})
         {
	   $set{$1} = $2;
	 }
     }
   close IN;
   warn Dumper "make_dummy_package_cfg using:", \%set;
   open OUT, ">$cfgfile" or die "make_dummy_package_cfg: cannot write $cfgfile: $!\n";
   print OUT qq{\
       summary => "The $set{APPLICATION_NAME} Client - file sync and share client",
       pkgdescription => "The $set{APPLICATION_NAME} Client provides file sync to desktop clients.",
       pkgdescription_debian => "The $set{APPLICATION_NAME} Client provides file sync to desktop clients.",
       sysconfdir => "etc/$set{APPLICATION_SHORTNAME}",  # etc/ownCloud, but lowercase for all OEMs..., without a leading slash
       maintainer => "ownCloud Inc.",
       maintainer_person => "Juergen Weigert <jw+jenkins\@owncloud.com>",
       desktopdescription => "$set{APPLICATION_NAME} desktop sync client",
};
   close OUT or die "make_dummy_package_cfg: could not write $cfgfile: $!\n";
}


sub obs_user
{
  my ($osc_cmd) = @_;
  open(my $ifd, "$osc_cmd user|") or die "cannot fetch user info: $!\n";
  my $info = join("",<$ifd>);
  chomp $info;
  $info =~ s{:.*}{};
  return $info;
}

sub obs_prj_exists
{
  my ($osc_cmd, $prj) = @_;

  open(my $tfd, "$osc_cmd meta prj '$prj' 2>/dev/null|") or die "cannot check '$prj'\n";
  if (<$tfd>)
    {
      close($tfd);
      return 1;
    }
  return 0;
}

# KEEP IN SYNC with obs_pkg_from_template
sub obs_prj_from_template
{
  my ($osc_cmd, $template_prj, $prj, $title) = @_;

  $prj =~ s{/$}{};
  $template_prj =~ s{/$}{};

  if (obs_prj_exists($osc_cmd, $prj))
    {
      print "Project '$prj' already there.\n";
      return;
    }

  open(my $ifd, "$osc_cmd meta prj '$template_prj'|") or die "cannot fetch meta prj $template_prj: $!\n";
  my $meta_prj_template = join("",<$ifd>);
  close($ifd);
  my $user = obs_user($osc_cmd);

  # fill in the template with our data:
  $meta_prj_template =~ s{<project\s+name="\Q$template_prj\E">}{<project name="$prj">}s;
  $meta_prj_template =~ s{<title>.*?</title>}{<title/>}s;	# make empty, if any.
  # now we always have the empty tag, to fill in.
  $meta_prj_template =~ s{<title/>}{<title>$title</title>}s;
  # add myself as maintainer:
  $meta_prj_template =~ s{(\s*<person\s)}{$1userid="$user" role="maintainer"/>$1}s;

  open(my $ofd, "|$osc_cmd meta prj '$prj' -F - >/dev/null") or die "cannot create project: $!\n";
  print $ofd $meta_prj_template;
  close($ofd) or die "writing prj meta failed: $!\n";
  print "Project '$prj' created.\n";
}

# almost a duplicate from above.
# KEEP IN SYNC with obs_prj_from_template
sub obs_pkg_from_template
{
  my ($osc_cmd, $template_prj, $template_pkg, $prj, $pkg, $title) = @_;

  $prj =~ s{/$}{};
  $template_prj =~ s{/$}{};

  # test, if it is already there, if so, do nothing:
  open(my $tfd, "$osc_cmd meta pkg '$prj' '$pkg' 2>/dev/null|") or die "cannot check '$prj/$pkg'\n";
  if (<$tfd>)
    {
      close($tfd);
      print "Package '$prj/$pkg' already there.\n";
      return;
    }

  open(my $ifd, "$osc_cmd meta pkg '$template_prj' '$template_pkg'|") or die "cannot fetch meta pkg $template_prj/$template_pkg: $!\n";
  my $meta_pkg_template = join("",<$ifd>);
  close($ifd);

  # fill in the template with our data:
  $meta_pkg_template =~ s{<package\s+name="\Q$template_pkg\E" project="\Q$template_prj\E">}{<package name="$pkg" project="$prj">}s;
  $meta_pkg_template =~ s{<title>.*?</title>}{<title/>}s;	# make empty, if any.
  # now we always have the empty tag, to fill in.
  $meta_pkg_template =~ s{<title/>}{<title>$title</title>}s;

  open(my $ofd, "|$osc_cmd meta pkg '$prj' '$pkg' -F - >/dev/null") or die "cannot create package: $!\n";
  print $ofd $meta_pkg_template;
  close($ofd);
  print "Package '$prj/$pkg' created.\n";
}

