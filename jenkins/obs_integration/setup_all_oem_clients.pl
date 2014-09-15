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
#

use Data::Dumper;
use File::Path;
use File::Temp ();	# tempdir()
use POSIX;		# strftime()
use Cwd ();

# used only by genbranding.pl -- but better crash here if missing:
use Config::IniFiles;	# Requires: perl-Config-IniFiles
use Template;		# Requires: perl-Template-Toolkit


my $build_token         = 'jw_'.strftime("%Y%m%d", localtime);
my $source_tar          = shift;

if (!defined $source_tar or $source_tar =~ m{^-})
  {
    die qq{
Usage: $0 v1.6.2 [home:jw:oem [filterbranding,... [api [tmpl]]]]

       $0 v1.7.0-alpha1 isv:ownCloud:oem testpilotcloud https://api.opensuse.org isv:ownCloud:community:nightly
       
... or similar
};
  }

my $container_project   = shift || 'oem';	#'home:jw:oem';

my $client_filter	= shift || "";
my @client_filter	= split(/[,\|\s]/, $client_filter);
my %client_filter = map { $_ => 1 } @client_filter;

my $obs_api             = shift || 'https://s2.owncloud.com';
my $template_prj 	= shift || 'desktop';
my $template_pkg 	= shift || 'owncloud-client';
my $create_msg 		= $ENV{OBS_INTEGRATION_MSG} || "created by: $0 @ARGV; template=$template_prj/$template_pkg";


my $customer_themes_git = 'git@github.com:owncloud/customer-themes.git';
my $source_git          = 'https://github.com/owncloud/mirall.git';
my $osc_cmd             = "osc -A$obs_api";
my $genbranding         = "./genbranding.pl -c '-A$obs_api' -p '$container_project' -r '$build_token' -o -f";
if ($ENV{'OSC_CMD'})
  {
    $osc_cmd = "$ENV{'OSC_CMD'} -A$obs_api";
    $osc_param = $ENV{'OSC_CMD'};
    $osc_param =~ s{^\S+\s+}{};	# cut away $0
    $genbranding        = "./genbranding.pl -c '$osc_param -A$obs_api' -p '$container_project' -r '$build_token' -o -f";
  }

print "osc_cmd='$osc_cmd';\ngenbranding='$genbranding';\n";

my $TMPDIR_TEMPL = '_oem_XXXXX';
our $verbose = 1;
our $no_op = 0;
my $skipahead = 0;	# 5 start with all tarballs there.

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
    }
  close $fd;
  return "$maj.$min.$pat";
}

# pull a branch from git, place it into destdir, packaged as a tar ball.
# This also double-checks if the version in VERSION.cmake matches the name of the branch.
sub fetch_mirall_from_branch
{
  my ($giturl, $branch, $destdir) = @_;

  my $gitsubdir = "$destdir/mirall_git";
  # CAUTION: keep in sync with
  # https://rotor.owncloud.com/view/mirall/job/mirall-source-master/configure

  run("git clone --depth 1 --branch $branch $source_git $gitsubdir")
    unless $skipahead > 1;

  # v1.7.0-alpha1
  # v1.6.2-themefix is a valid branch name.
  my ($version,$prerelease) = ($1,$2) if $branch =~ m{^v([\d\.]+)([abr-]\w+)?$}i;
  $prerelease =~ s{^-}{} if defined $prerelease;
  $genbranding .= " -P '$prerelease'" if defined $prerelease;

  my $v_git = pull_VERSION_cmake("$gitsubdir/VERSION.cmake");
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

  my $pkgname = "mirall-${version}";
  $source_tar = "$destdir/$pkgname.tar.bz2";
  run("cd $gitsubdir && git archive HEAD --prefix=$pkgname/ --format tar | bzip2 > $source_tar")
    unless $skipahead > 2;
  return ($source_tar, $version, $prerelease);
}


print "source_tar=$source_tar\n";
my $version = undef;
my $prerelease = undef;
($source_tar,$version,$prerelease) = fetch_mirall_from_branch($source_git, $source_tar, $tmp) 
  if $source_tar =~ m{^v[\d\.]+};
$source_tar = Cwd::abs_path($source_tar);	# we'll chdir() around. Take care.
print "source_tar=$source_tar\n";
print "prerelease=$prerelease\n" if defined $prerelease;
sleep 5;

die "need a source_tar path name or version number matching /^v[\\d\\.]+/\n" unless defined $source_tar and -e $source_tar;

