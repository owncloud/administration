#!/usr/bin/php
<?php

/**
 * trivial benchmarking tool to check if a change in an php application has a performance impact
 *
 * @author Frank Karlitschek
 * @copyright 2006 Frank Karlitschek frank@owncloud.org
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU AFFERO GENERAL PUBLIC LICENSE
 * License as published by the Free Software Foundation; either
 * version 3 of the License, or any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU AFFERO GENERAL PUBLIC LICENSE for more details.
 *
 * You should have received a copy of the GNU Affero General Public
 * License along with this library.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

echo("\nBenchmark v1.0 2006 Frank Karlitschek\n\n");

$count=$argv[1];
$url1=$argv[2];
$url2=$argv[3];

if(!isset($argv[3])) {
  echo("Trivial tool to compare the speed of two urls to check if a change in an php application has a performance impact.\n");
  echo("Use the url to the old code as url1 and the url of the new code as url2 and run it for example 100 times.\n");
  echo("Don't use this to measure remote webservers so that you don't measure the network instead of the php code.\n");
  echo("Usage:\n");
  echo("  ./benchmark.php <count> <url1> <url2> \n\n");
  exit();
}


$sum1=0;
$sum2=0;

for ($i=1; $i <= $count;$i++) {

  $time_start1 = microtime(true);
  $handle = fopen($url1, 'rb');
  $contents = stream_get_contents($handle);
  fclose($handle);
  $time_end1 = microtime(true);

  $time_start2 = microtime(true);
  $handle = fopen($url2, 'rb');
  $contents = stream_get_contents($handle);
  fclose($handle);
  $time_end2 = microtime(true);

  $t1=($time_end1 - $time_start1); 
  $t2=($time_end2 - $time_start2); 
  $sum1+=$t1;
  $sum2+=$t2;

  echo($i.'  '.$t1."  ".$t2."  ".($t1-$t2)."\n"); 
}
echo('url1: '.$url1.'     '.($sum1)."\n"); 
echo('url2: '.$url2.'     '.($sum2)."\n"); 
echo('diff:  '.($sum1-$sum2)."\n"); 
echo("url2 is ".round(($sum1/$sum2)*100)."% of the performance of url1\n"); 


echo("\n");
?>
