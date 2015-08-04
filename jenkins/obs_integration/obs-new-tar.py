#! /usr/bin/python
# Stuff tar balls from download url or local file into an obs package
#
# CAVEATS: 
# * this assumes, there is exactly one tar per package.
# * this assumes the owncloud way of macros in the specfile.

# Version 1.0: works in a working copy. 
# Version 1.1: RC capitalized correctly. owncloud not prefixed with owncloud. Email override.
# Version 1.2: added option --sr TARGETPRJ.
# Version 1.3: checking the tar ball to match the checkout name.
# Version 1.4: updating Source0: in the Specfiles.


import sys, time, argparse, subprocess, os, re

argv0 = 'obs_integration/obs-new-tar.py'
verbose=1
ap=argparse.ArgumentParser(description='obs package updater, run from a checked out working copy. Usually called from internal/update_all_tars.sh')
ap.add_argument('url', type=str, help="tar ball (file or) url to put into this package")
ap.add_argument('-c', '--commit', '--checkin', action='count', help="call 'osc ci' after updating the working copy")
ap.add_argument('-S', '--submitreq', '--sr', metavar='TARGETPRJ', help="call 'osc ci; osc submitreq TARGETPRJ' after updating the working copy")
ap.add_argument('-e', '--email', help="Specify maintainer email address. Default: derive from 'osc user'")
ap.add_argument('-n', '--name', help="Specify name (and version) Default: derive from url")

args=ap.parse_args()


if args.name:
  print("name(-version) specification not implemented.\n")
  sys.exit(0)

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

def parse_tarname(tarname, tarversion):
  """
    derive a package name from owncloud_enterprise_apps-6.0.6RC2.tar.bz2"
    and try to confirm the version number, 
    return the pkgname, a version and an optional prerelease string.
    E.g ('owncloud-enterprise-3rdparty', '6.0.9', 'beta')
  """
  pkg=None
  m = re.match("(.*)[-_\.]tar.*", tarname, re.I)
  if m: pkg=m.group(1)
  # beware Frank's creativity when naming tar balls.
  # owncloud-enterprise_apps_6_0_6RC2
  # owncloud-enterprise_apps
  m = re.match("(.*?)[-_](\d[\d\._]+)[-_~]?(\w.*?)?$", pkg)
  if m: (pkg,ver,pre) = m.groups()
  pkg = re.sub("_", "-", pkg)
  if pkg != 'owncloud' and not re.match('owncloud-.*', pkg):
    pkg = 'owncloud-'+pkg
  if ver is not None and tarversion is not None:
    if ver != tarversion and ver+pre != tarversion:
      if re.sub("[v\._]", "", tarversion) != re.sub("[\._-]", "", ver) and \
         re.sub("[v\._]", "", tarversion) != re.sub("[\._-]", "", ver+pre):
        print "WARNING: Version mismatch in tarname: %s (seen ver=%s, pre=%s, need %s)\n" % (tarname, ver, pre, tarversion)
	time.sleep(2)
      else:
        print "OK, %s ~ %s~%s" % (tarversion, ver, pre)
    else:
      print "YEAH, %s = %s~%s" % (tarversion, ver, pre)
  return (pkg, ver, pre)


def edit_specfile(specfile, data, tarurl):
  """
     open specfile, edit inplace for the given fields in data
     filed names need to be all lower case, not the way it really is in the specfile.

     Specfiles have a horrible syntax, that neither works well for human consumption nor
     for automated processing. We even tie into our private prerelease semantics
     and the base_version variable name is hardcoded. Live with it.
  """
  txt = open(specfile).read()
  txt = re.sub("^(Source0:\s+)(\S+)", "\g<1>"+tarurl, txt, flags=re.M)

  for item in data:
    item = item.lower()		# just an assertion.
    # print "%s should be %s" % (item, data[item])
    if item == "version":
      if re.search(  "^%define\s+base_version\s+", txt, flags=re.M):
        txt = re.sub("^(%define\s+base_version\s+)(\S+)", "\g<1>"+data[item], txt, flags=re.M)
      else:
        txt = re.sub("^(Version:\s+)(\S+)", "\g<1>"+data[item], txt, flags=re.M)
    else:
      if re.search(  "^%define\s+"+re.escape(item)+"\s+", txt, flags=re.M):
        txt = re.sub("^(%define\s+"+re.escape(item)+"\s+)(\S+)", "\g<1>"+data[item], txt, flags=re.M)
      else:
        ucfirst = item.capitalize()
        txt = re.sub("^("+re.escape(ucfirst)+":\s+)(\S+)", "\g<1>"+data[item], txt, flags=re.M)
  out=open(specfile, "w")
  out.write(txt)
  out.close()


def debian_version(data, buildrel=1):
  full_version = data['version']
  if "prerelease" in data and data['prerelease'] != '%nil': 
    pre = data['prerelease'].capitalize()
    pre = re.sub(r'^rc','RC', pre.lower(), re.I)	# re.I does not work???
    full_version += "~"+pre
  if buildrel is not None:
    full_version += "-" + str(buildrel)
  return full_version


def edit_changes(file, data, msg="Update to version %s"):
  """
    Prepend the most simplistic but syntactically correct debian changelog entry.
    No changelog body text.
    If an identical entry (except for the timestamp) is already there, 
    we just update the timestamp.
  """
  #                         Thu Jun  4 17:14:46 UTC 2015
  rpm_date = time.strftime("%a %b %e %H:%M:%S %Z %Y")
  msg = msg % debian_version(data, None)
  entry_fmt = """-------------------------------------------------------------------
%s - %s

- %s

"""
  entry = entry_fmt % (rpm_date, data['maintainer_email'], msg)
  txt = open(file).read()
  txt2 = re.sub(r'^.*\n','', txt)
  txt2 = re.sub(r'^.*\n','', txt2)	# cut away first 2 lines.
  ent2 = re.sub(r'^.*\n','', entry)
  ent2 = re.sub(r'^.*\n','', ent2)	# cut away first 2 lines.
  if txt2.startswith(ent2):
    txt = txt2[len(ent2):]
  txt = entry + txt
  out=open(file, "w")
  out.write(txt)
  out.close()


