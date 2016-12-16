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
use UpdateServer\Request;
use UpdateServer\Response;

class ResponseTest extends \PHPUnit_Framework_TestCase {
	/** @var Request */
	private $request;
	/** @var Config */
	private $config;
	/** @var Response */
	private $response;

	public function setUp() {
		$this->request = $this->getMockBuilder('\UpdateServer\Request')
			->disableOriginalConstructor()->getMock();
		$this->config = $this->getMockBuilder('\UpdateServer\Config')
			->disableOriginalConstructor()->getMock();
		$this->response = new Response($this->request, $this->config);
	}

	public function dailyVersionProvider() {
		return [
			[
				'5',
				'',
			],
			[
				'6',
				'<?xml version="1.0" encoding="UTF-8"?>
<owncloud>
 <version>100.0.0.0</version>
 <versionstring>ownCloud daily</versionstring>
 <url>https://download.owncloud.org/community/owncloud-7.0.13.zip</url>
 <web>https://doc.owncloud.org/server/7.0/admin_manual/maintenance/upgrade.html</web>
</owncloud>
',
			],
			[
				'7',
				'<?xml version="1.0" encoding="UTF-8"?>
<owncloud>
 <version>100.0.0.0</version>
 <versionstring>ownCloud daily</versionstring>
 <url>https://download.owncloud.org/community/owncloud-8.0.11.zip</url>
 <web>https://doc.owncloud.org/server/7.0/admin_manual/maintenance/upgrade.html</web>
</owncloud>
',
			],
			[
				'8',
				'<?xml version="1.0" encoding="UTF-8"?>
<owncloud>
 <version>100.0.0.0</version>
 <versionstring>ownCloud daily</versionstring>
 <url>https://download.owncloud.org/community/owncloud-8.1.6.zip</url>
 <web>https://doc.owncloud.org/server/8.0/admin_manual/maintenance/upgrade.html</web>
</owncloud>
',
			],
			[
				'8.0.5',
				'<?xml version="1.0" encoding="UTF-8"?>
<owncloud>
 <version>100.0.0.0</version>
 <versionstring>ownCloud daily</versionstring>
 <url>https://download.owncloud.org/community/owncloud-8.1.6.zip</url>
 <web>https://doc.owncloud.org/server/8.0/admin_manual/maintenance/upgrade.html</web>
</owncloud>
',
			],
			[
				'9',
				'<?xml version="1.0" encoding="UTF-8"?>
<owncloud>
 <version>100.0.0.0</version>
 <versionstring>ownCloud daily</versionstring>
 <url>https://download.owncloud.org/community/owncloud-daily-master.zip</url>
 <web>https://doc.owncloud.org/server/9.0/admin_manual/maintenance/upgrade.html</web>
</owncloud>
',
			],
			[
				'9.0.3',
				'<?xml version="1.0" encoding="UTF-8"?>
<owncloud>
 <version>100.0.0.0</version>
 <versionstring>ownCloud daily</versionstring>
 <url>https://download.owncloud.org/community/owncloud-daily-master.zip</url>
 <web>https://doc.owncloud.org/server/9.0/admin_manual/maintenance/upgrade.html</web>
</owncloud>
',
			]
		];
	}

