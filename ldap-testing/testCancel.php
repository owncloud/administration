<?php

$RUNTIME_NOAPPS = true;
require_once 'lib/base.php';
\OC_App::loadApp('user_ldap');

OCA\user_ldap\lib\Helper::clearMapping('user');

$ldapWrapper = new OCA\user_ldap\lib\LDAP();

$configPrefixes = OCA\user_ldap\lib\Helper::getServerConfigurationPrefixes(true);
$connector = new OCA\user_ldap\lib\Connection($ldapWrapper, $configPrefixes[0]);

$userManager = new OCA\user_ldap\lib\user\Manager(\OC::$server->getConfig(),
  new OCA\user_ldap\lib\FilesystemHelper(),
  new OCA\user_ldap\lib\LogWrapper(),
  \OC::$server->getAvatarManager(),
  new \OCP\Image());

$ldapAccess = new OCA\user_ldap\lib\Access($connector, $ldapWrapper, $userManager);

$userBackend = new OCA\user_ldap\USER_LDAP($ldapAccess);

$users = $userBackend->getUsers('', 10, 0);
$ok = count($users) === 10;
if($ok) {
  print('Step 1: fetching 10 users succeeded' . PHP_EOL);
} else {
  print('Step 1: fetching 10 users failed, check your setup! Users found:  ' . count($users)  . PHP_EOL);
  exit;
}
$ldapAccess->readAttribute($ldapAccess->connection->ldapAgentName, 'cn');
print('Step 2: reading attribute done' . PHP_EOL);
$users = $userBackend->getUsers('', 10, 10);
$ok = count($users) === 10;
if($ok) {
  print('Validation: cancelling Paged Search succeeded :) !' . PHP_EOL);
} else {
  print('Validation: cancelling Paged Search failed! Users found:  ' . count($users)  . PHP_EOL);
}
