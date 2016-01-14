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

use Behat\Behat\Context\BehatContext;
use Behat\Gherkin\Node\TableNode;

require_once 'QueryLogParser.php';
require_once 'vendor/autoload.php';

/**
 * Features context.
 */
class FeatureContext extends BehatContext
{
    /** @var \OctoWeasel\QueryLogParser */
    private $octoWeasel;
    /** @var array */
    private $result;
    /** @var array */
    private $failures;

    public function __construct()
    {
        $this->octoWeasel = new \OctoWeasel\QueryLogParser();
    }

    /**
     * @When /^parsing the file "([^"]*)"$/
     */
    public function parsingFile($file)
    {
        $r = $this->octoWeasel->parseFile($file);
        $this->result = $r['results'];
        $this->failures = $r['failures'];
    }

    /**
     * @Then the result should be
     */
    public function theResultShouldBe(TableNode $table)
    {
        $rows = $table->getHash();
        $missing = [];
        foreach($rows as $row) {
            $i = array_search($row, $this->result);
            if($i !== false) {
                unset($this->result[$i]);
            } else {
                $missing[] = $row;
            }
        }
        if ($this->result !== []) {
            if ($missing === []) {
                throw new \Exception('Additionaly found: ' . print_r($this->result, true));
            }
            throw new \Exception('Additionally found: ' . print_r($this->result, true) . PHP_EOL . 'Missing: ' . print_r($missing, true));
        } elseif ($missing !== []) {
            throw new \Exception('Missing: ' . print_r($missing, true));
        }

        if($this->failures !== []) {
            throw new \Exception('Failures available' . print_r($this->failures));
        }
    }

}