	/**
	 * @dataProvider dailyVersionProvider
	 */
	public function testBuildResponseForOutdatedDaily($version, $expected) {
		$this->request
			->expects($this->once())
			->method('getChannel')
			->willReturn('daily');
		$this->request
			->expects($this->any())
			->method('getBuild')
			->willReturn('2015-10-19T18:44:30+00:00');
		$this->config
			->expects($this->once())
			->method('get')
			->with('daily')
			->willReturn(
				[
					'9.1' => [
						'downloadUrl' => 'https://download.owncloud.org/community/owncloud-daily-master.zip',
						'web' => 'https://doc.owncloud.org/server/9.1/admin_manual/maintenance/upgrade.html',
					],
					'9.0' => [
						'downloadUrl' => 'https://download.owncloud.org/community/owncloud-daily-master.zip',
						'web' => 'https://doc.owncloud.org/server/9.0/admin_manual/maintenance/upgrade.html',
					],
					'8.2' => [
						'downloadUrl' => 'https://download.owncloud.org/community/owncloud-daily-stable9.zip',
						'web' => 'https://doc.owncloud.org/server/8.2/admin_manual/maintenance/upgrade.html',
					],
					'8.1' => [
						'downloadUrl' => 'https://download.owncloud.org/community/owncloud-8.2.3.zip',
						'web' => 'https://doc.owncloud.org/server/8.1/admin_manual/maintenance/upgrade.html',
					],
					'8.0' => [
						'downloadUrl' => 'https://download.owncloud.org/community/owncloud-8.1.6.zip',
						'web' => 'https://doc.owncloud.org/server/8.0/admin_manual/maintenance/upgrade.html',
					],
					'7' => [
						'downloadUrl' => 'https://download.owncloud.org/community/owncloud-8.0.11.zip',
						'web' => 'https://doc.owncloud.org/server/7.0/admin_manual/maintenance/upgrade.html',
					],
					'6' => [
						'downloadUrl' => 'https://download.owncloud.org/community/owncloud-7.0.13.zip',
						'web' => 'https://doc.owncloud.org/server/7.0/admin_manual/maintenance/upgrade.html',
					],
				]
			);
		$this->request
			->expects($this->any())
			->method('getMajorVersion')
			->willReturn($version[0]);
		if(isset($version[4])) {
			$this->request
				->expects($this->any())
				->method('getMinorVersion')
				->willReturn($version[4]);
		}

		$this->assertSame($expected, $this->response->buildResponse());
	}

	/**
	 * @dataProvider dailyVersionProvider
	 */
	public function testBuildResponseForCurrentDaily($version) {
		$this->request
			->expects($this->once())
			->method('getChannel')
			->willReturn('daily');
		$this->request
			->expects($this->any())
			->method('getBuild')
			->willReturn('2025-10-19T18:44:30+00:00');
		$this->request
			->expects($this->any())
			->method('getMajorVersion')
			->willReturn($version[0]);
		if(isset($version[4])) {
			$this->request
				->expects($this->any())
				->method('getMinorVersion')
				->willReturn($version[4]);
		}
		$this->config
			->expects($this->once())
			->method('get')
			->with('daily')
			->willReturn(
				[
					'9.1' => [
						'downloadUrl' => 'https://download.owncloud.org/community/owncloud-daily-master.zip',
						'web' => 'https://doc.owncloud.org/server/9.1/admin_manual/maintenance/upgrade.html',
					],
					'9.0' => [
						'downloadUrl' => 'https://download.owncloud.org/community/owncloud-daily-master.zip',
						'web' => 'https://doc.owncloud.org/server/9.0/admin_manual/maintenance/upgrade.html',
					],
					'8.2' => [
						'downloadUrl' => 'https://download.owncloud.org/community/owncloud-daily-stable9.zip',
						'web' => 'https://doc.owncloud.org/server/8.2/admin_manual/maintenance/upgrade.html',
					],
					'8.1' => [
						'downloadUrl' => 'https://download.owncloud.org/community/owncloud-8.2.3.zip',
						'web' => 'https://doc.owncloud.org/server/8.1/admin_manual/maintenance/upgrade.html',
					],
					'8.0' => [
						'downloadUrl' => 'https://download.owncloud.org/community/owncloud-8.1.6.zip',
						'web' => 'https://doc.owncloud.org/server/8.0/admin_manual/maintenance/upgrade.html',
					],
					'7' => [
						'downloadUrl' => 'https://download.owncloud.org/community/owncloud-8.0.11.zip',
						'web' => 'https://doc.owncloud.org/server/7.0/admin_manual/maintenance/upgrade.html',
					],
					'6' => [
						'downloadUrl' => 'https://download.owncloud.org/community/owncloud-7.0.13.zip',
						'web' => 'https://doc.owncloud.org/server/7.0/admin_manual/maintenance/upgrade.html',
					],
				]
			);

		$expected = '';

		$this->assertSame($expected, $this->response->buildResponse());
	}

