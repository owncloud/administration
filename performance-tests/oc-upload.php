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

$file='a.jpg'; 
$owncoud_url='http://frank:123456@localhost:80/owncloud';

for ($i = 1; $i <= 5000; $i++) {

	// sequential upload
	shell_exec('time curl -T '.$file.' '.$owncoud_url.' /remote.php/webdav/'.$file);

	// parallel upload
	//exec('time curl -T '.$file.' '.$owncoud_url.'/remote.php/webdav/'.$file.' > /dev/null & ');

}


