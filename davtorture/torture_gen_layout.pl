#!/usr/bin/env perl
use strict;
use Data::Random::WordList;

############################################################################

# Which extensions to randomly assign
my @exts = ('txt', 'pdf', 'html', 'docx', 'xlsx', 'pptx', 'odt', 'ods', 'odp');
# Maximum depth of the target structure
my $maxdepth = 6;
# Maximum amount of subfolders within a folder
my $max_subfolders = 6;
# Maximum amount of files within a folder
my $max_files_per_folder = 5;
# Maximum file size 
my $max_file_size = 1024**2;

############################################################################

my $wl; # keep the wordlist global.
my $overall_size;

sub open_wordlist
{
  my @wordlists = ('/usr/share/dict/words', '/usr/share/dict/american');

  my $wordlist;

  foreach my $wl (@wordlists) {
    if( -e $wl ) {
      $wordlist = $wl;
      last;
    }
  }

  die("Can not find a valid wordlist.") unless( -e $wordlist );
  print "Use wordlist: $wordlist\n";

  $wl = new Data::Random::WordList( wordlist => $wordlist );
}

sub gen_entries($)
{
  my ($count) = @_;

  my @rand_words = $wl->get_words($count);
  foreach(@rand_words) {
    $_ =~ s/\'//g;
  }

  return @rand_words;
}

sub create_subdir($)
{
  my ($depth) = @_;
  $depth--;
  my %dir_tree = ();

  my $dirCnt = $max_subfolders;
  $dirCnt = rand($max_subfolders) if( $depth < $max_subfolders-1 );

  my @dirs = gen_entries(int($dirCnt));
  my @files = gen_entries(int(rand($max_files_per_folder)));

  foreach my $file(@files) {
    $dir_tree{$file} = int(rand($max_file_size));
    $overall_size += $dir_tree{$file};
  }

  if ($depth > 0) {
    foreach my $dir(@dirs) {
      $dir_tree{$dir} = create_subdir($depth);
    }
  }

  return \%dir_tree;
}

sub create_dir_listing(@)
{
  my ($tree, $prefix) = @_;
  foreach my $key(keys %$tree) {
     my $entry = $tree->{$key};
     #print "$entry:".scalar $entry.":".ref $entry."\n";
     if (ref $entry eq "HASH") {
       create_dir_listing($tree->{$key}, "$prefix/$key");
     } else {
       my $ext = @exts[rand @exts];
       print "$prefix/$key.$ext:$entry\n";
     }
  }
}

srand();
open_wordlist();

$overall_size = 0;

my $dir = create_subdir($maxdepth);
create_dir_listing($dir, '.');

printf STDERR "\nOverall size: %-2f MiB\n", $overall_size/1024/1024;
$wl->close();
