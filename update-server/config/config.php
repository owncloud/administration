<?php
/**
 * @license MIT <http://opensource.org/licenses/MIT>
 */

/**
 * Welcome to the almighty configuration file. In this file the update definitions for each version are released. Please
 * make sure to read below description of the config format carefully before proceeding.
 *
 * ownCloud updates are delivered by a release channel, at the moment the following channels are available:
 *
 * - production
 * - stable
 * - beta
 * - daily
 *
 * With exception of daily (which is a daily build of master) all of them need to be configured manually. The config
 * array looks like the following:
 *
 * 'production' => [
 * 	'8.2' => [
 * 		'latest' => '8.2.3',
 * 		'web' => 'https://doc.owncloud.org/server/8.2/admin_manual/maintenance/upgrade.html',
 * 		// downloadUrl is an optional entry, if not specified the URL is generated using https://download.owncloud.org/community/owncloud-'.$newVersion['latest'].'.zip
 * 		'downloadUrl' => 'https://download.owncloud.org/foo.zip',
 * 	],
 * ]
 *
 * In this case if a ownCloud with the major release of 8.2 sends an update request the 8.2.3 versuib is returned if the
 * current ownCloud version is below 8.2.
 *
 * The search for releases in the config array is fuzzy and happens as following:
 * 	1. Major.Minor.Maintenance.Revision
 * 	2. Major.Minor.Maintenance
 * 	3. Major.Minor
 * 	4. Major
 *
 * Once a result has been found this one is taken. This allows it to define an update order in case some releases should
 * not be skipped. Let's take a look at an example:
 *
 * 'production' => [
 * 	'8.2.0' => [
 * 		'latest' => '8.2.1',
 * 		'web' => 'https://doc.owncloud.org/server/8.2/admin_manual/maintenance/upgrade.html',
 * 	],
 * 	'8.2' => [
 * 		'latest' => '8.2.4',
 * 		'web' => 'https://doc.owncloud.org/server/8.2/admin_manual/maintenance/upgrade.html',
 * 	],
 * 	'8.2.4' => [
 * 		'latest' => '9.0.0',
 * 		'web' => 'https://doc.owncloud.org/server/8.2/admin_manual/maintenance/upgrade.html',
 * 	],
 * ]
 *
 * This configuration array would have the following meaning:
 *
 * 1. 8.2.0 instances would be delivered 8.2.1
 * 2. All instances below 8.2.4 EXCEPT 8.2.1 would be delivered 8.2.4
 * 3. 8.2.4 instances get 9.0.0 delivered
 *
 * Oh. And be a nice person and also adjust the integration tests at /tests/integration/features/update.feature after doing
 * a change to the update logic. That way you can also ensure that your changes will do what you wanted them to do. The
 * tests are automatically executed on Travis or you can do it locally:
 *
 * 	- php -S localhost:8888 update-server/index.php &
 * 	- tests/integration/ && ../../vendor/bin/behat .
 */

return [
	'production' => [
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
		'6' => [
			'latest' => '7.0.13',
			'web' => 'https://doc.owncloud.org/server/7.0/admin_manual/maintenance/upgrade.html',
		],
	],
	'stable' => [
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
		'6' => [
			'latest' => '7.0.13',
			'web' => 'https://doc.owncloud.org/server/7.0/admin_manual/maintenance/upgrade.html',
		],
	],
	'beta' => [
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
		'6' => [
			'latest' => '7.0.13',
			'web' => 'https://doc.owncloud.org/server/7.0/admin_manual/maintenance/upgrade.html',
		],
	],
	'daily' => [
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
	],
];
