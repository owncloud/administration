<?php
/**
 * ownCloud
 *
 * @author Lukas Reschke <lukas@owncloud.com>
 * @copyright Copyright (c) 2016, ownCloud GmbH.
 *
 * This code is covered by the ownCloud Commercial License.
 *
 * You should have received a copy of the ownCloud Commercial License
 * along with this program. If not, see <https://owncloud.com/licenses/owncloud-commercial/>.
 *
 */

namespace UpdateServer;

class Config {
	/** @var array */
	private $configArray = [];

	/**
	 * @param string $configFile
	 */
	public function __construct($configFile) {
		$this->configArray = require_once $configFile;
	}

	/**
	 * @param string $key
	 * @return mixed
	 */
	public function get($key) {
		return $this->configArray[$key];
	}
}
