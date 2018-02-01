#! /usr/bin/python
#
# occ_checksum_check.py -- a script to check consistency of oc_filecache entries.
#
# (C) 2018 jw@owncloud.co
# Distribute under GPLv2 or ask.
#
# 2018-01-25, collecting code snippets
# 2018-01-29, jw: canonical() added.
# 2018-02-01, jw: utf-8 encoding fixes, use storage+path_hash instead of path, time output added.

from __future__ import print_function
import sys, os, io, re, time
import zlib, hashlib

verbose = False                 # set to true, to include full mount and cache entry dump on error.
try:
  tty = open("/dev/tty", "w")   # print directory names to user, even if stdot and stderr are redirected.
except:
  tty = sys.stderr

if sys.version_info.major < 3:
  # fix python2 have a compatible bytes() with two parameters.
  def bytes_utf8(tupl):
    return bytes(tupl)
  deb_deps="python-mysqldb or python-pymysql or python-mysql.connector"
else:
  def bytes_utf8(tupl):
    return bytes(tupl, 'utf-8')
  deb_deps="python3-mysqldb or python3-pymysql or python3-mysql.connector"


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
      raise ImportError("need one of (MySQLdb, pymysql, mysql.connector) e.g. from DEB packages ("+deb_deps+")")


if len(sys.argv) < 3:
  print("Usage: %s /srv/www/htdocs/owncloud/config/config.php pyh_tree_prefix" % sys.argv[0])
  print("\n\t phy_tree_prefix can be / for checking all users. Or use /USERNAME/files/... to restrict the check to a subtree")
  print("\n\t Note: pyh_tree_prefix is the physical path, not the view from within owncloud.")
  sys.exit(1)

tree_prefix = sys.argv[2]
time_csum = 0           # time spent computing checksums
time_db = 0             # time spent communitcaing with the database


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

def canonical(path):
  # os.path.abspath() almost gets it right.
  # in most cases it collapses leading slashes,
  # except that two are left around.
  p = os.path.abspath(path)
  if p[:2] == '//':
    return p[1:]
  return p

def find_mountpoint(table, path):
  # assmuming canonical keys in table, e.g. no trailing slashes.
  if path[:1] != '/': path = '/' + path         # assert loop termination
  if path[-1:] == '/': path = path[:-1]         # remove trailing shash, if any.
  while path != '':
    if path in table: return table[path]
    path = path.rsplit('/', 1)[0]
  return None

datadirectory = canonical(config['datadirectory'])
datadir_len = len(datadirectory)
if canonical(tree_prefix)[:datadir_len] != datadirectory:
  data_tree = canonical(datadirectory+'/'+tree_prefix)
else:
  data_tree = canonical(tree_prefix)
print("data_tree:", data_tree, file=tty)

# oc_mounts = fetch_table_d(dbc, oc_+'mounts', 'mount_point')
# same as above, but with added path column for root_id:
oc_mounts = fetch_dict(dbc, 'SELECT m.*, c.path as root_path FROM '+oc_+'mounts m LEFT JOIN '+oc_+'filecache c ON (m.root_id = c.fileid)', 'mount_point')
for m in oc_mounts.keys():       # make keys in oc_mounts canonical(paths). E.g. trailing '/' is removed.
  if m[:1] == '/':               # mountpoint written with leading slash.
    mc = canonical(m)
    if mc != m:
      oc_mounts[mc] = oc_mounts[m]
      del(oc_mounts[m])
  else:                          # mount point written relative. Does that happen?
    mc = canonical('/'+m)
    if mc != '/'+m:
      oc_mounts[mc[1:]] = oc_mounts[m]
      del(oc_mounts[m])

# print(find_mountpoint(oc_mounts, "/msrex/files/owncloud/Server Feature Demos/Demo - Multi-Link.mp4"))
# # {'mount_point': '/msrex/', 'root_id': 4L, 'user_id': 'msrex', 'id': 78L, 'storage_id': 2L}

def oc_checksum(path):
  file = io.open(path, "rb")
  buf = bytearray(1024*1024*4)
  a32_sum  = 1
  md5_sum  = hashlib.new('md5')
  sha1_sum = hashlib.new('sha1')

  while True:
    n = file.readinto(buf)
    if n == 0: break
    # must checksum in chunks, or python 2.7 explodes on a 20GB file with "OverflowError: size does not fit in an int"
    a32_sum = zlib.adler32(bytes(buf)[0:n], a32_sum)
    md5_sum.update(bytes(buf)[0:n])
    sha1_sum.update(bytes(buf)[0:n])
  file.close()

  sha1 = sha1_sum.hexdigest()
  md5  = md5_sum.hexdigest()
  a32  = "%08x" % (0xffffffff & a32_sum)
  return 'SHA1:'+sha1+' MD5:'+md5+' ADLER32:'+a32

