#! /usr/bin/python
#
# occ_checksum_check.py -- a script to check consistency of oc_filecache entries.
#
# (C) 2018 jw@owncloud.co
# Distribute under GPLv2 or ask.
#
# 2018-01-25, collecting code snippets
#

from __future__ import print_function
import sys, os, re
import zlib, hashlib
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
  print("Usage: %s path/to/config.php tree_prefix" % sys.argv[0])
  print("\n\t tree_prefix can be / for checking all users. Or use /USERNAME/files/... to restrict the check to a subtree")
  sys.exit(1)

tree_prefix = sys.argv[2]
if tree_prefix[:1] != '/':
  tree_prefix = '/'+tree_prefix

## hackey parser for config.php
config = {}
for line in open(sys.argv[1]):
  for m in re.finditer('(["\'])(.*?)\\1\s*=>\s*((["\'])(.*?)\\1|([\w]+))\s*,', line):
    # m = ("'", 'memcache.local', "'\\OC\\Memcache\\Redis'", "'", '\\OC\\Memcache\\Redis', None)
    # m = ("'", 'port', '6379', None, None, '6379')
    config[m.group(2)] = m.group(5) or m.group(6)

# any of MySQLdb, python oe mysql.connector work with this API:
db = mysql.connect(host=config['dbhost'], user=config['dbuser'], passwd=config['dbpassword'], db=config['dbname'])
oc_ = config['dbtableprefix'] or 'oc_'

def fetch_table_d(cur, tname, keyname, what='*'):
  cur.execute("SELECT "+what+" from "+tname);
  fields = [x[0] for x in cur.description]
  if not keyname in fields:
    raise ValueError("column "+keyname+" not in table "+tname)
  table = {}
  for row in cur.fetchall():
    rdict = dict(zip(fields, row))
    table[rdict[keyname]] = rdict
  return table

def find_mountpoint(table, path):
  if path[:1] != '/': path = '/' + path         # assert loop termination
  if path[-1:] != '/': path = path + '/'
  while path != '/':
    if path in table: return table[path]
    path = path.rsplit('/', 2)[0]+'/'
  return None


cur = db.cursor()
oc_mounts = fetch_table_d(cur, oc_+'mounts', 'mount_point')
print(find_mountpoint(oc_mounts, "/anne/files/Mitgliedsdat/foo.txt"))
print(find_mountpoint(oc_mounts, "/anne/files/Mitgliedsdaten/foo.txt"))
print(find_mountpoint(oc_mounts, "/anne/files"))
print(find_mountpoint(oc_mounts, "anne"))
print(find_mountpoint(oc_mounts, ""))

sys.exit(1)

cur.execute("SELECT storage,path,checksum from "+oc_+"filecache where name = 'Paris.jpg'")
for row in cur.fetchall():
  print(row)
db.close()

sys.exit(1)

data_tree = config['datadirectory']+tree_prefix
print("data_tree:", data_tree)

def oc_checksum(path):
  body = open(path).read()
  sha1 = hashlib.sha1(body).hexdigest()
  md5  = hashlib.md5(body).hexdigest()
  a32  = "%08x" % zlib.adler32(body)
  return 'SHA1:'+sha1+' MD5:'+md5+' ADLER32:'+a32


## Caution: this FTW fails, if
##  - a folder 'files' orrurs in config['datadirectory']
##  - a userid is named 'files' :-)
#
for dirname, subdirs, files in os.walk(data_tree, topdown=True):
  print("dir: ", dirname)
  if "/files/" not in dirname:
    files = []                    # ignore files above the files folder
    if  "files" in subdirs:
      subdirs[:] = ["files"]      # inplace mod to force entring files folder only.
  for file in files:
    print("  file: ", file, "csum: ", oc_checksum(dirname+'/'+file))


