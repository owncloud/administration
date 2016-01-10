<?php
/**
 * Signs a bare ownCloud release in a specified folder as well as all apps shipped within it.
 *
 * php sign.php /var/www/owncloud /var/private.key
 */

if(count($argv) !== 3) {
	die("Use php sign.php /var/www/owncloud /var/private.key\n");
}

$sourcePath = $argv[1] . '/';
$privateKey = $argv[2];

// Sign core release
$cmd = sprintf(
	'occ integrity:sign-core --privateKey=%s --certificate=%s/resources/codesigning/core.crt',
	$privateKey, $sourcePath
);

// Sign the core release
echo(shell_exec($sourcePath . $cmd));

// Now sign all apps in the app folder
$apps = array_filter(glob($sourcePath . 'apps/*'), 'is_dir');
foreach($apps as $app) {
	$app = basename($app);
	$cmd = sprintf(
		'occ integrity:sign-app --privateKey=%s --certificate=%s/resources/codesigning/core.crt --appId=%s',
		$privateKey, $sourcePath, $app
	);
	echo(shell_exec($sourcePath . $cmd));
}
