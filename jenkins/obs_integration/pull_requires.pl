#! /usr/bin/perl -w
#
# pull_requires.pl -- edit a specfile, to update all the requires.
# Used to create/update the test_installation package at # $repo.
#
# Maintained at github.com/owncloud/administration/jenkins/obs_integration/pull_requires.pl
#
# 2014-08-25, jw@owncloud.com
#            - initial draught, bits and pieces.

use Data::Dumper;
use LWP;
use LWP::UserAgent;
use Compress::Zlib;
use XML::Simple;

my $verbose = 1;

my $version = '0.3';

my $name_filter = qr{^(owncloud|owncloud\-client)$};
my $repo = 'http://download.opensuse.org/repositories/isv:/ownCloud:/community:/testing/';
my %platforms = (
  rpm => {
  'openSUSE_Factory' 	=> '0%{?suse_version} > 1310',
  'openSUSE_12.2' 	=> '0%{?suse_version} == 1220',
  'openSUSE_12.3' 	=> '0%{?suse_version} == 1230',
  'openSUSE_13.1' 	=> '0%{?suse_version} == 1310',
  'CentOS_CentOS-5'	=> '0%{?centos_version} == 5',
  'CentOS_CentOS-6'	=> '0%{?centos_version} == 6',
  'CentOS_CentOS-7'	=> '0%{?centos_version} == 7',
  'RedHat_RHEL-7'	=> '0%{?rhel_version} == 7',
  'RedHat_RHEL-6'	=> '0%{?rhel_version} == 6',
  'SLE_11_SP3'		=> '0%{?suse_version} == 1110',
  'SLE_11_SP2'		=> '0%{?suse_version} == 1110',
  'Fedora_18'		=> '0%{?fedora_version} == 18',
  'Fedora_19'		=> '0%{?fedora_version} == 19',
  'Fedora_20'		=> '0%{?fedora_version} == 20',
  },
  deb => {
  'xUbuntu_12.04'	=> undef,
  'xUbuntu_12.10'	=> undef,
  'xUbuntu_13.04'	=> undef,
  'xUbuntu_13.10'	=> undef,
  'xUbuntu_14.04'	=> undef,
  'xUbuntu_14.10'	=> undef,
  'Debian_6.0'		=> undef,
  'Debian_7.0'		=> undef,
  },
);

my $specfile = 'installation-test.spec';

my @spec_parts = read_spec_parts($specfile);
$spec_parts[1] = '';
my $base = parse_apache_dir($repo);
for my $dir (@{$base->{dirs}})
  {
    unless (exists($platforms{rpm}{$dir}) or
            exists($platforms{deb}{$dir}))
      {
        warn "$dir ignored.\t Please add it to $0:\%platforms\n";
	next;
      }
    my $format = ($platforms{rpm}{$dir}) ? 'rpm' : 'deb';
    
    my $url = "$repo/$dir";
    my $repodata = parse_apache_dir("$repo/$dir/repodata");
    my $req = { error => 'never' };
    if ($repodata->{files})
      {
        my @primary = grep { /\-primary\.xml/ } @{$repodata->{files}};
	$req = parse_requires_primary_xml("$repo/$dir/repodata/$primary[0]") if @primary;
      }

    $req = parse_requires_packages("$repo/$dir/Packages.gz") if $req->{error};
    $req = parse_requires_packages("$repo/$dir/Packages")    if $req->{error};

    $spec_parts[1] .= extract_spec($req, $dir, $name_filter) if $format eq 'rpm';
    # print Dumper $dir, $format, $req;
  }

open OUT, ">", $specfile or die "cannot write $specfile: $!\n";
print OUT $spec_parts[0];
print OUT $spec_parts[1];
print OUT $spec_parts[2];
close OUT or die "couldnot write $specfile: $!\n";
warn "deb part not impl.\n";

exit 0;
#####################################################

sub map_rpm_requires
{
  my ($name, $platform, $arch) = @_;
  
  my $mapping = 
    {
      '/usr/bin/php'	=> 'php5',	# what???
      '/bin/sh'		=> 'bash',	# what???
      'mysql'		=> 'mariadb'	# have choice: community-mysql mariadb
    };
  return $mapping->{$name} if $mapping->{$name};
  return $name;
}

