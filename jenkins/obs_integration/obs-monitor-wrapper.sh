#!/bin/sh
#
# obs-monitor-wrapper.sh calls obs-monitor.py
# * A human readable html page is generated. It autorefreshes every 5min,
#   so that running this wrapper via cron keeps the contents current.
# * Failed builds are retriggered.
# * parseable text file is also generated.
#
# Run this on monkey.
#
# 2015-06-12, jw@owncloud.com

obsapi=$1
obsproj=$2
dir=$3
selfdir=$(dirname $0)

if [ -z "$3" ]; then
  echo Usage: $0 obsapi obsproj outdir
  exit 0
fi


pkgurl=$obsapi/package/show/
statsbase=/var/www/html/monitor/$obsproj-stats
api=https://s2.owncloud.com
opt_r=--retrigger-failed
test 0$NO_TRIGGER -gt 0 && opt_r=

python $selfdir/obs-monitor.py -A$obsapi $obsproj > $statsbase.html.new --html $opt_r

cat > $statsbase.html <<EOF
<meta http-equiv="refresh" content="300">

<table width='100%'><tr><td align='right'>
  updated every 15min by<br>
  <a href="https://github.com/owncloud/administration/blob/master/jenkins/obs_integration/obs-monitor.py">obs-monitor.py</a>
</td></tr></table>
EOF
cat < $statsbase.html.new >> $statsbase.html
rm    $statsbase.html.new

## not really needed today.
# python $selfdir/obs-monitor.py -A$obsapi $obsproj > $statsbase.txt.new
# mv $statsbase.txt.new $statsbase.txt

