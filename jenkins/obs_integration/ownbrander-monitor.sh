#!/bin/sh

pkgurl=https://s2.owncloud.com/package/show/
statsbase=/var/www/html/monitor/owncloud-stats
python obs-monitor.py -As2 ownbrander > $statsbase.html.new --html --retrigger-failed

cat > $statsbase.html <<EOF
<table width='100%'><tr><td align='right'>
  updated every 15min by<br>
  <a href="https://github.com/owncloud/administration/blob/master/jenkins/obs_integration/obs-monitor.py">obs-monitor.py</a>
</td></tr></table>
EOF
cat < $statsbase.html.new >> $statsbase.html
rm    $statsbase.html.new

sleep 10
python obs-monitor.py -As2 ownbrander > $statsbase.txt

