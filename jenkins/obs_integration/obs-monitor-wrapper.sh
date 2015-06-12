#!/bin/sh
#
# obs-monitor-wrapper.sh calls obs-monitor.py
# A html page is generated, and failed builds are retriggered.
# Then an easier to parse text page is generated.
#
# Run this on monkey.
#
# 2015-06-12, jw@owncloud.com

obsapi=$1
obsproj=$2
dir=$3

if [ -z "$3" ]; then
  echo Usage: $0 obsapi obsproj outdir
  exit 0
fi

pkgurl=$obsapi/package/show/
statsbase=/var/www/html/monitor/$obsproj-stats
api=https://s2.owncloud.com
python obs-monitor.py -A$obsapi $obsproj > $statsbase.html.new --html --retrigger-failed

cat > $statsbase.html <<EOF
<table width='100%'><tr><td align='right'>
  updated every 15min by<br>
  <a href="https://github.com/owncloud/administration/blob/master/jenkins/obs_integration/obs-monitor.py">obs-monitor.py</a>
</td></tr></table>
EOF
cat < $statsbase.html.new >> $statsbase.html
rm    $statsbase.html.new

python obs-monitor.py -A$obsapi $obsproj > $statsbase.txt.new
mv $statsbase.txt.new $statsbase.txt

