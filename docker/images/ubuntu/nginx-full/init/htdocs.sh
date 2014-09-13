#!/usr/bin/env bash
set -e

if [[ ! -d /data/htdocs ]]; then
  mkdir -p /data/htdocs
fi

cat >| /data/htdocs/index.php << EOF
<?php
echo phpinfo();
EOF

chown -R www-data:www-data /data/htdocs
