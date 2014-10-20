#!/usr/bin/php
<?php
  $adn = 'cn=admin,dc=owncloud,dc=com';
  $base = 'dc=owncloud,dc=com';
  $apwd = 'admin';
  $host = 'localhost';
  $port = 389;

  $cr = ldap_connect($host, $port);
  ldap_set_option($cr, LDAP_OPT_PROTOCOL_VERSION, 3);
  ldap_bind($cr, $adn, $apwd);

  //creates on OU
  if(true) {
    $ouDN = 'ou=Boxes,'.$base;
    $entry['objectclass'][] = 'top';
    $entry['objectclass'][] = 'organizationalunit';
    $entry['ou'] = 'Boxes';
    $b = ldap_add($cr, $ouDN, $entry);
    if(!$b) {
      die;
    }
  }

  $start = 4;
  $gidStart = 6000;
  $amount = 7000;
  for($i=$start;$i<($amount+$start);$i++) {
    $cn = 'Box' . $i;
    $newDN = 'cn='.$cn.',ou=Boxes,'.$base;

    $entry = array();
    $entry['cn'] = $cn;
    $entry['gidNumber'] = $gidStart + $i + 1;
    $entry['objectclass'][] = 'posixGroup';

    $ok = ldap_add($cr, $newDN, $entry);
    if($ok) {
      echo('created ' . ': ' . $entry['cn'] . PHP_EOL);
    } else {
      var_dump($entry);
      die;
    }
  }


