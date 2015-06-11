#! /usr/bin/python
#
# obs-monitor.py - a simple tool to monitor multiple projects in one page.
#
# (c) 2015 jw@owncloud.com, distribute under GPL-2.0 or ask.
#
# 2015-06-11, v1.0, jw -- initial draft. But can already retrigger recursively
#
#
import argparse, subprocess, sys, os, re

verbose=0
def_apiurl="https://api.opensuse.org"
ap=argparse.ArgumentParser(description='Monitor build service results')
ap.add_argument('-r', '--retrigger-failed', action='store_true', help="Retrigger a build for all failed packages")
# ap.add_argument('-s', '--subprojects', action='store_true', help="also recurse into subprojects.")
ap.add_argument('-A', '--apiurl', help='the build service api to contact', default=def_apiurl)
ap.add_argument('proj', type=str, nargs='+', help="projects to monitor")
args=ap.parse_args()

# Keep in sync with internal_tar2obs.py obs_docker_install.py
def run(args, input=None, redirect=None, redirect_stdout=True, redirect_stderr=True, return_tuple=False, return_code=False, tee=False):
  """
     make the subprocess monster usable
  """

  if redirect is not None:
    redirect_stderr = redirect
    redirect_stdout = redirect

  if redirect_stderr:
    redirect_stderr=subprocess.PIPE
  else:
    redirect_stderr=sys.stderr

  if redirect_stdout:
    redirect_stdout=subprocess.PIPE
  else:
    redirect_stdout=sys.stdout

  in_redirect=""
  in_fd=None
  if input is not None:
    in_fd = subprocess.PIPE
    in_redirect=" (<< '%s')" % input

  if verbose: print "+ %s%s" % (args, in_redirect)
  p = subprocess.Popen(args, stdin=in_fd, stdout=redirect_stdout, stderr=redirect_stderr)
 
  (out,err) = p.communicate(input=input)

  if tee:
    if tee == True: tee=sys.stdout
    if out: print >>tee, " "+ out
    if err: print >>tee, " STDERROR: " + err

  if return_code:  return p.returncode
  if return_tuple: return (out,err,p.returncode)
  if err and out:  return out + "\nSTDERROR: " + err
  if err:          return "STDERROR: " + err
  return out

def list_subprojects(apiurl, proj):
  if not proj[-1] == ':': proj = proj + ':'	# assert trailing colon
  subs = []
  for prj in run(["osc", "-A"+apiurl, "ls"], redirect_stderr=False).split():
    if not re.match(re.escape(proj), prj): continue
    subs.append(prj)
  return subs 

def list_packages(apiurl, proj):
  return run(["osc", "-A"+apiurl, "ls", proj], redirect_stderr=False).split()
  
def list_packages_r(apiurl, proj):
  pkgs = map(lambda x: proj+'/'+x, list_packages(apiurl, proj))
  for prj in list_subprojects(apiurl, proj):
    pkgs.extend(map(lambda x: prj+'/'+x, list_packages(apiurl, prj)))
  return pkgs

def pkg_status(apiurl, proj_pack, ignore_re=None):
  """ construct proj_pack as project_name+'/'+package_name
  """
  st={}
  # dont use 'r -v' here.
  for line in run(["osc", "-A"+apiurl, "r", proj_pack], redirect_stderr=False).split('\n'):
    s = line.split(None, 2) 
    if len(s) < 3: continue
    if ignore_re is not None:
      if re.match(ignore_re, s[2]): continue
    st[s[0]+'/'+s[1]] = s[2]
  return st

success_re = r'(excluded|succeeded|\(unpublished\))'
mapped = {
  'good': [ 'disabled', 'excluded', 'succeeded', '(unpublished)',
  	    '*', 'disabled*', 'succeeded*' ]
}

ret={}
w=0
all_pkgs = list_packages_r(args.apiurl, args.proj[0])
for p in all_pkgs: 
  if len(p) > w: w=len(p)

for p in all_pkgs:
  st = pkg_status(args.apiurl, p, ignore_re=None)
  rstat = {}
  cnt = {}
  for k,v in st.items():
    for mkey in mapped:
      if v in mapped[mkey]: v = mkey
    if not v in rstat: rstat[v] = []
    if not v in cnt:   cnt[v] = 0
    rstat[v].append(k)
    cnt[v] +=1
  for retrigger in ['failed', 'unresolvable']:
    if retrigger in rstat:
      if not retrigger in ret: ret[retrigger] = 0
      ret[retrigger] += cnt[retrigger]

      if args.retrigger_failed:
        for target in rstat[retrigger]:
	  plat, arch = target.split('/') 
          print "\tretrigger", p, plat, arch
	  run(["osc", "-A"+args.apiurl, "rebuildpac", p, plat, arch], redirect=False)
  print "%-*s  %s" %(w,p, cnt)

print ret
