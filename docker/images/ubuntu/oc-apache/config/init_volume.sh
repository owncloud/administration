#!/bin/sh
mkdir -p /data-vol/oc-data
mkdir -p /data-vol/oc-config
chown -R www-data:www-data /data-vol/oc-data
chown -R www-data:www-data /data-vol/oc-config
chmod 766 /data-vol/oc-config

if [ ! -d /var/www/owncloud/config ]; then
  /sbin/setuser www-data ln -s /data-vol/oc-config /var/www/owncloud/config
  /sbin/setuser www-data cp /var/www/owncloud/config_old/.htaccess /var/www/owncloud/config
  /sbin/setuser www-data cp /var/www/owncloud/config_old/config.sample.php /var/www/owncloud/config
  /sbin/setuser www-data touch /var/www/owncloud/config/create
fi

cat > /var/www/owncloud/info.php << EOF
<?php
echo phpinfo();
EOF

mysql -u$DB_ENV_MYSQL_USER -p$DB_ENV_MYSQL_PASS -h$DB_PORT_3306_TCP_ADDR -e "CREATE DATABASE IF NOT EXISTS owncloud;"

if [ $MEMCACHED_PORT_11211_TCP ]; then
  cat > /etc/php5/mods-available/memcached-session.ini << EOF
session.save_handler = memcache
session.save_path = "$MEMCACHED_PORT_11211_TCP"
EOF

  php5enmod memcached-session

  /sbin/setuser www-data cat > /var/www/owncloud/config/memcached.php << EOF
<?php
\$CONFIG = array (
  'memcached_servers' => array(
    array('$MEMCACHED_PORT_11211_TCP_ADDR', $MEMCACHED_PORT_11211_TCP_PORT)
  ),

);
EOF

fi


