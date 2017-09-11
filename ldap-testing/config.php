<?php
  // Basic params
  $bdn = 'dc=owncloud,dc=com';
  $adn = 'cn=admin,dc=owncloud,dc=com';
  $apwd = 'admin';
  $host = 'localhost';
  $port = 389;

  // Define amount of users in groups
  $amount_users_in_groups = 10;
  $amount_groups= 5;

  // Define from which uid for users/groups script should start adding
  // This setting allows appending more users to existing LDAP
  $start_uid = 0;
  $start_uid_groups = 0;

  // Defines if image should be added to each LDAP User
  $configAddImage = true;

  // Defines if it should use memberof
  $memberof = false;

