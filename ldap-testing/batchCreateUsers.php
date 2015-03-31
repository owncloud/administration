#!/usr/bin/php
<?php
  include 'config.php';

  $cr = ldap_connect($host, $port);
  ldap_set_option($cr, LDAP_OPT_PROTOCOL_VERSION, 3);
  ldap_bind($cr, $adn, $apwd);

  //creates on OU
  if(true) {
    $ouDN = 'ou=Zombies,'.$bdn;
    $entry['objectclass'][] = 'top';
    $entry['objectclass'][] = 'organizationalunit';
    $entry['ou'] = 'Zombies';
    $b = ldap_add($cr, $ouDN, $entry);
    if(!$b) {
      die;
    }
  }

  $names = unserialize(file_get_contents('names.dat'));
  $cfn = count($names['fns']) - 1;
  $csn = count($names['sns']) - 1;

  $start = 294;
  $uidStart = 10249;
  $amount = 30000;
  for($i=$start;$i<($amount+$start);$i++) {
    $uid = 'zombie'.$i;
    $newDN = 'uid='.$uid.',ou=Zombies,'.$bdn;

    $fn = $names['fns'][rand(0, $cfn)];
    $sn = $names['sns'][rand(0, $csn)];
    $entry = array();
    $entry['cn'] = $fn.' '.$sn;
    $entry['gecos'] = $fn.' '.$sn;
    $entry['sn'] = $sn;
    $entry['givenName'] = $fn;
    $entry['displayName'] = $sn.', '.$fn;
    $entry['homeDirectory'] = '/home/openldap/'.$uid;
    $entry['objectclass'][] = 'posixAccount';
    $entry['objectclass'][] = 'inetOrgPerson';
    $entry['loginShell'] = '/bin/bash';
    $entry['userPassword'] = $uid;
    $entry['gidNumber'] = 5000;
    $entry['uidNumber'] = $uidStart + $i + 1;


    $ok = ldap_add($cr, $newDN, $entry);
    if($ok) {
      echo('created ' . $uid . ': ' . $entry['displayName'] . PHP_EOL);
    }
  }


