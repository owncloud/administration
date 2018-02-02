#! /usr/bin/python
#
# stale_filecache.py -- a script to find stale oc_filecache entries.
# run this after occ_checksum_check.py with a file containing all fileids found.
#
#
# (C) 2018 jw@owncloud.com
# Distribute under GPLv2 or ask.
#
# 2018-01-31, initia draught
# 2018-02-02, jw. Refactored into lib/owncloud.py

from __future__ import print_function
import sys, re
from lib.owncloud import OCC

if len(sys.argv) < 3:
  print("Usage: %s /srv/www/htdocs/owncloud/config/config.php all_ids.out" % sys.argv[0])
  sys.exit(1)

oc = OCC()
oc.load_config(sys.argv[1])
fileid_file = sys.argv[2]

def fetch_table_d(tname, keyname, what='*'):
  return oc.db_fetch_dict("SELECT "+what+" from "+tname, keyname)

# oc_mounts = fetch_table_d(oc.oc_+'mounts', 'mount_point')

fileid_seen = []
with open(fileid_file) as ff:
  for line in ff:
    try:
      fileid_seen.append(int(line))
    except ValueError:
      pass
fileid_seen = set(fileid_seen)         # make membership lookup fast
print("%8d filecache entries checked" % len(fileid_seen))


# nice try: But 2MB seems to be a limit for the query size...
# top_sto="SELECT COUNT(fileid) AS fileid_c, storage FROM "+oc.oc_+"filecache WHERE path LIKE 'files/%' AND fileid NOT IN ("+fileid_seen+") GROUP BY storage ORDER BY fileid_c DESC LIMIT 10"

all_outfile = re.sub('[^/]*$', 'files_fileids.out', fileid_file)        # different name in same folder.
ofd = open(all_outfile, "w")
total = 0

dbc = oc.db_cursor()
dbc.execute("SELECT fileid,storage FROM "+oc.oc_+"filecache WHERE path LIKE 'files/%'")
for row in dbc.fetchall():
  total += 1
  print("%d %d" % row, file=ofd)

ofd.close()
print("%8d stale filecache entries for /files/" % (total-len(fileid_seen)))

storage_stat={}
stale_outfile = re.sub('[^/]*$', 'files_fileids_stale.out', fileid_file)     # different name in same folder.
with open(all_outfile) as ifd:
  with open(stale_outfile, "w") as ofd:
    for line in ifd:
      (fileid,storage) = line.split()
      try:
        if int(fileid) not in fileid_seen:
          storage = int(storage)
          print(line.rstrip(), file=ofd)
          if not storage in storage_stat:
            storage_stat[storage] = 0
          else:
            storage_stat[storage] += 1
      except ValueError:
        pass

dbc.execute("SELECT id, numeric_id FROM "+oc.oc_+"storages")
storage_name={}
for row in dbc.fetchall():
  storage_name[row[1]] = row[0]

top=10
print("\nTop 10 storages with stale fileids:")
print("   count | storage | name")
print("---------+---------+-------")
for (sto, cnt) in reversed(sorted(storage_stat.items(), key=lambda x:x[1])):
  if sto in storage_name:
    name = storage_name[sto]
  else:
    name = ''
  print("%8d |%8s | %s" % (cnt, sto, name))
  top -= 1
  if top < 0:
    break