	/**
	 * @return array
	 */
	public function responseProvider() {
		return [
			[
				'production',
				'8',
				'0',
				'8',
				'',
				'<?xml version="1.0" encoding="UTF-8"?>
<owncloud>
 <version>8.0.9</version>
 <versionstring>ownCloud 8.0.9</versionstring>
 <url>https://download.owncloud.org/community/owncloud-8.0.9.zip</url>
 <web>https://doc.owncloud.org/server/8.0/admin_manual/maintenance/upgrade.html</web>
</owncloud>
',
			],
			[
				'production',
				'8',
				'0',
				'7',
				'',
				'<?xml version="1.0" encoding="UTF-8"?>
<owncloud>
 <version>8.0.7.1</version>
 <versionstring>ownCloud 8.0.7.1</versionstring>
 <url>https://download.owncloud.org/community/owncloud-8.0.7.1.zip</url>
 <web>https://doc.owncloud.org/server/8.0/admin_manual/maintenance/upgrade.html</web>
</owncloud>
',
			],
			[
				'production',
				'8',
				'0',
				'7',
				'1',
				'<?xml version="1.0" encoding="UTF-8"?>
<owncloud>
 <version>8.0.8</version>
 <versionstring>ownCloud 8.0.8</versionstring>
 <url>https://download.owncloud.org/community/owncloud-8.0.8.zip</url>
 <web>https://doc.owncloud.org/server/8.0/admin_manual/maintenance/upgrade.html</web>
</owncloud>
',
			],
			[
				'production',
				'8',
				'0',
				'9',
				'',
				'<?xml version="1.0" encoding="UTF-8"?>
<owncloud>
 <version>8.0.10</version>
 <versionstring>ownCloud 8.0.10</versionstring>
 <url>https://download.owncloud.org/community/owncloud-8.0.10.zip</url>
 <web>https://doc.owncloud.org/server/8.0/admin_manual/maintenance/upgrade.html</web>
</owncloud>
',
			],
			[
				'production',
				'8',
				'0',
				'10',
				'',
				'',
			],
			[
				'production',
				'8',
				'0',
				'11',
				'',
				'',
			],
			[
				'production',
				'7',
				'0',
				'11',
				'',
				'<?xml version="1.0" encoding="UTF-8"?>
<owncloud>
 <version>7.0.12</version>
 <versionstring>ownCloud 7.0.12</versionstring>
 <url>https://download.owncloud.org/community/owncloud-7.0.12.zip</url>
 <web>https://doc.owncloud.org/server/8.0/admin_manual/maintenance/upgrade.html</web>
</owncloud>
',
			],
			[
				'production',
				'8',
				'1',
				'4',
				'',
				'<?xml version="1.0" encoding="UTF-8"?>
<owncloud>
 <version>8.1.5</version>
 <versionstring>ownCloud 8.1.5</versionstring>
 <url>https://download.owncloud.org/community/owncloud-8.1.5.zip</url>
 <web>https://doc.owncloud.org/server/8.1/admin_manual/maintenance/upgrade.html</web>
</owncloud>
',
			],
			[
				'production',
				'8',
				'1',
				'5',
				'',
				'',
			],
			[
				'production',
				'8',
				'2',
				'1',
				'',
				'<?xml version="1.0" encoding="UTF-8"?>
<owncloud>
 <version>8.2.2</version>
 <versionstring>ownCloud 8.2.2</versionstring>
 <url>https://download.owncloud.org/community/owncloud-8.2.2.zip</url>
 <web>https://doc.owncloud.org/server/8.2/admin_manual/maintenance/upgrade.html</web>
</owncloud>
',
			],
			[
				'production',
				'8',
				'2',
				'3',
				'',
				'',
			],
			[
				'production',
				'8',
				'3',
				'3',
				'',
				'',
			],
			[
				'production',
				'',
				'',
				'',
				'',
				'',
			],
			[
				'stable',
				'8',
				'0',
				'9',
				'',
				'<?xml version="1.0" encoding="UTF-8"?>
<owncloud>
 <version>8.0.10</version>
 <versionstring>ownCloud 8.0.10</versionstring>
 <url>https://download.owncloud.org/community/owncloud-8.0.10.zip</url>
 <web>https://doc.owncloud.org/server/8.0/admin_manual/maintenance/upgrade.html</web>
</owncloud>
',
			],
			[
				'stable',
				'8',
				'0',
				'10',
				'',
				'',
			],
			[
				'stable',
				'8',
				'0',
				'11',
				'',
				'',
			],
			[
				'stable',
				'6',
				'0',
				'5',
				'',
				'<?xml version="1.0" encoding="UTF-8"?>
<owncloud>
 <version>7.0.12</version>
 <versionstring>ownCloud 7.0.12</versionstring>
 <url>https://downloads.owncloud.com/foo.zip</url>
 <web>https://doc.owncloud.org/server/8.0/admin_manual/maintenance/upgrade.html</web>
</owncloud>
',
			],
			[
				'stable',
				'7',
				'0',
				'11',
				'',
				'<?xml version="1.0" encoding="UTF-8"?>
<owncloud>
 <version>7.0.12</version>
 <versionstring>ownCloud 7.0.12</versionstring>
 <url>https://download.owncloud.org/community/owncloud-7.0.12.zip</url>
 <web>https://doc.owncloud.org/server/8.0/admin_manual/maintenance/upgrade.html</web>
</owncloud>
',
			],
			[
				'stable',
				'8',
				'1',
				'4',
				'',
				'<?xml version="1.0" encoding="UTF-8"?>
<owncloud>
 <version>8.1.5</version>
 <versionstring>ownCloud 8.1.5</versionstring>
 <url>https://download.owncloud.org/community/owncloud-8.1.5.zip</url>
 <web>https://doc.owncloud.org/server/8.1/admin_manual/maintenance/upgrade.html</web>
</owncloud>
',
			],
			[
				'stable',
				'8',
				'1',
				'5',
				'',
				'',
			],
			[
				'stable',
				'8',
				'2',
				'1',
				'',
				'<?xml version="1.0" encoding="UTF-8"?>
<owncloud>
 <version>8.2.2</version>
 <versionstring>ownCloud 8.2.2</versionstring>
 <url>https://download.owncloud.org/community/owncloud-8.2.2.zip</url>
 <web>https://doc.owncloud.org/server/8.2/admin_manual/maintenance/upgrade.html</web>
</owncloud>
',
			],
			[
				'stable',
				'8',
				'2',
				'3',
				'',
				'',
			],
			[
				'stable',
				'8',
				'3',
				'3',
				'',
				'',
			],
			[
				'stable',
				'',
				'',
				'',
				'',
				'',
			],
			[
				'beta',
				'8',
				'0',
				'9',
				'',
				'<?xml version="1.0" encoding="UTF-8"?>
<owncloud>
 <version>8.0.10</version>
 <versionstring>ownCloud 8.0.10</versionstring>
 <url>https://download.owncloud.org/community/owncloud-8.0.10.zip</url>
 <web>https://doc.owncloud.org/server/8.0/admin_manual/maintenance/upgrade.html</web>
</owncloud>
',
			],
			[
				'beta',
				'8',
				'0',
				'10',
				'',
				'',
			],
			[
				'beta',
				'8',
				'0',
				'11',
				'',
				'',
			],
			[
				'beta',
				'7',
				'0',
				'11',
				'',
				'<?xml version="1.0" encoding="UTF-8"?>
<owncloud>
 <version>7.0.12</version>
 <versionstring>ownCloud 7.0.12</versionstring>
 <url>https://download.owncloud.org/community/owncloud-7.0.12.zip</url>
 <web>https://doc.owncloud.org/server/8.0/admin_manual/maintenance/upgrade.html</web>
</owncloud>
',
			],
			[
				'beta',
				'7',
				'0',
				'13',
				'',
				'',
			],
			[
				'beta',
				'8',
				'1',
				'4',
				'',
				'<?xml version="1.0" encoding="UTF-8"?>
<owncloud>
 <version>8.1.5</version>
 <versionstring>ownCloud 8.1.5</versionstring>
 <url>https://download.owncloud.org/community/owncloud-8.1.5.zip</url>
 <web>https://doc.owncloud.org/server/8.1/admin_manual/maintenance/upgrade.html</web>
</owncloud>
',
			],
			[
				'beta',
				'8',
				'1',
				'5',
				'',
				'',
			],
			[
				'beta',
				'8',
				'2',
				'1',
				'',
				'<?xml version="1.0" encoding="UTF-8"?>
<owncloud>
 <version>8.2.2</version>
 <versionstring>ownCloud 8.2.2</versionstring>
 <url>https://download.owncloud.org/community/owncloud-8.2.2.zip</url>
 <web>https://doc.owncloud.org/server/8.2/admin_manual/maintenance/upgrade.html</web>
</owncloud>
',
			],
			[
				'beta',
				'8',
				'2',
				'3',
				'',
				'',
			],
			[
				'beta',
				'8',
				'3',
				'3',
				'',
				'',
			],
			[
				'beta',
				'',
				'',
				'',
				'',
				'',
			],
			[
				'',
				'8',
				'2',
				'1',
				'',
				'',
			],
			[
				'',
				'',
				'',
				'',
				'',
				'',
			],
		];
	}

