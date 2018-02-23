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
# 2018-02-02, jw. Refactored into lib/owncloud.py
# 2018-02-23, jw. initial objectstore check done: potential issues seen:
#                mtimes are often off by a few seconds!
#                files_version/ often have no checksum!

from __future__ import print_function
import sys, os, re, time
from lib.owncloud import OCC

verbose=False                   # set to true, to include full mount and cache entry dump on error.
oc = OCC(verbose=verbose)

try:
  tty = open("/dev/tty", "w")   # print directory names to user, even if stdot and stderr are redirected.
except:
  tty = sys.stderr

if len(sys.argv) < 3:
  print("Usage: %s /srv/www/htdocs/owncloud pyh_tree_prefix" % sys.argv[0], file=tty)
  print("\n\t phy_tree_prefix can be / for checking all users. Or use /USERNAME/files/... to restrict the check to a subtree", file=tty)
  print("\n\t Note: pyh_tree_prefix is the physical path, not the view from within owncloud.", file=tty)
  sys.exit(1)

config = oc.load_config(sys.argv[1])

tree_prefix = sys.argv[2]
time_csum = 0           # time spent computing checksums
time_db = 0             # time spent communitcaing with the database

try:
  dbc = oc.db_cursor()
except ImportError as e:
  print("ImportError:", e)
  sys.exit(1)

def fetch_table_d(tname, keyname, what='*'):
  return oc.db_fetch_dict("SELECT "+what+" from "+tname, keyname)

