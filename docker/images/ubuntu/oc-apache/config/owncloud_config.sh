#!/bin/sh

# cat > /var/www/owncloud/config/base_config.php << EOF
# <?php
# \$CONFIG = array (
#   'instanceid' => 'oc0e56e6f24c',
#   'passwordsalt' => '29f1c9358866d5af5eca5e70db117e',
# );
# EOF


mysql -u $DB_ENV_MYSQL_USER -p $DB_ENV_MYSQL_PASS -h $DB_PORT_3306_TCP_ADDR -e "CREATE DATABASE IF NOT EXISTS owncloud;"
