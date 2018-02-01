#! /usr/bin/python
#
# stale_filecache.py -- a script to find stale oc_filecache entries.
# run this after occ_checksum_check.py with a file containing all fileids found.
#
#
# (C) 2018 jw@owncloud.co
# Distribute under GPLv2 or ask.
#
# 2018-01-31, initia draught

from __future__ import print_function
import sys, os, re, time
import zlib, hashlib

verbose = False             # set to true, to include full mount and cache entry dump on error.

try:
  # apt-get install python-mysqldb
  # zypper in python-MySQL-python
  import MySQLdb as mysql
except:
  try:
    # apt-get python-pymysql
    # zypper in python-PyMySQL  # fails to connect on s3 ???
    import pymysql as mysql
  except:
    try:
      # apt-get python-mysql.connector
      # yum install mysql-connector-python
      # zypper in python-mysql-connector-python
      import mysql.connector as mysql
    except:
      raise ImportError("need one of (MySQLdb, pymysql, mysql.connector) e.g. from DEB packages (python-mysqldb, python-pymysql, python-mysql.connector)")


if len(sys.argv) < 3:
  print("Usage: %s /srv/www/htdocs/owncloud/config/config.php all_ids.out" % sys.argv[0])
  sys.exit(1)

fileid_file = sys.argv[2]

## hackey parser for config.php
config = {}
for line in open(sys.argv[1]):
  for m in re.finditer('(["\'])(.*?)\\1\s*=>\s*((["\'])(.*?)\\1|([\w]+))\s*,', line):
    # m = ("'", 'memcache.local', "'\\OC\\Memcache\\Redis'", "'", '\\OC\\Memcache\\Redis', None)
    # m = ("'", 'port', '6379', None, None, '6379')
    config[m.group(2)] = m.group(5) or m.group(6)

if config['dbtype'] == 'mysql':
  # any of MySQLdb, python oe mysql.connector work with this API:
  try:
    sock='/var/run/mysql/mysql.sock'
    if os.path.exists(sock) and config['dbhost'] == 'localhost':
      # pymysql does not try the unix domain socket, if tcp port 3306 is closed.
      db = mysql.connect(host=config['dbhost'], user=config['dbuser'], passwd=config['dbpassword'], db=config['dbname'], unix_socket=sock)
    else:
      db = mysql.connect(host=config['dbhost'], user=config['dbuser'], passwd=config['dbpassword'], db=config['dbname'])
  except:
    db = mysql.connect(host=config['dbhost'], user=config['dbuser'], passwd=config['dbpassword'], db=config['dbname'])
  # db.set_character_set('utf8')        # maybe for mysqldb only?
else:
  print("dbtype '"+config['dbtype']+"' not impl. Try 'mysql'", file=tty)
  sys.exit(1)

dbc = db.cursor()
dbc.execute('SET NAMES utf8;')
dbc.execute('SET CHARACTER SET utf8;')
dbc.execute('SET character_set_connection=utf8;')

oc_ = config['dbtableprefix'] or 'oc_'

def fetch_dict(cur, select, keyname, bind=[]):
  cur.execute(select)
  fields = [x[0] for x in cur.description]
  if not keyname in fields:
    raise ValueError("column "+keyname+" not in table "+tname)
  table = {}
  for row in cur.fetchall():
    rdict = dict(zip(fields, row))
    table[rdict[keyname]] = rdict
  return table

def fetch_table_d(cur, tname, keyname, what='*'):
  return fetch_dict(cur, "SELECT "+what+" from "+tname, keyname)

# oc_mounts = fetch_table_d(cur, oc_+'mounts', 'mount_point')

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
# top_sto="SELECT COUNT(fileid) AS fileid_c, storage FROM "+oc_+"filecache WHERE path LIKE 'files/%' AND fileid NOT IN ("+fileid_seen+") GROUP BY storage ORDER BY fileid_c DESC LIMIT 10"

all_outfile = re.sub('[^/]*$', 'files_fileids.out', fileid_file)        # different name in same folder.
ofd = open(all_outfile, "w")
total = 0

cmd="SELECT fileid,storage FROM "+oc_+"filecache WHERE path LIKE 'files/%'"
dbc.execute(cmd)
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

cmd="SELECT id, numeric_id FROM "+oc_+"storages"
dbc.execute(cmd)
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