def report(info, errfd=sys.stderr, logfd=sys.stdout):
  """ evaluate data returned from check_oc_filecache_*()
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

def check_oc_filecache_path(cur, path):
  global time_db, time_csum
  path = oc.canonical_path(path)
  full_path = path
  info = { 'err':[], 'msg':[], 'path':path }
  if path[:datadir_len] != datadirectory:
    info['err'].append("file ignored, not inside config['datadirectory']: "+path)
  else:
    path = path[datadir_len:]                 # inside datadirectory.
    mount = oc.find_mountpoint(path)
    if mount is None:
      info['err'].append("file ignored, mount point not found in oc_mounts: "+ path)
    else:
      mount_point = oc.canonical_path(mount['mount_point'])
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

      time_t0 = time.time()
      try:
        cache = oc.filecache(storage=storage_id, path=path)
      except Exception as e:
        info['err'].append("sql error: "+repr(e)+" | info:"+str(info))
        return info
      time_db += time.time() - time_t0
      if cache is None:
        info['err'].append("oc_filecache entry is missing: "+path+" "+str(mount))
      else:
        stat = os.stat(full_path)
        info['cache'] = cache
        mtime = str(int(stat.st_mtime))
        if cache['checksum'] is None:
          info['err'].append("checksum is NULL")
        elif cache['checksum'] == '':
          info['err'].append("checksum is empty")
        else:
          time_t0 = time.time()
          csum = oc.oc_checksum(full_path)     # expensive. do this only if filecache has a checksum for us to compare with.
          time_csum += time.time() - time_t0

          if csum != cache['checksum']:
            info['err'].append("checksum mismatch: cache:"+cache['checksum']+"   \t\t\t\t      phys:"+csum)
        try:
          cache_mtime = int(cache['mtime'])
        except:
          cache_mtime = -1
        if cache_mtime != mtime:
          days_off = (cache_mtime-mtime)/3600./24
          info['err'].append("mtime mismatch: cache:%s phys:%d off=%.1fd" % (str(cache['mtime']), mtime, days_off))
        if cache['size'] != stat.st_size:
          info['err'].append("size mismatch: cache:"+str(cache['size'])+" phys:"+str(stat.st_size))
  return info

def check_oc_filecache_id(cur, bucket, fileid, o_size, o_mtime):
  global time_db, time_csum
  info = { 'err':[], 'msg':[], 'path':None }
  time_t0 = time.time()
  try:
    cache = oc.filecache(fileid=fileid)
  except Exception as e:
    info['err'].append("sql error: "+repr(e)+" | info:"+str(info))
    return info
  time_db += time.time() - time_t0
  if cache is None:
        info['err'].append("oc_filecache entry is missing: "+path+" "+str(mount))
  else:
        info['cache'] = cache
        mtime = str(o_mtime)
        if cache['checksum'] is None:
          if cache['path'][:6] == 'files/':
            # thumbnails/, files_version/, upload/ have NULL checksum.
            # BUMMER: files_version/ should have checksums!
            info['err'].append("checksum is NULL")
        elif cache['checksum'] == '':
          info['err'].append("checksum is empty")
        else:
          time_t0 = time.time()
          csum = oc.oc_checksum_objectstore(bucket, 'urn:oid:'+str(fileid))
          time_csum += time.time() - time_t0
          if csum != cache['checksum']:
            info['err'].append("checksum mismatch: cache:"+cache['checksum']+"   \t\t\t\t      phys:"+csum)
        o_mtime_epoch = oc.mtime_objectstore(o_mtime)
        try:
          cache_mtime = int(cache['mtime'])
        except:
          cache_mtime = -1
        if cache_mtime != o_mtime_epoch:
          if o_mtime_epoch < cache_mtime or (o_mtime_epoch - 4) > cache_mtime:
            # BUMMER: objectstore mtimes are usually a few seconds behind. why that???
            days_off = (cache_mtime-o_mtime_epoch)/3600./24
            info['err'].append("mtime mismatch: cache:%s phys:%s[%d] off=%.1fd" % (cache['mtime'], o_mtime, o_mtime_epoch, days_off))
        if cache['size'] != o_size:
          info['err'].append("size mismatch: cache:"+str(cache['size'])+" phys:"+str(o_size))
  return info


if oc.has_primary_objectstore():
  unk_name_count = 0
  done_list = set()
  # No file tree walk needed here, the objectstore is flat.
  # FIXME: username is ignored, if specified.
  #
  # Algorithm:
  # We enumerate all objects in the objectstore, for each
  #   and lookup the the fileid in the oc_filecache table.
  #   if found,
  #           add the fileid to the done_list.
  #           Calculate the oc_checksum.
  #           Compare the checksums and report good or bad.
  # We enumerate all oc_filecache entries that have an
  # oc_storage id starting with object::store: or object::user:
  #    all fileids not in the done-list are reported as orphaned.
  #
  obst = oc.bucket_objectstore()
  for k in obst.list():
    m = re.match('^urn:oid:(\d+)$', k.name)
    if not m:
      if unk_name_count == 0:
        print("ERROR: unknown name schema in objectstore: '%s' expected: 'urn:oid:NNNN'" % k.name)
      unk_name_count += 1
      continue

    fileid = int(m.group(1))
    # print("%20s %10s %d" % (k.last_modified, k.size, fileid))
    result = check_oc_filecache_id(dbc, obst, fileid, k.size, k.last_modified)
    if 'cache' in result: done_list.add(fileid)
    report(result)

  # print("len(done_list) = ", len(done_list))
  cur = oc.db_cursor()
  cur.execute("SELECT id FROM oc_mimetypes WHERE mimetype LIKE 'httpd%'")
  dirtypes = []		# oc_mimetype: httpd, httpd/unix-directory
  for row in cur.fetchall():
    dirtypes.append(row[0])
  dirtypes = ','.join(map(lambda x: str(x), dirtypes))
  cur.execute("SELECT fileid FROM "+oc.oc_+"filecache WHERE mimetype NOT IN ("+dirtypes+")")
  for row in cur.fetchall():
    if row[0] not in done_list:
      print("E: fileid=%d not in objectstore" % row[0], file=sys.stderr)

else:

  # Prepare for a file-tree-walk
  ##############################
  # assume it is a mounted linux filesystem.
  datadirectory = oc.canonical_path(config['system']['datadirectory'])
  datadir_len = len(datadirectory)
  if oc.canonical_path(tree_prefix)[:datadir_len] != datadirectory:
    data_tree = oc.canonical_path(datadirectory+'/'+tree_prefix)
  else:
    data_tree = oc.canonical_path(tree_prefix)
  print("data_tree:", data_tree, file=tty)

  # do the file-tree-walk
  #######################
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
        report(check_oc_filecache_path(dbc, path))
  else:
    report(check_oc_filecache_path(dbc, data_tree))     # single file

