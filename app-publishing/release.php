#!/usr/bin/php
<?php
/**
* @author Frank Karlitschek <frank@owncloud.org>
*
* @copyright Copyright (c) 2015, ownCloud, Inc.
* @license AGPL-3.0
*
* This code is free software: you can redistribute it and/or modify
* it under the terms of the GNU Affero General Public License, version 3,
* as published by the Free Software Foundation.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
* GNU Affero General Public License for more details.
*
* You should have received a copy of the GNU Affero General Public License, version 3,
* along with this program.  If not, see <http://www.gnu.org/licenses/>
*
*/


function showhelp() {
  echo("  Usage: release.php <action> <repo> <branch> \n");
  echo("  <action> is 'build'\n");
  echo("  <repo> is 'calendar', 'contacts' or 'bookmarks'\n");
  echo("  <directory> is '.' if the repository itself should be packaged or a subdirectory if a subdirectory should be packaged\n");
  echo("  <branch> is 'stable6', 'stable7', ... or 'master'\n");
  echo("\n");
  echo("  Example: release.php build calendar . stable7 \n");
  echo("\n");
  exit();
}

  /**
  * Delete some files that are in the git repositories but should not be part of the release
  */
  function removenotneededfiles() {
    echo("Removing not needed files...\n");
    passthru('rm -rf tests');
    passthru('rm -rf build');
    passthru('rm -rf .idea');
    passthru('rm -rf .scrutinizer.yml');
    passthru('rm -rf .jshintrc');
    passthru('rm -rf .well-known');
    passthru('rm -rf .gitignore');
    passthru('rm -rf .gitmodules');
    passthru('rm -rf .tx');
    passthru('rm -rf COPYING-README');
    passthru('rm -rf README.md');
    passthru('rm -rf autotest-js.sh');
    passthru('rm -rf autotest.cmd');
    passthru('rm -rf autotest.sh');
    passthru('rm -rf CONTRIBUTING.md');
    passthru('rm -rf issue_template.md');
    passthru('rm -rf autotest.cmd');
    passthru('rm -rf autotest-external.sh');
    passthru('rm -rf autotest-hhvm.sh');
    passthru('rm -rf bower.json');
    passthru('rm -rf buildjsdocs.sh');
    passthru('rm -rf .bowerrc');
  }

  /**
  * Create zip file for a specific directory.
  */
  function createpackage($name,$directory) {
    echo("Creating $name ...\n");
    passthru('zip  -rq9  '.$name.'.zip  '.$directory.'  --exclude=*.git*  --exclude=*.gitignore*  --exclude=*.tx  --exclude=*.gitkeep*  --exclude=*build.xml*  --exclude=*.travis.yml* --exclude=*.scrutinizer.yml* --exclude=*.jshintrc*  --exclude=*.idea*  --exclude=*issue_template.md* --exclude=*autotest.sh* --exclude=*autotest.cmd* --exclude=*autotest-js.sh* --exclude=*README.md*  ');
  }
    

///////////////////////////////////////////////////////////////
date_default_timezone_set('UTC');

echo("\nownCloud release packaging and publishing script \n\n");

if($argc<>5) showhelp();

// action
if($argv[1]=='build') {
  $action='build';
} else {
  showhelp();
}


// repository
$repository=$argv[2];


// directory
$directory=$argv[3];


// branch
if($argv[4]=='stable6') {
  $branch='stable6';
}elseif($argv[4]=='stable5') {
  $branch='stable5';
}elseif($argv[4]=='stable7') {
  $branch='stable7';
}elseif($argv[4]=='stable8') {
  $branch='stable8';
}elseif($argv[4]=='stable8.1') {
  $branch='stable8.1';
}elseif($argv[4]=='stable8.2') {
  $branch='stable8.2';
}elseif($argv[4]=='master') {
  $branch='master';
} else {
  showhelp();
}



// workflows

if($action=='build') {

  if($directory=='.') {
    $name=$repository;
  } else {
    $name=$directory;
  }	  

  echo("Building ".$name." branch:".$branch."\n");

  passthru('rm -rf build-temp');
  mkdir('build-temp');
  chdir('build-temp');

  echo("Checkout ".$repository."\n");

  passthru('git clone -q git@github.com:owncloud/'.$repository.'.git '.$repository);
  chdir($repository);
  if($directory<>'.') chdir($directory);


  if($branch<>'master') passthru('git checkout -b '.$branch.' origin/'.$branch.'');

  removenotneededfiles();
  
  chdir('..');
  createpackage($name,$name);
  passthru('mv '.$name.'.zip ..');
  chdir('..');


  if($directory<>'.') {
    passthru('mv '.$name.'.zip ..');
    chdir('..');
  }

  passthru('rm -rf build-temp');


}
