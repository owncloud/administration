#! /bin/sh
#
# Requires: apt-get install smartmontools
#
# 2018-01-23, jw@owncloud.com
# 2018-01-24, jw@owncloud.com accept different names, and show disk age.
#
#   5 Reallocated_Sector_Ct   0x0033   100   100   010    Pre-fail  Always       -       0
#   9 Power_On_Hours          0x0032   097   097   000    Old_age   Always       -       10234
#  12 Power_Cycle_Count       0x0032   097   097   000    Old_age   Always       -       2787
# 177 Wear_Leveling_Count     0x0013   099   099   000    Pre-fail  Always       -       21
# 179 Used_Rsvd_Blk_Cnt_Tot   0x0013   100   100   010    Pre-fail  Always       -       0
# 181 Program_Fail_Cnt_Total  0x0032   100   100   010    Old_age   Always       -       0
# 182 Erase_Fail_Count_Total  0x0032   100   100   010    Old_age   Always       -       0
# 183 Runtime_Bad_Block       0x0013   100   100   010    Pre-fail  Always       -       0
# 187 Uncorrectable_Error_Cnt 0x0032   100   100   000    Old_age   Always       -       0
# 190 Airflow_Temperature_Cel 0x0032   068   048   000    Old_age   Always       -       32
# 195 ECC_Error_Rate          0x001a   200   200   000    Old_age   Always       -       0
# 199 CRC_Error_Count         0x003e   099   099   000    Old_age   Always       -       11
# 235 POR_Recovery_Count      0x0012   099   099   000    Old_age   Always       -       78
# 241 Total_LBAs_Written      0x0032   099   099   000    Old_age   Always       -       20822674808
#
# at wilma:
#   7 Seek_Error_Rate         0x000f   089   060   030    Pre-fail  Always       -       84
# 195 Hardware_ECC_Recovered  0x001a   030   005   000    Old_age   Always       -       1891


disks=$(/usr/sbin/smartctl --scan | sed -e 's@^/dev/@@' -e 's/ .*//')
for disk in $disks; do
  smartctl -A /dev/$disk | egrep 'Power_On_Hours|Raw_Read_Error|Seek_Error|ECC_Error|CRC_Error|ECC_Recovered' | awk "{ printf \"%-5s %-24s %-8s %4.4s %10s\n\", \"$disk:\", \$2, \$7, \$9, \$10 }"
done

