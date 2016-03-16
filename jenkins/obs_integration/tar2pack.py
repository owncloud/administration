#! /usr/bin/python
#
# (C) 2016 jw@owncloud.com
#
# tar2package.py automates package generation for the openbuildservice.
# It populates a folder (named after the pakcage PACKNAME) with downloaded tar archive and 
# metadata generated from the templates.
#
# The tar  archive name is parsed to derive several template variables:
#  PACKNAME VERSION PRERELEASE
# All (other) variables can be overwritten with -d option.
# 
# Intended usage:
#
# osc co ce:9.0 owncloud-files
# osc co ce:9.0 owncloud
# cd ce:9.0:testing
# tar2pack.py http://download.owncloud.org/community/owncloud-9.0.0RC1.tar.bz2 -d PACKNAME=owncloud-files
# tar2pack.py http://download.owncloud.org/community/owncloud-9.0.0RC1.tar.bz2
# (cd owncloud-files; osc addremove; osc ci)
# (cd owncloud; osc addremove; osc ci)

# Requires: python, wget, svn
#
#
# 2016-03-14: Version 0.1  jw@owncloud: unfinished draft.



import sys, time, argparse, subprocess, os, re, tempfile, shutil

argv0 = 'obs_integration/tar2pack.py'
def_template_dir = 'http://github.com/owncloud/administration/tree/master/jenkins/obs_integration/templates'

# Keep in sync with obs-new-tar.py internal_tar2obs.py obs_docker_install.py
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


ap=argparse.ArgumentParser(description='deb/rpm package generator, using a tar-archive and templates. The result is written to a subdirectory named after the variable PACKNAME')
ap.add_argument('url', type=str, help="tar archive (file or) url to put into this package")
ap.add_argument('-d', '--define', action="append", metavar="KEY=VALUE", help="Specify name=value for template variables. Default: derive from url")
ap.add_argument('-n', '--name', metavar="PACKNAME", help="same as -d PACKNAME=... This defines the name of the.")
ap.add_argument('-t', '--template-dir', metavar="TEMPLATE-DIR", default=def_template_dir, help="directory where templates are. Also supports a github repository URL or '../tree/master/..' subdirectory URL")
ap.add_argument('-v', '--verbose', action='store_true', help="Be more verbose. Default: quiet")
args=ap.parse_args()
print args

verbose = args.verbose
define = {}
if args.name: args.define.append("PACKNAME=" + args.name)

for d in args.define:
  (key,val) = d.split('=')
  define[key] = val

# http://download.owncloud.org/community/owncloud-9.0.0RC1.tar.bz2
# ('http://download.owncloud.org/community/', 'owncloud', '9.0.0', 'rc1', 'tar.bz2', '.bz2')
#              1              2                  3          4   5
m = re.match(r'(.*/)?(.*?)[_-](\d[\d\.]*?)[\.~-]?([a-z]+\d+)?\.(tar(\.\w+)?|tgz|zip)$', args.url, flags=re.IGNORECASE)
if m:
  if not 'PACKNAME'   in define: define['PACKNAME']   = m.group(2)
  if not 'VERSION'    in define: define['VERSION']    = m.group(3)
  if not 'PRERELEASE' in define: define['PRERELEASE'] = m.group(4)
# print m.groups()

if not 'PRERELEASE' in define or define['PRERELEASE'] == None or define['PRERELEASE'] == '': 
  define['PRERELEASE'] = '%nil'

if not 'BUILDRELEASE_DEB' in define: define['BUILDRELEASE_DEB'] = '1'
if not 'VERSION_DEB' in define:
  version_deb = define['VERSION']
  if define['PRERELEASE'] != '%nil': version_deb = define['VERSION'] + '~' + define['PRERELEASE']
  define['VERSION_DEB'] = re.sub('-', '_', version_deb)

# automatic variables that cannot be overwritten:
define['VERSION_MM'] = re.sub(r'^([^\.]+\.[^\.]+).*$', "\g<1>", define['VERSION'])
define['SOURCE_TAR_URL'] = args.url

if verbose: print define

## find templates
template_base = args.template_dir
if re.match('^https?://', args.template_dir):
  # it is an url
  template_base = tempfile.mkdtemp(prefix='tar2pack_')
  if verbose: print args.template_dir, "->", template_base
  svn_url = re.sub('/tree/master/', '/trunk/', args.template_dir)
  svn_co = ['svn', 'co', '--non-interactive']
  if not verbose: svn_co.append('--quiet')
  run(svn_co + [svn_url, template_base])

template_dir = template_base
for d in (define['PACKNAME'], define['VERSION_MM'], define['VERSION'], 'v'+re.sub('\.', '_', define['VERSION'])):
  if verbose: print("try subdir "+d+" ... ")
  if os.path.isdir(template_dir + '/' + d):
    template_dir = template_dir + '/' + d
    if verbose: print(" -> OK.")
  else:
    if verbose: print(" -> not found.")

if verbose: print template_dir
for d in os.listdir(template_dir):
  if os.path.isdir(template_dir+'/'+d):
    print(template_dir + " is not a template directory: contains subdirectory '"+d+"'\n")
    exit(1)

outdir=define['PACKNAME']
## create destination directory if missing
if not os.path.isdir(outdir): os.mkdir(outdir)

## bring in the tar archive
newtarfile=args.url
newtarfile=re.sub(r'.*/',define['PACKNAME']+'/', args.url)
if re.search(r'://', args.url):
  r=run(["wget", args.url,"-O",newtarfile,"-nv"], redirect=False, return_code=True)
  if r: sys.exit()
else:
  try:
    shutil.copyfile(args.url, newtarfile)
  except shutil.SameFileError:
    pass

## clean out all old metafiles.
for file in os.listdir(outdir):
  if not re.search(r"\.(changes|changelog)$", outdir+'/'+file): continue
  if outdir+'/'+file != newtarfile: continue
  ## if file is listed as source in specfile: continue
  print("removing old "+file)
  unlink(outdir+'/'+file)


## set SOURCE_TAR_TOP_DIR (inspecting tar archive)
## refresh other sources listed in spec, if url specified

exit(0)
# CLEANUP
if re.match('https?://', args.template_dir): shutil.rmtree(template_base)

