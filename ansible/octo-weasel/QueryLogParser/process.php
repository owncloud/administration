<?php
/**
 * @author Morris Jobke <hey@morrisjobke.de>
 *
 * @copyright Copyright (c) 2016, ownCloud, Inc.
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

require_once 'QueryLogParser.php';
require_once 'AccessLogParser.php';

$results = [];
$failures = [];

$queryParser = new \OctoWeasel\QueryLogParser();
$qr = $queryParser->parseFile($argv[1]);

$results['queries'] = $qr['results'];
if($qr['failures'] !== []) {
    $failures['queries'] = $qr['failures'];
}

$accessParser = new \OctoWeasel\AccessLogParser();
$ar = $accessParser->parseFile($argv[2]);

$results['requests'] = $ar['results'];
if($ar['failures'] !== []) {
    $failures['requests'] = $ar['failures'];
}

$fh = fopen($argv[3], 'w');
fwrite($fh, json_encode($results, JSON_PRETTY_PRINT));
fclose($fh);

echo json_encode([
    'queries' => count($results['queries']),
    'requests' => count($results['requests']),
]);

if($failures !== []) {
    echo json_encode($failures, JSON_PRETTY_PRINT);
    exit(1);
}
