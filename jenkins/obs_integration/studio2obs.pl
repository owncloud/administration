#! /usr/bin/perl -w
#
# studio2obs.pl -- converts an export from susestudio.com into a package for the open build service
#
# 2014-08-19, 0.1 jw@owncloud.com
#		-- initial draught
#               -- see also  ~/HOWTO/owncloud-appliance.tct
# 2014-08-19, 0.2 jw@owncloud.com
#               -- repo2proj() %package_replace functional.
# 2014-08-21, 0.3 jw@owncloud.com
#		-- created by comment added to kiwi file.
#		-- symlinks must be relative inside of root.tar.gz

use File::Find;
use Data::Dumper;
my $version = '0.3';
my $verbose = 1;


my $self_cmd = "$0 @ARGV # (V$version)";

my $studio_tar = shift;
my $default_api_url = 'https://api.opensuse.org';
my %package_replace = 
(
  'module-init-tools' => 
  q{<package name='module-init-tools'/>
    <!-- Problem: nothing provides /usr/bin/eu-nm needed by module-init-tools -->
    <package name='elfutils'/>
    <!-- Problem: nothing provides /usr/bin/sg_inq needed by udev-208-23.3.x86_64 -->
    <package name='sg3_utils'/>
    <!-- have choice for sbin_init needed by mkinitrd: systemd-sysvinit systemd-mini-sysvinit -->
    <!-- avoid using systemd-mini (seen in openSUSE:Factory:ARM/JeOS-beagle) -->
    <package name="systemd-sysvinit"/>
    <package name='systemd-presets-branding-basedonopensuse'/>
    },

  'patterns-openSUSE-base' => 
  q{<package name='patterns-openSUSE-base'/>
    <!-- have choice for product_flavor(openSUSE) needed by openSUSE-release: ... -->
    <package name="openSUSE-release-mini"/>
    <package name="ncurses-utils"/><!-- provides /usr/bin/tput needed by aaa_base -->
    <package name="pkg-config"/><!-- provides /usr/bin/pkg-config needed by shared-mime-info -->
    <package name="yast2-installation"/>
    },

  'yast2' => 
  q{<package name='yast2'/>
    <!-- have choice for libyui_pkg needed by yast2-packager: libyui-ncurses-pkg5 libyui-qt-pkg5 libyui-gtk-pkg5 -->
    <package name="libyui-ncurses-pkg5"/>
    },

  'plymouth' => 
  q{<package name='plymouth'/>
    <!-- have choice for plymouth-branding needed by plymouth: plymouth-branding-basedonopensuse plymouth-branding-openSUSE, -->
    <package name='plymouth-branding-basedonopensuse'/>
    },

  'owncloud' => 
  q{<package name='owncloud'/>
    <package name='apache2'/>
    },

);

