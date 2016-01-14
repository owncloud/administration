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

$q = new \OctoWeasel\QueryLogParser();
$r = $q->parseFile($argv[1]);

$fh = fopen($argv[2], 'w');
fwrite($fh, json_encode($r['results'], JSON_PRETTY_PRINT));
fclose($fh);

echo count($r['results']);

if($r['failures'] !== []) {
    echo json_encode($r['failures'], JSON_PRETTY_PRINT);
    exit(1);
}
