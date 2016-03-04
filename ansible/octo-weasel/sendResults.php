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

$tag = $argv[1];
$shaSum = $argv[2];
$currentTime = $argv[3];
$resultsFile = $argv[4];
$statsFile = $argv[5];

$apiUrl = getenv('API_URL');
$apiToken = getenv('API_TOKEN');

$response = [];

$response['measurement'] = json_decode(file_get_contents($statsFile), true);
$response['measurement']['performance'] = [];

$fh = fopen($resultsFile, 'r');
while (($line = fgets($fh)) !== false) {
    $parts = explode(',', $line);

    $type = trim($parts[0], '"');
    $cardinality = trim($parts[1], '"');
    $unit = $parts[2] === '"WalltimeMilliseconds"' ? 'ms' : 'unknown';

    if($type === 'propfind') {
        $type .= '-' . $cardinality;
        $cardinality = 1;
    }

    $cardinality = str_replace(['k', 'M'], ['000', '000000'], $cardinality);

    $response['measurement']['performance'][] = [
        'type' => $type,
        'unit' => $unit,
        'cardinality' => intval($cardinality),
        'repeats' => intval(trim($parts[5])),
        'value' => intval($parts[4]),
    ];
}

fclose($fh);

/* get mysql version */
preg_match('@[0-9]+\.[0-9]+\.[0-9]+@', shell_exec('mysql -V'), $version);
$mysqlVersion = $version[0];

$response['environment'] = [
    'git.tag' => $tag,
    'time' => $currentTime,
    'php' => phpversion(),
    'mysql' => $mysqlVersion,
    'opcache' => ini_get('opcache.enable') === '1' ? '1' : '0'
];


echo json_encode($response, JSON_PRETTY_PRINT);
echo PHP_EOL;

$data = json_encode($response);
$curl = curl_init();
curl_setopt_array($curl, [
    CURLOPT_RETURNTRANSFER => 1,
    CURLOPT_URL => $apiUrl . $shaSum,
    CURLOPT_USERAGENT => 'sendResults.php 0.1',
    CURLOPT_POST => 1,
    CURLOPT_POSTFIELDS => $data,
    CURLOPT_HTTPHEADER => [
        'Content-Type: application/json',
        'Content-Length: ' . strlen($data),
        'Authorization: token ' . $apiToken,
    ],
]);

$result = curl_exec($curl);
curl_close($curl);

if($result !== false) {
    echo "Data successful send" . PHP_EOL;
    echo PHP_EOL;
    echo "curl response: " . PHP_EOL;
    echo $result . PHP_EOL;
    exit;
}

echo "Failed to send data" . PHP_EOL;
exit(1);
