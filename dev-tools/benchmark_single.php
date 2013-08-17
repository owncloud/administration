#!/usr/bin/php
<?php
/*
	By Markus Goetz <markus@woboq.com>
	This code is released under the public domain.
	
	Benchmark a URL
	Change the cookie line if you want to be logged in
*/

if($argc != 3) {
  echo("  ./benchmark_single.php <count> <url> \n\n");
  exit();
}

$count=$argv[1];
$url=$argv[2];

$opts = array(
  'http'=>array(
    'method'=>"GET",
    'header'=>"Accept-language: en\r\n" .
              "Cookie: oc0b4d3e5b1b=1n2vl307rn0clnsuhgoh78jq21\r\n" // changeme!
  )
);
$context = stream_context_create($opts);

$sum=0;

for ($i=1; $i <= $count;$i++) {

  $time_start1 = microtime(true);
  $contents = file_get_contents($url, false, $context);
  $time_end1 = microtime(true);

  $t1=($time_end1 - $time_start1); 
  $sum+=$t1;

  echo($i.'  '.$t1."\n"); 
}

echo('avg:   ' .  ($sum)/($count));

echo("\n");
?>
