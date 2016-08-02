#!/usr/bin/php
<?php
include 'config.php';

$cr = ldap_connect($host, $port);
ldap_set_option($cr, LDAP_OPT_PROTOCOL_VERSION, 3);
ldap_bind($cr, $adn, $apwd);

//creates on OU
$ouDN = 'ou=Armies,' . $bdn;
$entry = array();
$entry['objectclass'][] = 'top';
$entry['objectclass'][] = 'organizationalunit';
$entry['ou'] = 'Armies';
$b = ldap_add($cr, $ouDN, $entry);

$ouDN = 'ou=Zombies,' . $bdn;
$entry = array();
$entry['objectclass'][] = 'top';
$entry['objectclass'][] = 'organizationalunit';
$entry['ou'] = 'Zombies';
$b = ldap_add($cr, $ouDN, $entry);

$names = json_decode(file_get_contents('names.json'), true);
$cfn = count($names['fns']) - 1;
$csn = count($names['sns']) - 1;
$zombie_counter=0;

#CREATE KING
$uid= 'zombieKing';
$bossDN = 'uid=' . $uid . ',ou=Zombies,' . $bdn;
$fn = 'Zombie';
$sn = 'King';
$entry = array();
$entry['cn'] = $fn . ' ' . $sn;
$entry['gecos'] = $fn . ' ' . $sn;
$entry['sn'] = $sn;
$entry['givenName'] = $fn;
$entry['displayName'] = $sn . ', ' . $fn;
$entry['homeDirectory'] = '/home/openldap/zombieKing';
$entry['objectclass'][] = 'top';
$entry['objectclass'][] = 'posixAccount';
$entry['objectclass'][] = 'inetOrgPerson';
$entry['objectclass'][] = 'shadowAccount';
$entry['objectclass'][] = 'organizationalPerson';
$entry['objectclass'][] = 'person';
$entry['loginShell'] = '/bin/bash';
$entry['userPassword'] = 'zombieKing';
$entry['uidNumber'] = $start_uid;
$entry['gidNumber'] = 5000;
$entry['mail'] = 'zombieKing@example.org';
$entry['employeeNumber'] = 100000000000;
if ($configAddImage) {
    $entry['jpegPhoto'] = file_get_contents('zombie.jpg');
}

$ok = ldap_add($cr, $bossDN, $entry);
if ($ok) {
    echo('created [no. ' . $zombie_counter . '] ' . $uid . ': ' . $entry['displayName'] . PHP_EOL);
} else {
    echo('failed ' . $start_uid . ': ' . $entry['displayName'] . PHP_EOL);
}

for ($n = $start_uid_groups; $n < ($amount_groups+$start_uid_groups); $n++) {
	$cn = 'Army' . $n;
	$newgroupDN = 'cn=' . $cn . ',ou=Armies,' . $bdn;

	$entry = array();
	$entry['cn'] = $cn;
	$entry['objectclass'][] = 'top';
	if ($memberof) {
	    $entry['objectclass'][] = 'groupOfNames';
	    $entry['member'] = $bossDN;
	}
	else {
	    $entry['objectclass'][] = 'posixGroup';
        $entry['gidNumber'] = 500;
	    $entry['memberUid'] = 'zombieKing';
	}

	$ok = ldap_add($cr, $newgroupDN, $entry);
	if ($ok) {
		echo('created ' . ': ' . $entry['cn'] . PHP_EOL);
	} else {
		var_dump($entry);
	}

    $amount = $amount_users_in_groups;
    $start = $start_uid + $amount_groups + ($n * $amount);

    for ($i = $start; $i < ($amount + $start); $i++) {
        $uid = 'zombie' . $i;
        $newDN = 'uid=' . $uid . ',ou=Zombies,' . $bdn;

        $fn = $names['fns'][rand(0, $cfn)];
        $sn = $names['sns'][rand(0, $csn)];
        $entry = array();
        $entry['cn'] = $fn . ' ' . $sn;
        $entry['gecos'] = $fn . ' ' . $sn;
        $entry['sn'] = $sn;
        $entry['givenName'] = $fn;
        $entry['displayName'] = $sn . ', ' . $fn;
        $entry['homeDirectory'] = '/home/openldap/' . $uid;
        $entry['objectclass'][] = 'top';
        $entry['objectclass'][] = 'posixAccount';
        $entry['objectclass'][] = 'inetOrgPerson';
        $entry['objectclass'][] = 'shadowAccount';
        $entry['objectclass'][] = 'organizationalPerson';
        $entry['objectclass'][] = 'person';
        $entry['loginShell'] = '/bin/bash';
        $entry['userPassword'] = $uid;
        $entry['uidNumber'] = $i + 1;
        $entry['gidNumber'] = 5000;
        $entry['mail'] = $uid . '@example.org';
        $entry['employeeNumber'] = 100000000000;

        if ($configAddImage) {
            $entry['jpegPhoto'] = file_get_contents('zombie.jpg');
        }

        $ok = ldap_add($cr, $newDN, $entry);
        if ($ok) {
            echo('created [no. ' . $i . '] ' . $uid . ': ' . $entry['displayName'] . PHP_EOL);
	        if ($memberof) {
	            $group_info['member'] = $newDN;
	        }
	        else {
	            $group_info['memberUid'] = $uid;
	        }

            ldap_mod_add ( $cr, $newgroupDN, $group_info );
        } else {
            echo('failed ' . $uid . ': ' . $entry['displayName'] . PHP_EOL);
        }

    }
}