unless (-f $studio_tar)
  {
    die qq{studio2obs.pl Version $version

Usage: 
       $0 ~/Download/*-kiwi_src.tar.gz [PACK_NAME]
       env PROJ_PREFIX=openSUSE.org $0 ...
       osc vc
       osc ci

When inside a checkout of a build service project or package directory, the following 
additional actions are taken:
 If in a project directory, specify a PACK_NAME, and an implicit
 'osc mkpac PACK_NAME; cd PACK_NAME' is done.
 If in a package directory, the PACK_NAME is taken from the current directory.
 PROJ_PREFIX defaults to '', if .osc/_apiurl refers to api.opensuse.org;
 PROJ_PREFIX defaults to 'openSUSE.org' otherwise.

PACK_NAME is mandatory, when outside of a checkout directory.
};
  }

sub run
{
  my ($cmd) = @_;
  print "+ $cmd\n" if $verbose;
  system($cmd) and die "$cmd failed: $@ $!\n";
}

my $api_url;
my $pkg_name= shift;
my $osc_pkg_name;
my $outdir='.';

if (open IN, "<", ".osc/_apiurl")
  {
    $api_url = <IN>; chomp $api_url; close IN;

    if (open IN, "<", ".osc/_package")
      {
        $osc_pkg_name = <IN>; chomp $osc_pkg_name;
        die "both, .osc/_package (='$pkg_name') present, and PACK_NAME=$osc_pkg_name specified.\n" 
	  if $osc_pkg_name and $osc_pkg_name ne $pkg_name;
	$pkg_name = $osc_pkg_name;
      }
    else 
      {
        run("osc mkpac '$pkg_name' || true") if defined $pkg_name;
        $outdir = $pkg_name;
      }
  }

die "Error: no PACK_NAME specified and not inside a package directory\n" unless defined $pkg_name;
unless (-d ".osc")
  {
    mkdir $pkg_name unless -d $pkg_name;
    $outdir = $pkg_name;
  }

# die Dumper "studio_tar=$studio_tar api_url=$api_url prj_name=$prj_name pkg_name=$pkg_name\n";
# die Dumper "outdir=$outdir\n";

my $start_in_prj = -f ".osc/_project";
my $start_in_pkg = -f ".osc/_package";

chdir($outdir); $outdir='.';

$tmpdir .= "./_studio2obs_$$";
mkdir($tmpdir) or die "mkdir $tmpdir failed: $!\n";

run("tar zxf '$studio_tar' -C $tmpdir");
run("mv $tmpdir/*/source/* '$outdir/'");
run("rm -rf '$tmpdir'");

if (-d "root")
  {
    # make all symlinks relative
    File::Find::find({ wanted => sub {
      return unless -l $File::Find::name;
      my $target = readlink($File::Find::name);
      my $dir = $File::Find::dir;
      return unless $target =~ m{/};	# we only take care of absolute links.

      # root/passwd2 -> /etc/passwd
      #   -> etc/passwd
      # root/etc/systemd/sys/m/firstboot.service -> /etc/systemd/sys/suse-studio-firstboot.service
      #   -> ../../../../etc/systemd/sys/suse-studio-firstboot.service

      $dir =~ s{^root/}{}g;	# inside root, 
      $dir =~ s{[^/]+}{..}g;	# crawl upwads.
      # not normalized, but hey, it works ...
      # print "symlink in root: $_ -> $dir$target\n";

      unlink($File::Find::name);
      symlink("$dir$target", $File::Find::name);

    }, no_chdir => 1, follow => 0 }, 'root');

    # compress in a tar ball, without any parent directories, not even 'root/...'
    run("tar zcf root.tar.gz -C root .");
    run("rm -rf root");
  }

my $kiwifile = "$pkg_name.kiwi";
rename("config.xml", $kiwifile) if -f "config.xml";
kiwi_studio2obs($kiwifile, $api_url) if -f $kiwifile;
prependChangeLog("$pkg_name.changes", "generated by: $self_cmd");

run("osc add * || true") if $start_in_prj;
run("ls -la .");

if ($verbose)
{
  print "Now you can try this:\n\n";
  print " cd $pkg_name; \n" unless $start_in_pkg;
  print qq{ osc build *.kiwi images
 osc ci

If the build fails to delete a proc directory, try:
 sudo mv /var/tmp/build-root/images-x86_64{,.$RANDOM}
};
}

exit(0);
# ------------------------------------------------------

sub repo2proj
{
  my ($repo,$pre) = @_;
  $pre||='';
  $pre = $pre . ':' if length $pre and not $pre =~ m{:$};

  # The structure of the download mirrors is notoriously irregular. 
  # If there is library code to do the mapping, use it here too.

  ####
  # http://download.opensuse.org/update/13.1/
  # http://download.opensuse.org/distribution/13.1/repo/oss/
  # http://download.opensuse.org/repositories/server:php:extensions/openSUSE_13.1/
  ####
  return "obs://${pre}openSUSE:$1:Update/standard" if $repo =~ m{^https?://download\.opensuse\.org/update/(\d+\.\d)/?$}i;
  return "obs://${pre}openSUSE:$1/standard"        if $repo =~ m{^https?://download\.opensuse\.org/distribution/(\d+\.\d)/repo/oss/?$}i;
  return "obs://${pre}$1/$2"                       if $repo =~ m{^https?://download\.opensuse\.org/repositories/([^/]+)/(.*?)/?$};

  warn "repo2proj($repo) NO MATCH -- Please edit the *.kiwi file yourself\n";
  sleep(3);
  return "obs://${pre}... REPO2PROJ($repo) NO MATCH";
}

sub read_osc_whois
{
  open IN, "osc whois|";
  my $line = <IN> || '';
  close IN;
  # jnweiger: "Juergen Weigert" <jnweiger@gmail.com>
  my $login    = $1 if $line =~ m{^(.*):};
  my $fullname = $1 if $line =~ m{"(.*)"};
  my $email    = $1 if $line =~ m{<(.*)>};

  unless (defined $email)
    {
      open IN, "<", "$ENV{HOME}/.oscrc";
      while (defined (my $line = <IN>))
        {
	  # email = jw@owncloud.com
	  $email = $1 if $line =~ m{^email\s*=\s*(.*)};
	}
    }
  return ($login||'', $fullname||'', $email||'');
}

sub kiwi_studio2obs
{
  my ($kiwifile, $api_url) = @_;
  $api_url = $api_url || $ENV{API_URL} || $default_api_url;
  my $prj_pre = (lc($api_url) eq lc($default_api_url)) ? '' : 'openSUSE.org';
  $prj_pre = $ENV{PROJ_PREFIX} if defined $ENV{PROJ_PREFIX};

  open IN, "<", $kiwifile or die "cannot read $kiwifile: $!\n";
  my $kiwi = join("", <IN>);
  close IN;

  ## name ourselves
  $kiwi =~ s{(<author)}{"<!-- converted by: $self_cmd, " . scalar(localtime) ." -->\n    $1"}e;

  ## refernce myself
  my ($user,$author,$contact) = read_osc_whois();
  print "author=$author contact=$contact\n";
  # <author>JuergenWeigert</author>
  $kiwi =~ s{(<author>).*?(</author>)}{$1$author$2} if $author;
  # <contact>studio-devel@suse.de</contact>
  $kiwi =~ s{(<contact>).*?(</contact>)}{$1$contact$2} if $contact;

  ## postprocess repositories

  # <repository type='yast2'>
  $kiwi =~ s{<(repository\s+type)=['"].*?['"]\s*>}{<$1='rpm-md'>}mg;
  # <source path='http://download.opensuse.org/repositories/server:php:extensions/openSUSE_13.1/'/>
  $kiwi =~ s{<(source\s+path)=["'](.*?)['"]\s*/>}{"<$1='".repo2proj($2,$prj_pre)."'/>"}mge;

  $kiwi =~ s{<opensusePattern\s+name=['"]([^'"]+)['"]\s*/>}{<package name="patterns-openSUSE-$1"/>}mg;

  ## postprocess packages
  for my $pkg (keys %package_replace)
    {
      $kiwi =~ s{<(package\s+name)=['"]\Q$pkg\E['"]\s*/>}{$package_replace{$pkg}}mge;
    }

  ## yippie.

  open OUT, ">", $kiwifile or die "cannot write $kiwifile: $!\n";
  print OUT $kiwi;
  close OUT or die "could not write $kiwifile: $!\n";
}

sub prependChangeLog
{
  my ($filename, $message) = @_;
  open IN, "<", $filename;
  my $text = join('', <IN>);
  close IN;
  $text ||='';

  my ($user,$name,$email) = read_osc_whois();
  $email ||= ($ENV{logname}||'user') . "@localhost";

  $text = qq{-------------------------------------------------------------------
}. scalar(localtime) . qq{ - $email

- $message

} . $text;
  open OUT, ">", $filename or die "cannot write $filename: $!\n";
  print OUT $text;
  close OUT or die "could not write $filename: $!\n";
}
