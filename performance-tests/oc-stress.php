#!/usr/bin/php
<?php

/**
 * A tool to hammer an ownCloud server with a lot of parallel requests to generate some load
 *
 * @author Frank Karlitschek
 * @copyright 2013 Frank Karlitschek frank@owncloud.org
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


require("RollingCurl.php");


// Who am I ?
echo("\noc-stress v1.0 Frank Karlitschek\n\n");


// help
if($argc<>4) {
  echo("A tool to stress an ownCloud server and generate some load on it. It's using the great RollingCurl class from Josh Fraser to handle parallel curl requests.\n");
  echo("Parameter 1: The url to call.\n");
  echo("Parameter 2: Number of requests.\n");
  echo("Parameter 3: Number of parallel requests.\n");
  echo("Don't use this to call remote servers. You will test the network instead of ownCloud.\n");
  echo("Usage:\n");
  echo("  ./oc-stress.php <url> <number of requests> <number of parallel requests> \n\n");
  exit();
}

// configure
$url = $argv[1];
$requests_count = $argv[2];
$window_size = $argv[3];


// init stats
$count_processed=0;
$current_requestcount=0;


function request_callback($response, $info, $request) {
    global $count_processed;
    global $current_time;
    global $current_requestcount;
    
    if($current_time==0) $current_time=time();
    $count_processed++;
    
    if($current_time<>time()){
        $current_time=time();
        echo('Current requests/sec: '.($count_processed-$current_requestcount)."\n");
        
        $current_requestcount=$count_processed;
    }

// debug
//  echo('request: '.$count_processed)."\n";
//	print_r($response);
//  print_r($info);
//  print_r($request);

    if($info['http_code']<>200) echo('Error: http_code:'.$info['http_code']."\n");
}


$rc = new RollingCurl("request_callback");
$rc->window_size = $window_size;

for($i = 0; $i < $requests_count; ++$i) {
    $request = new RollingCurlRequest($url);
    $rc->add($request);
}

echo('Total number of requests: '.$requests_count."\n");
echo('Number of parallel requests: '.$window_size."\n");
echo("\n");


$start_time = microtime(true);
$rc->execute();
$end_time = microtime(true);


echo("\n");
echo('Processed requests: '.$current_requestcount." \n");
echo('Total time: '.round(($end_time-$start_time),3)." sec\n");
echo('Requests / sec: '.round($current_requestcount/($end_time-$start_time),3)." \n");
echo("\n");

