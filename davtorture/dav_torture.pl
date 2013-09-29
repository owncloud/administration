#!/usr/bin/perl
#
# Test script for the ownCloud module of csync.
# This script requires a running ownCloud instance accessible via HTTP.
# It does quite some fancy tests and asserts the results.
#
# Copyright (C) by Klaas Freitag <freitag@owncloud.com>, ownCloud GmbH
#

use lib ".";

use Carp::Assert;
use File::Copy;
use ownCloud::Test;
use File::Path qw(make_path);
use File::Basename qw(dirname);
use Time::Piece;

use Time::HiRes qw( time );

use strict;

print "Hello, this is torture for the ownCloud WebDAV server.\n";

my %seen_dirs;

my $resultFile = "./results.dat";
my $tsv_file = "./puts.tsv";

sub tortureCreateRemoteDir($)
{
  my ($dir) = @_;
  
  my $prev_part = ".";
  $dir =~ s|^\./||;
  my @dir_parts = split(/\//, $dir);
  
  if( scalar @dir_parts == 1 ) {
    # its just a file.
    return;
  }
  
  foreach my $part ( @dir_parts ) {
      $part = $prev_part . "/" .$part;
      unless( $seen_dirs{$part} ) {
        createRemoteDir($part);
        $seen_dirs{$part} = 1;
      }
      $prev_part = $part;
  }
}

initTesting();

if (scalar @ARGV < 2) {
  print "Usage: $0 input.lay <offsetdir>\n";
  exit;
}

my ($lay_file, $offset_dir) = @ARGV;

open FILE, "<", $lay_file or die $!;

$offset_dir .= "/" unless( $offset_dir =~ /\/$/ );

print "Working on filetree at $offset_dir\n";
my $lastdir = "";

my $overall_start = time();
my $overall_transmitted = 0;
my $overall_cnt = 0;

while (<FILE>) {
  my ($file, $size) = split(/:/, $_);
  
  $file =~ s/^\.\///;
  my $fullfile = $offset_dir . $file;
  my $dir = dirname $file;
  if( $dir ne "." && $dir ne $lastdir ) {
    print "Creating missing dir $dir\n";
    tortureCreateRemoteDir($dir);
    $lastdir = $dir;
  }
  
  my $start = time();
  putToDirLWP($fullfile, $dir);
  my $end = time();
  $overall_cnt++;
  my $duration = 1000*1000*($end-$start);
  printf("[PUT] File: %-70s: %d %d µsec. = %d kByte/sec.\n", $file, $size, $duration, $size/1024*1/($end-$start)); 
  $overall_transmitted += $size;
}

my $overall_end = time();
my $overall_time = ($overall_end-$overall_start);
my $avg_rate = $overall_transmitted / 1024 * 1/$overall_time;

my $result = sprintf "[OVERALL PUT] %.2f MByte in %d files to %s in %.2f sec. = %.2f kB/sec.\n", $overall_transmitted/1024/1024, $overall_cnt, 
       server(), $overall_time, $avg_rate;

my $t = localtime();
my $tstr = $t->ymd . " " . $t->hms;

print "\n$result\n";

if( open FILE, ">>$resultFile" ) {
  print FILE "$tstr $result";
}
close FILE;


if( open FILE, ">>$tsv_file" ) {
  $result = sprintf("%s\t%d\t%.2f\t%d\t%.3f\n", $tstr, $avg_rate, $overall_transmitted/1024, $overall_cnt, $overall_time);
  print FILE "$result";
}
close FILE;


