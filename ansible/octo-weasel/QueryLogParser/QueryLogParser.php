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

class SkipException extends \Exception {}

class QueryLogParser {

    private function parseQuery($query) {
        if(strpos($query, 'SET NAMES') === 0 ||
            strpos($query, 'SET SESSION') === 0 ||
            strpos($query, 'SET GLOBAL') === 0 ||
            strpos($query, 'set autocommit') === 0 ||
            strpos($query, 'commit') === 0 ||
            strpos($query, 'START TRANSACTION') === 0 ||
            strpos($query, 'CREATE DATABASE') === 0 ||
            strpos($query, 'DROP DATABASE') === 0 ||
            strpos($query, 'SHOW DATABASE') === 0 ||
            strpos($query, 'CREATE TABLE') === 0 ||
            strpos($query, 'GRANT') === 0 ||
            strpos($query, 'SHOW GRANTS') === 0 ||
            strpos($query, 'select @@') === 0 ||
            strpos($query, 'SELECT user FROM mysql.user') === 0 ||
            strpos($query, 'select count(*) from information_schema.tables') === 0) {
            throw new SkipException('Unrelevant query' . $query);
        }
        if(preg_match('!^SELECT\s+.*\s+FROM\s+`(?P<table>[a-zA-Z_]+)`.*JOIN!', $query, $selectMatch)) {
            return [
                'type' => 'SELECT-JOIN',
                'table' => $selectMatch['table']
            ];
        }
        if(preg_match('!^SELECT\s+.*\s+FROM\s+`(?P<table>[a-zA-Z_]+)`!', $query, $selectMatch)) {
            return [
                'type' => 'SELECT',
                'table' => $selectMatch['table']
            ];
        }
        if(preg_match('!^UPDATE\s+`(?P<table>[a-zA-Z_]+)`!', $query, $selectMatch)) {
            return [
                'type' => 'UPDATE',
                'table' => $selectMatch['table']
            ];
        }
        if(preg_match('!^INSERT\s+INTO\s+`(?P<table>[a-zA-Z_]+)`!', $query, $selectMatch)) {
            return [
                'type' => 'INSERT',
                'table' => $selectMatch['table']
            ];
        }
        if(preg_match('!^DELETE\s+FROM\s+`(?P<table>[a-zA-Z_]+)`!', $query, $selectMatch)) {
            return [
                'type' => 'DELETE',
                'table' => $selectMatch['table']
            ];
        }

        throw new \Exception('Unknown query: ' . $query);
    }

    private function parseLine($line) {
        $line = str_replace("\n", "", $line);
        $match = preg_match('!^((\d{6} \d{2}:\d{2}:\d{2})|\t)\s+(?P<id>\d+)\s+(?P<type>[A-Za-z]+)(\s+(?P<query>.+))?\s*$!', $line, $matches);

        if(!$match) {
            throw new \Exception('Unknown line: ' . $line);
        }

        if(in_array($matches['type'], ['Connect', 'Quit'])) {
            throw new SkipException('Connect or Quit ' . $line);
        }

        if($match && $matches['type'] === 'Query' && isset($matches['query'])) {
            $queryResult = $this->parseQuery($matches['query']);
            return [
                'count' => 1,
                'type' => $queryResult['type'],
                'table' => $queryResult['table']
            ];
        }

        throw new \Exception('Unkown: ' . $line);
    }

    public function parseFile($filename)
    {
        $fh = fopen($filename, 'r');
        $results = [];
        $failures = [];
        $indexes = [];

        $previousLine = '';

        // skip all lines at the beginning that doesn't start with a number
        while ($line = fgets($fh)) {
            if (preg_match('!^\s*\d!', $line)) {
                $previousLine = $line;
                break;
            }
        }
        while ($line = fgets($fh)){
            if(preg_match('!^\s*\d!', $line)) { // line starts with number -> new query has started
                try {
                    $result = $this->parseLine($previousLine);
                    $key = $result['type'].$result['table'];
                    if(isset($indexes[$key])) {
                        $results[$indexes[$key]]['count'] += 1;
                    } else {
                        $results[] = $result;
                        $indexes[$key] = sizeof($results) - 1;
                    }
                } catch (SkipException $e) {
                    // pass
                } catch (\Exception $e) {
                    $failures[] = $e->getMessage();
                }

                $previousLine = $line;
            } else { // line with no number at the beginning -> belongs to previous line
                $previousLine .= $line;
            }
        }

        try {
            $result = $this->parseLine($previousLine);
            $key = $result['type'].$result['table'];
            if(isset($indexes[$key])) {
                $results[$indexes[$key]]['count'] += 1;
            } else {
                $results[] = $result;
                $indexes[$key] = sizeof($results) - 1;
            }
        } catch (SkipException $e) {
            // pass
        } catch (\Exception $e) {
            $failures[] = $e->getMessage();
        }

        return ['results' => $results, 'failures' => $failures];
    }
}