def edit_debchangelog(file, data, msg="Update to version %s"):
  """
    Prepend the most simplistic but syntactically correct debian changelog entry.
    No changelog body text.
    If an identical entry (except for the timestamp) is already there, 
    we just update the timestamp.
  """
  #                         "Tue, 02 Jun 2015 14:30:50 +0200"
  debian_date = time.strftime("%a, %d %b %Y %H:%M:%S %z")
  msg = msg % debian_version(data, None)
  entry = """%s (%s) stable; urgency=low

  * %s

 -- %s <%s>  """ % (data['name'], debian_version(data), msg, data['maintainer_name'], data['maintainer_email'])
  txt = open(file).read()

  if txt.startswith(entry):
    txt = txt[len(entry):]
    txt = re.sub(r'^.*','', txt)		# zap the timestamp
    txt = re.sub(r'^[\s*\n]*','', txt, re.M)	# zap leading newlines and whitespaces
  entry += debian_date + "\n\n"
  txt = entry + txt
  out=open(file, "w")
  out.write(txt)
  out.close()


def edit_dscfile(dscfile, data):
  """
     open *.dsc, edit inplace for the given fields in data
  """
  txt = open(dscfile).read()
  if "name" in data:
    txt = re.sub("^((Source|Binary):\s+)(\S+)", "\g<1>"+data['name'], txt, flags=re.M)
  if "version" in data:
    full_version = debian_version(data)
    txt = re.sub("^(Version:\s+)(\S+)", "\g<1>"+full_version, txt, flags=re.M)
  out=open(dscfile, "w")
  out.write(txt)
  out.close()

def parse_osc_user(data):
  """
    osc user
    jw: "Juergen Weigert" <jw@owncloud.com>
  """
  txt=run(["osc","user"],redirect=True)
  m = re.match(r'(.*?):\s"(.*?)"\s+<(.*?)>', txt)
  if m is None:
    print("Error: osc user failed.")
    sys.exit(0)
  data['logname'] = m.group(1)
  data['maintainer_name'] = m.group(2)
  data['maintainer_email'] = m.group(3)
  if args.email: data['maintainer_email'] = args.email

def addremove_tars(tarname):
  """ remove all tar balls except the named one
  """
  for file in os.listdir("."):
    if re.match(".*[\._-]tar.*", file):
      if file != tarname:
        run(["osc", "del", file], redirect=False)
  run(["osc", "add", tarname], redirect=False)

##################################################################

cwd = os.path.abspath('.')
# ['', 'home', 'testy', 'src', 'obs', 'isv', 'ownCloud', 'community', '7.0', 'testing', 'owncloud']
cwd_pkg = re.split('[:/]', cwd)[-1]
cwd_ver = re.split('[:/]', cwd)[-2]
cwd_testing = False
if cwd_ver == 'testing':
  cwd_testing = True
  cwd_ver = re.split('[:/]', cwd)[-3]
  print ":testing project seen here.\n"
else:
  print "non-testing project seen here.\n"

print(cwd, cwd_ver, cwd_testing)

run(["osc", "up"], redirect=False)

newtarfile=args.url
if re.search(r'://', args.url):
  newtarfile=re.sub(r'.*/','', args.url)
  r=run(["wget", args.url,"-O",newtarfile], redirect=False, return_code=True)
  if r: sys.exit()

tar = parse_tarname(newtarfile, None)
# ('owncloud-enterprise-3rdparty', '6.0.9', 'beta')
data = { 'name': tar[0], 'version': tar[1], 'prerelease':tar[2] }
if data['prerelease'] is None or data['prerelease'] == '': 
  data['prerelease'] = '%nil'
  if cwd_testing:
    print("You are trying to commit a final release into a testing project at %s\n" % cwd)
    sys.exit()
else:
  if not cwd_testing:
    print("You are trying to commit a testing release into a final project at %s\n" % cwd)
    sys.exit()
if data['name'] != cwd_pkg:
  print("You are trying to commit tar %s into a checkout of package '%s'\n" % (data['name'], cwd_pkg))
  sys.exit()

if os.path.exists('obs_check_deb_spec.sh'):
  run(["sh", "obs_check_deb_spec.sh"], redirect=False)


parse_osc_user(data)
edit_specfile(data['name']+".spec", data, args.url)
edit_dscfile(data['name']+".dsc", data)
edit_debchangelog("debian.changelog", data)
edit_changes(data['name']+".changes", data)
addremove_tars(newtarfile)

if args.commit or args.submitreq:
  if args.commit and args.commit > 1:
    msg = "Update to version %s via %s" % (debian_version(data, None), argv0)
    run(["osc", "ci", "-m", msg], redirect=False)
  else:
    run(["osc", "ci"], redirect=False)

  if args.submitreq:
    run(["osc", "submitreq", args.submitreq], redirect=False)
else:
  run(["osc", "diff"], redirect=False)

info=run(["osc", "info", "."], redirect=True)
src=re.search('Source URL:\s(.*)$', info, re.M)
dst=re.search('link to project\s([^,]*),', info, re.M)

print("Check the build results at %s\n" % re.sub('/source/', '/package/show/', src.group(1)))
if not args.commit: print(" ... after committing ...")
if args.submitreq: print(" ... and in %s after accepting the above request" % dst.group(1))