	/**
	 * @param string $channel
	 * @param string $majorVersion
	 * @param string $minorVersion
	 * @param string $revisionVersion
	 * @param string $maintenanceVersion
	 * @param string $expected
	 *
	 * @dataProvider responseProvider
	 */
	public function testBuildResponseForChannel($channel,
												$majorVersion,
												$minorVersion,
												$maintenanceVersion,
												$revisionVersion,
												$expected) {
		$config = [
			'8.2' => [
				'latest' => '8.2.2',
				'web' => 'https://doc.owncloud.org/server/8.2/admin_manual/maintenance/upgrade.html',
			],
			'8.1' => [
				'latest' => '8.1.5',
				'web' => 'https://doc.owncloud.org/server/8.1/admin_manual/maintenance/upgrade.html',
			],
			'8.0' => [
				'latest' => '8.0.10',
				'web' => 'https://doc.owncloud.org/server/8.0/admin_manual/maintenance/upgrade.html',
			],
			'8.0.7' => [
				'latest' => '8.0.7.1',
				'web' => 'https://doc.owncloud.org/server/8.0/admin_manual/maintenance/upgrade.html',
			],
			'8.0.7.1' => [
				'latest' => '8.0.8',
				'web' => 'https://doc.owncloud.org/server/8.0/admin_manual/maintenance/upgrade.html',
			],
			'8.0.8' => [
				'latest' => '8.0.9',
				'web' => 'https://doc.owncloud.org/server/8.0/admin_manual/maintenance/upgrade.html',
			],
			'7' => [
				'latest' => '7.0.12',
				'web' => 'https://doc.owncloud.org/server/8.0/admin_manual/maintenance/upgrade.html',
			],
			'6' => [
				'latest' => '7.0.12',
				'web' => 'https://doc.owncloud.org/server/8.0/admin_manual/maintenance/upgrade.html',
				'downloadUrl' => 'https://downloads.owncloud.com/foo.zip',
			],
		];
		$this->request
			->expects($this->any())
			->method('getChannel')
			->willReturn($channel);
		$this->config
			->expects($this->any())
			->method('get')
			->with($channel)
			->willReturn($config);
		$this->request
			->expects($this->any())
			->method('getMajorVersion')
			->willReturn($majorVersion);
		$this->request
			->expects($this->any())
			->method('getMinorVersion')
			->willReturn($minorVersion);
		$this->request
			->expects($this->any())
			->method('getMaintenanceVersion')
			->willReturn($maintenanceVersion);
		$this->request
			->expects($this->any())
			->method('getRevisionVersion')
			->willReturn($revisionVersion);

		$this->assertSame($expected, $this->response->buildResponse());
	}
}
