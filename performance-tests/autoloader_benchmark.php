<?php

/**

A simple tool to run autoload speed tests.
Loads a pre-defined set of core ownCloud classes via one of the autoloader classes and reports the time taken.
Pass the -c argument on the command line or c=1 on the querystring via a browser to use CachingAutoloader.
Use in conjunction with benchmark_single.php to repeatedly autoload classes to test caching.
Be sure to either place this file in the ownCloud root or adjust the require_once paths below prior to use.

**/

global $RUNTIME_NOAPPS;
$RUNTIME_NOAPPS = true;

define('PHPUNIT_RUN', 1);

require_once __DIR__.'/lib/base.php';

require_once __DIR__.'/lib/autoloader.php';
require_once __DIR__.'/lib/cachingautoloader.php';

OC_Hook::clear();
OC_Log::$enabled = false;

$classes = <<< ALL_CLASSES
\OC\BackgroundJob\Legacy\QueuedJob
\OC\BackgroundJob\Legacy\RegularJob
\OC\Connector\Sabre\ObjectTree
\OC\DB\AdapterOCI8
\OC\DB\AdapterPgSql
\OC\DB\AdapterSqlite
\OC\DB\AdapterSQLSrv
\OC\DB\Connection
\OC\Files\Cache\Scanner
\OC\Files\Cache\Shared_Cache
\OC\Files\Cache\Shared_Permissions
\OC\Files\Cache\Shared_Watcher
\OC\Files\Storage\AmazonS3
\OC\Files\Storage\CommonTest
\OC\Files\Storage\DAV
\OC\Files\Storage\Dropbox
\OC\Files\Storage\FTP
\OC\Files\Storage\Google
\OC\Files\Storage\iRODS
\OC\Files\Storage\MappedLocal
\OC\Files\Storage\SFTP
\OC\Files\Storage\Shared
\OC\Files\Storage\SMB
\OC\Files\Storage\SWIFT
\OC\Files\Storage\Temporary
\OC\Files\Storage\Wrapper\Quota
\OC\Files\Utils\Scanner
\OC\Group\Manager
\OC\HintException
\OC\Hooks\PublicEmitter
\OC\Log\Rotate
\OC\Memcache\APC
\OC\Memcache\APCu
\OC\Memcache\Memcached
\OC\Memcache\XCache
\OC\Preview\Image
\OC\Preview\JavaScript
\OC\Preview\MP3
\OC\Preview\PPTX
\OC\Preview\StarOffice
\OC\Preview\Unknown
\OC\Session\Internal
\OC\Session\Memory
\OC\Setup\MSSQL
\OC\Setup\MySQL
\OC\Setup\OCI
\OC\Setup\PostgreSQL
\OC\Setup\Sqlite
\OC\SyntaxException
\OC\Template\CSSResourceLocator
\OC\Template\JSResourceLocator
\OC\Updater
\OC\User\Manager
\OC\VObject\CompoundProperty
\OC\VObject\StringProperty
\OCA\AppFramework\AppTest
\OCA\AppFramework\Controller\ControllerTest
\OCA\AppFramework\Db\DoesNotExistException
\OCA\AppFramework\Db\EntityTest
\OCA\AppFramework\Db\MapperTest
\OCA\AppFramework\Db\MultipleObjectsReturnedException
\OCA\AppFramework\DependencyInjection\DIContainer
\OCA\AppFramework\DependencyInjection\DIContainerTest
\OCA\AppFramework\Http\DispatcherTest
\OCA\AppFramework\Http\DownloadResponseTest
\OCA\AppFramework\Http\ForbiddenResponse
\OCA\AppFramework\Http\ForbidenResponseTest
\OCA\AppFramework\Http\HttpTest
\OCA\AppFramework\Http\JSONResponse
\OCA\AppFramework\Http\JSONResponseTest
\OCA\AppFramework\Http\NotFoundResponse
\OCA\AppFramework\Http\NotFoundResponseTest
\OCA\AppFramework\Http\RedirectResponse
\OCA\AppFramework\Http\RedirectResponseTest
\OCA\AppFramework\Http\RequestTest
\OCA\AppFramework\Http\ResponseTest
\OCA\AppFramework\Http\TemplateResponse
\OCA\AppFramework\Http\TemplateResponseTest
\OCA\AppFramework\Http\TextDownloadResponse
\OCA\AppFramework\Http\TextDownloadResponseTest
\OCA\AppFramework\Http\TextResponse
\OCA\AppFramework\Http\TextResponseTest
\OCA\AppFramework\Http\TwigResponse
\OCA\AppFramework\Http\TwigResponseTest
\OCA\Appframework\Middleware\Http\HttpMiddleware
\OCA\AppFramework\Middleware\Http\HttpMiddlewareTest
\OCA\AppFramework\Middleware\Security\SecurityException
\OCA\AppFramework\Middleware\Security\SecurityMiddleware
\OCA\AppFramework\Middleware\Security\SecurityMiddlewareTest
\OCA\AppFramework\Middleware\Twig\TwigMiddleware
\OCA\AppFramework\Middleware\Twig\TwigMiddlewareTest
\OCA\AppFramework\MiddlewareDispatcherTest
\OCA\AppFramework\MiddlewareTest
\OCA\AppFramework\\routing\RouteConfigTest
\OCA\AppFramework\Utility\FaviconFetcherTest
\OCA\AppFramework\Utility\MethodAnnotationReaderTest
\OCA\AppFramework\Utility\NoValidUrlException
\OCA\Encryption\Proxy
\OCA\Firewall\Rules\CIDR
\OCA\Firewall\Rules\FileType
\OCA\Firewall\Rules\Regex
\OCA\Notes\API\NotesAPI
\OCA\Notes\API\NotesAPITest
\OCA\Notes\Controller\NotesController
\OCA\Notes\Controller\NotesControllerTest
\OCA\Notes\Controller\PageController
\OCA\Notes\Controller\PageControllerTest
\OCA\Notes\Db\Note
\OCA\Notes\Db\NoteTest
\OCA\Notes\DependencyInjection\DIContainer
\OCA\Notes\Service\NoteDoesNotExistException
\OCA\Notes\Service\NotesServiceTest
\OCA\Notes\Utility\NotesControllerTest
\OCA\user_ldap\GROUP_LDAP
\OCA\user_ldap\Group_Proxy
\OCA\user_ldap\lib\Jobs
\OCA\user_ldap\USER_LDAP
\OCA\user_ldap\User_Proxy
\OCP\Image
\OCP\Template
ALL_CLASSES;

$classes = preg_split("#[\r\n]+#", $classes);

$ce = true;

$caching = false;

if(strpos(PHP_SAPI, 'CLI') === false) {
	header('content-type: text/plain');
	if(isset($_GET['c'])) {
		$caching = true;
	}
}
else {
	foreach($argv as $a) {
		if($a == '-c') {
			$caching = true;
		}
	}
}

if($caching) {
	echo "Using CachingAutoloader\n";
	$memoryCache = \OC\Memcache\Factory::createLowLatency('Autoloader');
	$auto_loader = new \OC\CachingAutoloader($memoryCache);
}
else {
	echo "Using Autoloader\n";
	$auto_loader = new \OC\Autoloader();
}

$start = microtime(true);
foreach($classes as $class) {
	if($class[0] === '#') continue;
	//echo "{$class}\n";
	$auto_loader->load($class);
}
$full = microtime(true);
$taken = $full - $start;

echo $ce ? "All loaded\n" : "Some not loaded\n";
echo "Time Taken: {$taken} seconds\n";

if($caching) {
	if($memoryCache) {
		$cache = get_class($memoryCache);
		echo "Cache used: {$cache}\n";
	}
	else {
		echo "No cache\n";
	}
}
