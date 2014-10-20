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


  $gidStart = 6000;
  $groups = 100;

  $start = 294;
  $uidStart = 10249;
  $amount = 30000;
  for($i=$start;$i<($amount+$start);$i++) {
    $dn = 'cn=Box'.(rand(0, 99)).',ou=Boxes,'.$base;
    $uid = 'zombie'.$i;
    $entry['memberUid'] = 'uid='.$uid.',ou=Zombies,'.$base;

    $ok = ldap_mod_add($cr, $dn, $entry);
    if($ok) {
      echo('added ' . $entry['memberUid'] . ' as member of ' . $dn . PHP_EOL);
    } else {
      echo('error adding ' . $entry['memberUid'] . ' as member of ' . $dn . PHP_EOL);
    }
  }


