#! /usr/bin/python
#
# (C) 2018 jw@owncloud.com
# Distribute under GPLv2 or ask.
#
# 2018-02-02, jw V0.1: Refactored common code from occ_checksum_check.py and stale_filecache.py
# 2018-02-20, jw V0.2: Try 'occ config:list --private' before reading 'config/config.php'
#
from __future__ import print_function
import sys, os, io, re
import zlib, hashlib, json, subprocess
import time, datetime

###
## TODO: allow object store as primary storage
## Study: http://docs.ceph.com/docs/master/radosgw/s3/python/
# import boto
# conn = boto.connect_s3( AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY )
# image_bucket = conn.get_bucket( IMAGE_BUCKET )
# -> handle file access through an abstract OCFile class, doing both,
#    plain filesystem and object store.
# -> oc_filecache:fileid -> maps to "urn:oid:<fileid>" in the bucket.
###


if sys.version_info.major < 3:
  # fix python2 have a compatible bytes() with two parameters.
  def _bytes_utf8(tupl):
    return bytes(tupl)
else:
  def _bytes_utf8(tupl):
    return bytes(tupl, 'utf-8')


class OCC():
  """
  tools for ownCloud. This class implements functions that are also present
  or should/could be present in the owncloud/occ.php class.
  """
  def __init__(self, verbose=False, config=None):
    self._config = {}
    self._confs = None	# shorthand for _config['system']
    self._config_file = None
    self._verbose = verbose
    self._oc_mounts = None
    self._db = None
    self._db_cursor = None
    self.oc_ = 'oc_'    # dbtableprefix

  def dbtableprefix(self):
    """
    Returns the dbtableprefix to be used when constructing SQL statements.
    This is also available as member variable oc_ for convenience.
    """
    return self._confs.get('dbtableprefix', 'oc_')

  def parse_config_json(self, home):
    """
    find owner of the occ command,
    try to sudo or su into that user,
    call occ config:list --private
    or as a fallback occ config:list

    This requires a somewhat healthy owncloud server that is able to run php.
    The result is returned as a dict.
    """

    occ_cmd = home+"/occ"
    from pwd import getpwuid
    try:
      st = os.stat(home+"/config/config.php")   # much better stat this, if we can
    except:
      st = os.stat(occ_cmd)                     # lousy fallback, if we cannot read the config.php

    user = getpwuid(st.st_uid).pw_name 	# "www-data"

    if os.geteuid() == st.st_uid:
      if self._verbose: print("... trying to run 'occ config:list'")
      cmds = [
        [ "php", occ_cmd, "config:list", "--private" ],
        [ "php", occ_cmd, "config:list" ],
        [ occ_cmd, "config:list", "--private" ],
        [ occ_cmd, "config:list" ]
      ]
    else:
      if self._verbose: print("... trying to run 'occ config:list' as user %s" % (user))
      cmds = [	# one of these should work:
        [ "sudo", "-u", user, "php", occ_cmd, "config:list", "--private" ],
        [ "su",   user, "-c", "php "+occ_cmd+" config:list --private" ],
        [ "sudo", "-u", user, "php", occ_cmd, "config:list" ],
        [ "su",   user, "-c", "php "+occ_cmd+" config:list" ],
        [ "sudo", "-u", user, occ_cmd, "config:list", "--private" ],
        [ "su",   user, "-c", occ_cmd+" config:list --private" ],
        [ "sudo", "-u", user, occ_cmd, "config:list" ],
        [ "su",   user, "-c", occ_cmd+" config:list" ]
      ]
    e0 = None
    ee = None
    outtext = ""
    errtext = ""
    for cmd in cmds:
      if self._verbose: print(" + ", cmd)         # say something, in case the process hangs.
      try:
        p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, stdin=subprocess.PIPE, close_fds=True)
        (outtext, errtext) = p.communicate()
        if len(errtext):
          raise ValueError("STDERR("+" ".join(cmd)+"): "+errtext)
        else:
          if len(outtext.strip()):
            break
      except Exception as e:
        print("Retryable exception: ", e)
        if len(outtext.strip()):
          print("cmd: ", cmd)
          print(outtext)
          sys.exit(1)
        if e0 is None: e0 = e
        ee = e
    if len(outtext.strip()):
      try:
        return json.loads(outtext)
      except Exception as e:
        e.args += ( "Unparsable json output: ", outtext )
        if e0 is None: e0 = e
        ee = e
    if ee == e0:
      raise ValueError(repr(ee)+"\n"+repr(outtext)+"\n"+repr(errtext))
    else:
      raise ValueError(repr(e0)+"\n"+repr(ee)+"\n"+repr(outtext)+"\n"+repr(errtext))


  def parse_config_file(self, file):
    """
    Parse an owncloud config.php file. The parser here is a simple minded regexp parser and expects
    one key value pair per line like this:

      'datadirectory' => '/var/oc-data',

    Items using other fancy syntax are silently skipped.
    This parser should be avoided in favour of parse_config_json().
    The result is returned as a dict.
    """
    config = {}
    with open(file) as cfg:
      for line in cfg:
        if "'objectstore'" in line:
          raise ValueError("Found complex 'objectstore' in "+file+" - The trivial regexp parser cannot do that. Need parse_config_json().")
        for m in re.finditer('(["\'])(.*?)\\1\s*=>\s*((["\'])(.*?)\\1|([\w]+))\s*,', line):
          # m = ("'", 'memcache.local', "'\\OC\\Memcache\\Redis'", "'", '\\OC\\Memcache\\Redis', None)
          # m = ("'", 'port', '6379', None, None, '6379')
          config[m.group(2)] = m.group(5) or m.group(6)
    return config

  def load_config(self, oc_home):
    """
    Loads the owncloud server configuration using parse_config_file().
    Also returns the result as a dict.
    """
    oc_home = re.sub("/config/config\.php$", "", oc_home)	# backwards compat
    configfile = "occ config:list"
    try:
      self._config = self.parse_config_json(oc_home)
    except ValueError as e:
      configfile = oc_home+"/config/config.php"
      try:
        self._config = { 'system': self.parse_config_file(configfile) }
      except Exception as e2:
        print("parse_config_json: ", e, "\nparse_config_file: ", e2)
        sys.exit(1)
    self._confs = self._config['system']
    self._config_file = configfile
    self.oc_ = self.dbtableprefix()
    return self._config

  def mtime_objectstore(self, o_mtime):
    """
    This silly objectstore here returns a last_modified time as string
    '2018-02-20T15:44:55.462Z' instead of 1519137895.462 (epoch)
    Here is the conversion function for this string.
    Returns seconds since the epoch.
    It is unclear if the result should be rounded or truncated for comparison with a oc_filecache mtime.
    """
    dt = datetime.datetime.strptime(o_mtime, '%Y-%m-%dT%H:%M:%S.%fZ')
    ## truncated:
    return int(time.mktime(dt.timetuple()))
    # epoch = time.mktime(dt.timetuple())+0.000001*dt.microsecond
    # ## rounded:
    # return int(epoch+.5)
    # ## float:
    # return epoch


  def has_primary_objectstore(self):
    """
    predicate to check if the Primary storage is an object store
    Returns True if yes.
    Returns False otherwise. A plain filesystem is assumend then.
    """
    return 'objectstore' in self._confs

  def bucket_objectstore(self):
    cfg = self._confs['objectstore']['arguments']
    opt = cfg['options']
    host = opt['endpoint']
    https = False
    port = 80
    if host.startswith('https://'):
      host = host[8:]
      https = True
      port = 443
    elif host.startswith('http://'):
      host = host[7:]
      https = False
      port = 80

    path = '/'
    m = re.match('^([^/]+)(/.*)', host)
    if m:
      host = m.group(1)
      path = m.group(2)
    m = re.match('^([^:]+):(\d+)', host)
    if m:
      host = m.group(1)
      port = int(m.group(2))

    # print(cfg)
    try:
      import boto
      conn = boto.connect_s3(
          opt['credentials']['key'],
          opt['credentials']['secret'],
          host=host, port=port, is_secure=https
        )
      conn.calling_format = boto.s3.connection.OrdinaryCallingFormat()
      # print(conn.get_all_buckets())
      return conn.get_bucket(cfg['bucket'])
    except Exception as e:
      e.args += ('boto.connect_s3()', host, port, path, https, "try 'apt-get install python-boto'")
      print(repr(e))
    return None


  def db_connect(self):
    if self._confs['dbtype'] == 'mysql':

      if sys.version_info.major < 3:
        deb_deps="python-mysqldb or python-pymysql or python-mysql.connector"
      else:
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
            raise ImportError("need one of the python mysql bindings. E.g. from DEB packages ("+deb_deps+")")

      m = re.match("(.*):(\d+)$", self._confs['dbhost'])
      dbport = None
      if m:
        dbhost = m.group(1)
        dbport = int(m.group(2))
      else:
        dbhost = self._confs['dbhost']

      # any of MySQLdb, python oe mysql.connector work with this API:
      try:
        sock='/var/run/mysql/mysql.sock'
        if os.path.exists(sock) and dbhost == 'localhost' and dbport is None:
          # pymysql does not try the unix domain socket, if tcp port 3306 is closed.
          self._db = mysql.connect(host=dbhost, user=self._confs['dbuser'], passwd=self._confs['dbpassword'], db=self._confs['dbname'], unix_socket=sock)
        else:
          if dbport is None:
            self._db = mysql.connect(host=dbhost, user=self._confs['dbuser'], passwd=self._confs['dbpassword'], db=self._confs['dbname'])
          else:
            self._db = mysql.connect(host=dbhost, user=self._confs['dbuser'], passwd=self._confs['dbpassword'], db=self._confs['dbname'], port=dbport)
      except:
        if dbport is None:
          self._db = mysql.connect(host=self._confs['dbhost'], user=self._confs['dbuser'], passwd=self._confs['dbpassword'], db=self._confs['dbname'])
        else:
          self._db = mysql.connect(host=self._confs['dbhost'], user=self._confs['dbuser'], passwd=self._confs['dbpassword'], db=self._confs['dbname'], port=dbport)

      # self._db.set_character_set('utf8')        # maybe for mysqldb only?
      return self._db

    elif self._confs['dbtype'] == 'sqlite3':

      if sys.version_info.major < 3:
        deb_deps="libpython2.7-stdlib"
      else:
        deb_deps="libpython3.5-stdlib"
      sqlite3_file = self._confs['datadirectory']+"/owncloud.db"
      if not os.path.exists(sqlite3_file):
        print("SQLITE3 ERROR opening ", sqlite3_file, "\nTry starting with sudo -u www-data ... ?")
        sys.exit(1)

      try:
        import sqlite3
      except:
        raise ImportError("need one of the python sqlite3 bindings. E.g. from DEB packages ("+deb_deps+")")

      self._db = sqlite3.connect(sqlite3_file)
      return self._db

    raise ValueError("dbtype '"+self._confs['dbtype']+"' not impl. Try 'mysql'")

  def db_execute(self, cmd, bind=()):
    dbc = self.db_cursor()
    if self._confs['dbtype'] == 'sqlite3':
      if cmd[:4].lower() == 'set ': return None
      cmd = re.sub("\s%s(\s|$)", " ? ", cmd)    # sqlite3 driver does not understand = %s syntax. Fall back to '?'.
    if self._verbose: print("db_execute: ", cmd, bind)
    return dbc.execute(cmd, bind)


  def db_cursor(self):
    if self._db_cursor is not None:
      return self._db_cursor

    if self._db is None:
      self.db_connect()
    dbc = self._db_cursor = self._db.cursor()
    self.db_execute('SET NAMES utf8;')
    self.db_execute('SET CHARACTER SET utf8;')
    self.db_execute('SET character_set_connection=utf8;')
    return dbc

  def canonical_path(self, path):
    """
    Removes redundant slashes and dots from path.
    Resolves backtracking to parent path components.
    Same as os.path.abspath, except that we never return a path starting with '//'.
    """
    # os.path.abspath() almost gets it right.
    # in most cases it collapses leading slashes,
    # except that two are left around.
    p = os.path.abspath(path)
    if p[:2] == '//':
      return p[1:]
    return p

  def db_fetch_dict(self, select, keyname, bind=[]):
    self.db_execute(select)
    cur = self.db_cursor()
    fields = [x[0] for x in cur.description]
    if not keyname in fields:
      raise ValueError("column "+keyname+" not in table "+tname)
    table = {}
    for row in cur.fetchall():
      rdict = dict(zip(fields, row))
      table[rdict[keyname]] = rdict
    return table


  def filecache(self, fileid=None, storage=None, path=None, path_md5=None):
    """
    Efficiently lookup a filecache entry, using either
    - fileid              (should be the primary key on the table)
    or
    - storage + path_hash (which is an extra index on the table)
    or
    - storage + path      (where path is converted to path_hash using md5)

    The filecache entry is returned as a dict with keys 'fileid','size','mtime','permissions','checksum'.
    In case the lookup was by fileid, the fields 'path' and 'path_hash' are also present.
    """
    cur = self.db_cursor()
    if path is not None:
      path_md5 = hashlib.new('md5', _bytes_utf8(path))

    if fileid is not None:
      self.db_execute("SELECT fileid,size,mtime,permissions,checksum,path,path_hash FROM "+self.oc_+"filecache WHERE fileid = %s", (fileid,))
      fields = ['fileid','size','mtime','permissions','checksum','path','path_hash']
    elif storage is not None and path_md5 is not None:
      self.db_execute("SELECT fileid,size,mtime,permissions,checksum FROM "+self.oc_+"filecache WHERE storage = %s AND path_hash = %s", (storage, path_md5.hexdigest()))
      fields = ['fileid','size','mtime','permissions','checksum']
    else:
      raise ValueError("filecache lookup needs fileid or storage+path or storage+path_md5")
    row = cur.fetchone()
    if row is None:
      return None
    return dict(zip(fields, row))

  def db_fetch_mounts(self):
    """
    Cache the contents of the database table oc_mounts for later use with e.g. find_mountpoint()
    Needs a database cursor as parameter. You can get one by calling db_connect() and db_cursor().
    """
    dbc = self._db_cursor
    self._oc_mounts = self.db_fetch_dict('SELECT m.*, c.path as root_path FROM '+self.oc_+'mounts m LEFT JOIN '+self.oc_+'filecache c ON (m.root_id = c.fileid)', 'mount_point')
    for m in self._oc_mounts.keys():       # make keys in oc_mounts canonical_path(paths). E.g. trailing '/' is removed.
      if m[:1] == '/':               # mountpoint written with leading slash.
        mc = self.canonical_path(m)
        if mc != m:
          self._oc_mounts[mc] = self._oc_mounts[m]
          del(self._oc_mounts[m])
      else:                          # mount point written relative. Does that happen?
        mc = self.canonical_path('/'+m)
        if mc != '/'+m:
          self._oc_mounts[mc[1:]] = self._oc_mounts[m]
          del(self._oc_mounts[m])


  def find_mountpoint(self, path):
    """
    walk backwards through a given filesystem path
    until we find a matching entry in the oc_mounts table.
    This implicitly calls db_fetch_mounts() if not previously called to
    obtain a cached copy of the oc_mounts table from the database.

    # print(find_mountpoint(oc_mounts, "/jw/files/owncloud/Demos/Demo.mp4"))
    # # {'mount_point': '/jw/', 'root_id': 4L, 'user_id': 'jw', 'id': 78L, 'storage_id': 2L}
    """
    if self._oc_mounts is None:
      self.db_fetch_mounts()

    # assmuming canonical keys in self._oc_mounts, e.g. no trailing slashes.
    if path[:1] != '/': path = '/' + path         # assert loop termination
    if path[-1:] == '/': path = path[:-1]         # remove trailing shash, if any.
    while path != '':
      if path in self._oc_mounts: return self._oc_mounts[path]
      path = path.rsplit('/', 1)[0]
    return None

  def oc_checksum(self, path, bufsize=1024*1024*4):
    """
    Returns a checksum string as introduced in oc_filecache with version 10.0.4
    The code reads the file in chunks of bufsize once and does all needed computations
    on the fly. Linear cpu usage with filesize, but constant memory.
    """
    file = io.open(path, "rb")
    buf = bytearray(bufsize)
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

  def oc_checksum_objectstore(self, bucket, name):
    """
    Returns a checksum string as introduced in oc_filecache with version 10.0.4
    The code reads chunks from the objectstore and does all needed computations
    on the fly. Linear cpu usage with filesize, but constant memory.
    """
    a32_sum  = 1
    md5_sum  = hashlib.new('md5')
    sha1_sum = hashlib.new('sha1')

    for buf in bucket.lookup(name):
      # must checksum in chunks, or python 2.7 explodes on a 20GB file with "OverflowError: size does not fit in an int"
      a32_sum = zlib.adler32(buf, a32_sum)
      md5_sum.update(buf)
      sha1_sum.update(buf)

    sha1 = sha1_sum.hexdigest()
    md5  = md5_sum.hexdigest()
    a32  = "%08x" % (0xffffffff & a32_sum)
    return 'SHA1:'+sha1+' MD5:'+md5+' ADLER32:'+a32



if __name__ == '__main__':
  pass
