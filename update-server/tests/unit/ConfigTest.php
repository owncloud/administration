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

namespace Tests;

use UpdateServer\Config;

class ConfigTest extends \PHPUnit_Framework_TestCase {
	public function testGet() {
		$config = new Config(__DIR__ . '/../data/config.php');

		$productionResponse = [
			'8.2' => [
				'latest' => '8.2.3',
				'web' => 'https://doc.owncloud.org/server/8.2/admin_manual/maintenance/upgrade.html',
			],
			'8.1' => [
				'latest' => '8.1.6',
				'web' => 'https://doc.owncloud.org/server/8.1/admin_manual/maintenance/upgrade.html',
			],
			'8.0' => [
				'latest' => '8.0.11',
				'web' => 'https://doc.owncloud.org/server/8.0/admin_manual/maintenance/upgrade.html',
			],
			'7' => [
				'latest' => '7.0.13',
				'web' => 'https://doc.owncloud.org/server/8.0/admin_manual/maintenance/upgrade.html',
			],
		];
		$this->assertSame($productionResponse, $config->get('production'));
	}
}
