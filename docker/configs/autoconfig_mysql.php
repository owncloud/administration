<?php 
$user = $_SERVER['DB_ENV_MYSQL_USER'];
$pass = $_SERVER['DB_ENV_MYSQL_PASS'];
$dbhost = $_SERVER['DB_PORT_3306_TCP_ADDR'];
$dbname = $_SERVER['DB_NAME'];

$AUTOCONFIG = array(
  'directory'     => '/data-vol/oc-data', 
  'adminlogin'    => 'admin',
  'adminpass'     => 'password',
  "dbtype"        => "mysql",
  "dbname"        => "owncloud",
  "dbuser"        => "username",
  "dbpass"        => "password",
  "dbhost"        => "localhost",
  "dbtableprefix" => "",
);

