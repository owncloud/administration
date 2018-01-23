#! /bin/sh
#
# Requires: apt-get install smartmontools
#
# 2018-01-23, jw@owncloud.com

disks=$(/usr/sbin/smartctl --scan | sed -e 's@^/dev/@@' -e 's/ .*//')
for disk in $disks; do
  smartctl -A /dev/$disk | egrep 'Raw_Read_Error|Seek_Error|ECC_Recovered' | awk "{ printf \"%-5s %-24s %-8s %4.4s %10s\n\", \"$disk:\", \$2, \$7, \$9, \$10 }"
done

