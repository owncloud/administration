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

namespace OctoWeasel;

class AccessLogParser {

    protected $patterns = array(
        '%%' => '(?P<percent>\%)',
        '%a' => '(?P<remoteIp>(((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))|([0-9A-Fa-f]{1,4}(?::[0-9A-Fa-f]{1,4}){7})|(([0-9A-Fa-f]{1,4})?(:[0-9A-Fa-f]{1,4}){0,7}:(:[0-9A-Fa-f]{1,4}){1,7}))',
        '%A' => '(?P<localIp>(((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))|([0-9A-Fa-f]{1,4}(?::[0-9A-Fa-f]{1,4}){7})|(([0-9A-Fa-f]{1,4})?(:[0-9A-Fa-f]{1,4}){0,7}:(:[0-9A-Fa-f]{1,4}){1,7}))',
        '%h' => '(?P<host>[a-zA-Z0-9\-\._:]+)',
        '%l' => '(?P<logname>(?:-|[\w-]+))',
        '%m' => '(?P<requestMethod>OPTIONS|GET|HEAD|POST|PUT|DELETE|TRACE|CONNECT|PATCH|PROPFIND)',
        '%p' => '(?P<port>\d+)',
        '%r' => '(?P<request>(?:(?:[A-Z]+) .+? HTTP/1.(?:0|1))|-|)',
        '%t' => '\[(?P<time>\d{2}/(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)/\d{4}:\d{2}:\d{2}:\d{2} (?:-|\+)\d{4})\]',
        '%u' => '(?P<user>(?:-|[\w-]+))',
        '%U' => '(?P<URL>.+?)',
        '%v' => '(?P<serverName>([a-zA-Z0-9]+)([a-z0-9.-]*))',
        '%V' => '(?P<canonicalServerName>([a-zA-Z0-9]+)([a-z0-9.-]*))',
        '%>s' => '(?P<status>\d{3}|-)',
        '%b' => '(?P<responseBytes>(\d+|-))',
        '%T' => '(?P<requestTime>(\d+\.?\d*))',
        '%O' => '(?P<sentBytes>[0-9]+)',
        '%I' => '(?P<receivedBytes>[0-9]+)',
        '\%\{(?P<name>[a-zA-Z]+)(?P<name2>[-]?)(?P<name3>[a-zA-Z]+)\}i' => '(?P<Header\\1\\3>.*?)',
        '%D' => '(?P<timeServeRequest>[0-9]+)',
    );

    private function parseLine($line, $pcreFormat) {

        if (!preg_match($pcreFormat, $line, $matches)) {
            throw new \Exception($line);
        }

        return [
            'request' => $matches['request'],
            'sentBytes' => $matches['sentBytes'],
            'timeServeRequest' => round(((int)$matches['timeServeRequest'])/1000)
        ];
    }

    public function parseFile($filename, $format = '%h %l %u %t "%r" %>s %O "%{Referer}i" "%{User-Agent}i" %D')
    {
        // strtr won't work for "complex" header patterns
        // $this->pcreFormat = strtr("#^{$format}$#", $this->patterns);
        $expr = "#^{$format}$#";
        foreach ($this->patterns as $pattern => $replace) {
            $expr = preg_replace("/{$pattern}/", $replace, $expr);
        }
        $pcreFormat = $expr;

        $fh = fopen($filename, 'r');
        $results = [];
        $failures = [];

        while ($line = fgets($fh)){
            try {
                $result = $this->parseLine($line, $pcreFormat);

                $requestParts = explode(' ', $result['request']);
                $httpVerb = $requestParts[0];

                if($result['timeServeRequest'] > 1000) {
                    $countIndex = '>1000';
                } else {
                    $countIndex = strval(ceil($result['timeServeRequest']/100) * 100);
                }

                if(isset($results[$httpVerb])) {
                    $results[$httpVerb]['totalSentBytes'] += $result['sentBytes'];
                    $results[$httpVerb]['totalServeRequestTime'] += $result['timeServeRequest'];
                } else {
                    $results[$httpVerb] = [
                        'totalSentBytes' => $result['sentBytes'],
                        'totalServeRequestTime' => $result['timeServeRequest'],
                        'count' => [
                            '100' => 0,
                            '200' => 0,
                            '300' => 0,
                            '400' => 0,
                            '500' => 0,
                            '600' => 0,
                            '700' => 0,
                            '800' => 0,
                            '900' => 0,
                            '1000' => 0,
                            '>1000' => 0,
                        ]
                    ];
                }

                $results[$httpVerb]['count'][$countIndex] += 1;

            } catch (\Exception $e) {
                $failures[] = $e->getMessage();
            }

        }

        return ['results' => $results, 'failures' => $failures];
    }
}
