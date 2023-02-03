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

use UpdateServer\Request;

class RequestTest extends \PHPUnit_Framework_TestCase {
	public function testRequest() {
		$request = new Request('8x2x0x12x1448709225.0768x1448709281xtestingxx2015-10-19T18:44:30+00:00%208ee2009de36e01a9866404f07722892f84c16e3e', []);
		$this->assertSame(8, $request->getMajorVersion());
		$this->assertSame(2, $request->getMinorVersion());
		$this->assertSame(0, $request->getMaintenanceVersion());
		$this->assertSame(12, $request->getRevisionVersion());
		$this->assertSame(1448709225.0768, $request->getInstallationMtime());
		$this->assertSame(1448709281, $request->getLastCheck());
		$this->assertSame('testing', $request->getChannel());
		$this->assertSame('', $request->getEdition());
		$this->assertSame('2015-10-19T18:44:30', $request->getBuild());
		$this->assertSame('', $request->getRemoteAddress());
	}

	public function testRequestInvalidEntry() {
		$this->expectException(\UpdateServer\Exceptions\UnsupportedReleaseException::class);
		new Request('x8x2x0x12x1448709225.0768x1448709281xtestingxx2015-10-19T18:44:30+00:00%208ee2009de36e01a9866404f07722892f84c16e3e', []);
	}
}