def report(info, errfd=sys.stderr, logfd=sys.stdout):
  """ evaluate data returned from check_oc_filecache()
  """
  if info['err']:
    if verbose:
      print(str(info), file=errfd)
    else:
      pre = "E: "
      if 'cache' in info and 'fileid' in info['cache']:
        pre = pre+"fileid="+str(info['cache']['fileid'])+" "
      print(pre+(" | ".join(info['err'])), file=errfd)
    errfd.flush()
  else:
    print(str(info['cache']['fileid']), file=logfd)
    logfd.flush()

def check_oc_filecache(cur, path):
  global time_db, time_csum
  path = canonical(path)
  full_path = path
  info = { 'err':[], 'msg':[], 'path':path }
  if path[:datadir_len] != datadirectory:
    info['err'].append("file ignored, not inside config['datadirectory']: "+path)
  else:
    path = path[datadir_len:]                 # inside datadirectory.
    mount = find_mountpoint(oc_mounts, path)
    if mount is None:
      info['err'].append("file ignored, mount point not found in oc_mounts: "+ path)
    else:
      mount_point = canonical(mount['mount_point'])
      if path == mount_point:
        info['msg'].append("file mount")
        path = ''
      elif path[:len(mount_point)] == mount_point:
        info['msg'].append("dir mount")
        path = path[len(mount_point):]   # inside mountpoint
      else:
        info['err'].append("internal mount error: "+path+" "+str(mount))
        return info

      storage_id = mount['storage_id']            # do not recurse into files, we already had seen this storage_id earlier.
      # user_id = mount['user_id']
      # root_id = mount['root_id']                # things may be mounted deeper.
      info['mount'] = mount
      if path[:1] == '/':
        path = path[1:]                           # remove leading slashes, they are not stored in oc_filecache

      path_md5 = hashlib.new('md5', bytes_utf8(path))

      try:
        time_t0 = time.time()
        cur.execute("SELECT fileid,size,mtime,permissions,checksum FROM "+oc_+"filecache WHERE storage = %s AND path_hash = %s", (storage_id, path_md5.hexdigest()))
        row = cur.fetchone()
        time_db += time.time() - time_t0
      except Exception as e:
        info['err'].append("sql error: "+str(e)+" | info:"+str(info))
        return info

      if row is None:
        info['err'].append("oc_filecache entry is missing: "+path+" "+str(mount))
      else:
        cache = dict(zip(['fileid','size','mtime','permissions','checksum'], row))
        stat = os.stat(full_path)
        info['cache'] = cache
        mtime = str(int(stat.st_mtime))
        if cache['checksum'] is None:
          info['err'].append("checksum is NULL")
        elif cache['checksum'] == '':
          info['err'].append("checksum is empty")
        else:
          time_t0 = time.time()
          csum = oc_checksum(full_path)         # expensive. do this only if filecache has a checksum for us to compare with.
          time_csum += time.time() - time_t0

          if csum != cache['checksum']:
            info['err'].append("checksum mismatch: cache:"+cache['checksum']+"   \t\t\t\t      phys:"+csum)
        if str(cache['mtime']) != mtime:
          info['err'].append("mtime mismatch: cache:"+str(cache['mtime'])+" phys:"+mtime)
        if cache['size'] != stat.st_size:
          info['err'].append("size mismatch: cache:"+str(cache['size'])+" phys:"+str(stat.st_size))
  return info


## Caution: this FTW fails, if
##  - a folder 'files' orrurs in config['datadirectory']
##  - a userid is named 'files' :-)
#
if os.path.isdir(data_tree):
  for dirname, subdirs, files in os.walk(data_tree, topdown=True):
    print("t: %.1f+%.1fs, dir: %s" % (time_db, time_csum, dirname), file=tty)
    if "/files/" not in dirname+"/":
      files = []                    # ignore files above the files folder
      if  "files" in subdirs:
        subdirs[:] = ["files"]      # inplace mod to force entring files folder only.
    for file in files:
      path = dirname+'/'+file
      report(check_oc_filecache(dbc, path))
else:
  report(check_oc_filecache(dbc, data_tree))     # single file

