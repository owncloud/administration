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
  print("Usage: %s /srv/www/htdocs/owncloud/config/config.php pyh_tree_prefix" % sys.argv[0], file=tty)
  print("\n\t phy_tree_prefix can be / for checking all users. Or use /USERNAME/files/... to restrict the check to a subtree", file=tty)
  print("\n\t Note: pyh_tree_prefix is the physical path, not the view from within owncloud.", file=tty)
  sys.exit(1)

config = oc.load_config(sys.argv[1])
tree_prefix = sys.argv[2]
time_csum = 0           # time spent computing checksums
time_db = 0             # time spent communitcaing with the database

dbc = oc.db_cursor()

def fetch_table_d(tname, keyname, what='*'):
  return oc.db_fetch_dict("SELECT "+what+" from "+tname, keyname)

datadirectory = oc.canonical_path(config['datadirectory'])
datadir_len = len(datadirectory)
if oc.canonical_path(tree_prefix)[:datadir_len] != datadirectory:
  data_tree = oc.canonical_path(datadirectory+'/'+tree_prefix)
else:
  data_tree = oc.canonical_path(tree_prefix)
print("data_tree:", data_tree, file=tty)


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
        info['err'].append("sql error: "+str(e)+" | info:"+str(info))
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