sub extract_spec
{
  my ($req, $platform, $name_filter) = @_;
  my $cond = $platforms{rpm}{$platform};

  my $text = '';
  return $text unless $req->{pkg};
  $text .= "\%if $cond\n" if $cond;
  for my $pkg (@{$req->{pkg}})
    {
      next if $name_filter and $pkg->{name} !~ m{$name_filter};
      $text .= "\%ifarch $pkg->{arch}\n" if $pkg->{arch} and $pkg->{arch} ne 'noarch';
      my $vers = $1 if $pkg->{vers} =~ m{^([^-]+)};
      $text .= "BuildRequires: $pkg->{name} == $vers\n";
      for my $req (@{$pkg->{requ}})
        {
          my $mapped = map_rpm_requires($req, $platform, $pkg->{arch});
          $text .= "BuildRequires: $mapped\n";
	}
      $text .= "\%endif\n" if $pkg->{arch} and $pkg->{arch} ne 'noarch';
    }
  $text .= "\%endif\n" if $cond;
  return $text;
}

sub get_http_dec
{
  my ($url) = @_;
  my $ua = LWP::UserAgent->new;
  my $can_accept = HTTP::Message::decodable;
  $ua->agent("$0/$version ", 'Accept-Encoding' => $can_accept);
  print "+ $url\n" if $verbose;
  $response = $ua->request(HTTP::Request->new(GET => $url));
  if (!$response->is_success) 
    {
      return { error => $response->status_line };
    }
  my $text = $response->decoded_content;
  return { text => Compress::Zlib::memGunzip($text) || $text }; # do gunzip, if needed.
}

# returns [{ name => $name, vers => $vers, arch => $arch, depe,reco,sugg => [symbols, ...] }, ...]
sub parse_requires_packages
{
  my ($url) = @_;
  my $get = get_http_dec($url);
  return $get unless $get->{text};
  my $text = $get->{text};
  my @pkg;
  while ($text =~ m{^(\S+):\s*(.*)$}mg)
    {
      my ($tag, $val) = ($1,$2);
      if ($tag eq 'Package')
        {
	  push @pkg, { name => $val };
	}
      else
        {
	  my $tag4 = substr(lc $tag, 0, 4);
	  $pkg[-1]{$tag4} = $val if $tag =~ m{^(version|architecture|depends|recommends|suggests)$}i;
	}
    }
  return { pkg => \@pkg };
}

# returns [{ name => $name, vers => $vers, arch => $arch, requ => [symbols,...] }, ...]
sub parse_requires_primary_xml
{
  my ($url) = @_;
  my $get = get_http_dec($url);
  return $get unless $get->{text};
  my $obj = XML::Simple::XMLin($get->{text}, ForceArray => 1);

  my $list;
  for my $p (@{$obj->{package}})
    {
      my $name = $p->{name}[0];
      my $arch = $p->{arch}[0];
      my $vers = $p->{version}[0]{ver} . '-' . $p->{version}[0]{rel};
      next if $arch eq 'src';

      my $req = $p->{format}[0]{'rpm:requires'};
      $req = $req->[0] if ref $req eq 'ARRAY';
      $req = $req->{'rpm:entry'} if $req->{'rpm:entry'};
      $req = [ keys %$req ] if ref $req eq 'HASH';
      # warn Dumper $name, $vers, $arch, $req;
      push @$list, { name => $name, vers => $vers, arch => $arch, requ => $req };
    }
  return { pkg => $list };
}

sub parse_apache_dir
{
  my ($url, $ign) = @_;
  $ign ||= qr{\.mirrorlist$};

  my @files = ();
  my @dirs = ();
  # <img src="/icons/folder.png" alt="[DIR]" /> <a href="openSUSE_13.1/">openSUSE_13.1/</a>    
  # <img src="/icons/folder.png" alt="[DIR]" /> <a href="openSUSE_Factory/">openSUSE_Factory/</a> 

  my $get = get_http_dec($url);
  return $get unless $get->{text};
  my $text = $get->{text};

  while ($text =~ m{<a\s+href=['"]([^\?/'">]+/?)['"]>}g)
    {
      my $file = $1;
      next if defined $ign and $file =~ m{$ign};

      if ($file =~ s{/$}{})
        {
	  push @dirs, $file;
        }
      else
        {
	  push @files, $file;
        }
    }
  return { files => \@files, dirs => \@dirs };
}

sub read_spec_parts
{
  my ($specfile) = @_;
  
  my @part = ('','','');
  my $requires_seen = 0;
  open(IN, "<", $specfile) or die "cannto read $specfile: $!\n";
  while (defined (my $line = <IN>))
    {
      $requires_seen++ if $line =~ m{REQUIRES_END};
      $part[$requires_seen] .= $line;
      $requires_seen++ if $line =~ m{REQUIRES_START};
    }
  return @part;
}