run("git clone --depth 1 $customer_themes_git $tmp_t") 
  unless $skipahead > 3;

opendir(DIR, $tmp_t) or die("cannot opendir my own $tmp: $!");
my @d = grep { ! /^\./ } readdir(DIR);
closedir(DIR);

my @candidates = ();
for my $dir (sort @d)
  {
    next unless -d "$tmp_t/$dir/mirall";
    next if @client_filter and not $client_filter{$dir};
    #  - generate the branding tar ball
    # CAUTION: keep in sync with jenkins jobs customer_themes
    # https://rotor.owncloud.com/view/mirall/job/customer-themes/configure
    chdir($tmp_t);
    run("tar cjf ../$dir.tar.bz2 ./$dir")
      unless $skipahead > 4;
    push @candidates, $dir if -f "$tmp_t/$dir/mirall/package.cfg";
  }

print Dumper \@candidates;

sub obs_user
{
  my ($osc_cmd) = @_;
  open(my $ifd, "$osc_cmd user|") or die "cannot fetch user info: $!\n";
  my $info = join("",<$ifd>);
  chomp $info;
  $info =~ s{:.*}{};
  return $info;
}

# KEEP IN SYNC with obs_pkg_from_template
sub obs_prj_from_template
{
  my ($osc_cmd, $template_prj, $prj, $title) = @_;

  # test, if it is already there, if so, do nothing:
  open(my $tfd, "$osc_cmd meta prj '$prj' 2>/dev/null|") or die "cannot check '$prj'\n";
  if (<$tfd>)
    {
      close($tfd);
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


## make sure the top project is there in obs
obs_prj_from_template($osc_cmd, $template_prj, $container_project, "OwnCloud Desktop Client OEM Container project");
chdir($scriptdir) if defined $scriptdir;

for my $branding (@candidates)
  {
    if (@client_filter)
      {
        unless ($client_filter{$branding})
	  {
	    print "Branding $branding skipped: not in client_filter\n";
	    next;
	  }
	delete $client_filter{$branding};
      }

    ## generate the individual container projects
    obs_prj_from_template($osc_cmd, $template_prj, "$container_project:$branding", "OwnCloud Desktop Client project $branding");

    ## create an empty package, so that genbranding is happy.
    obs_pkg_from_template($osc_cmd, $template_prj, $template_pkg, "$container_project:$branding", "$branding-client", "$branding Desktop Client");

    # checkout branding-client, update, checkin.
    run("rm -rf '$container_project:$branding'");
    run("$osc_cmd checkout '$container_project:$branding' '$branding-client'");
    # we run in |cat, so that git diff not open less with the (useless) changes 
    run("env PAGER=cat OBS_INTEGRATION_MSG='$create_msg' $genbranding '$source_tar' '$tmp/$branding.tar.bz2'");	
    # FIXME: abort, if this fails. Pipe cat prevents error diagnostics here. Maybe PAGER=cat helps?

    run("rm -rf '$container_project:$branding'");

    ## fill in all the support packages.
    ## CAUTION: trailing colon is important!
    run("./setup_oem_client.pl '$branding' '$container_project:' '$obs_api' '$template_prj'");

    ## babble out the diffs. Just for the logfile.
    ## This helps catching outdated *.in files in templates/client/* -- 
    ## genbranding uses them. Mabye it should use files from the template package as template?
    for my $f ('%s-client.spec', '%s-client.dsc', 'debian.control', '%s-client.desktop')
      {
        my $template_file = sprintf "$f", 'owncloud';
        my $branding_file = sprintf "$f", $branding;
	run("$osc_cmd cat $template_prj $template_pkg $template_file > $tmp/$template_file || true");
	run("$osc_cmd cat '$container_project:$branding' '$branding-client' '$branding_file'> $tmp/$branding_file || true");
	run("diff -ub '$tmp/$template_file' '$tmp/$branding_file' || true");
	unlink("$tmp/$template_file");
	unlink("$tmp/$branding_file");
      }
  }

if (@client_filter and scalar(keys %client_filter))
  {
    print "unused filter terms: ", Dumper \%client_filter;
    print "check your spelling!\n";
    sleep 10;
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
print "You can use collect_all_oem_clients.pl to push the build results to download.owncloud.com\n";
for my $branding (@candidates)
  {
    print " $obs_api/package/show/$container_project:$branding/$branding-client\n";
  }
