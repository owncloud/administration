#!/usr/bin/python
#
# (c) 2014,2015 jw@owncloud.com
# Distribute under GPLv2 or ask.
#
# obs_docker_install.py -- prepare a docker image with owncloud packages
# V0.1 -- jw    initial draught, with APT only.
# V0.2 -- jw    support for extra-packages added, support for YUM, ZYPP added.
#               support debian packages without release number
# V0.3 -- jw    updated run() to capture exit code, fixed X11 connection via unix:0
#               added --quiet option and run.verbose.
#               added --exec command introducer with simple shell meta char recognition
# V0.4 -- jw    added "map": to obs config, to handle strange download mirror layouts.
#               added image_name sanitation.
# V0.5 -- jw    option --keep-going implemented. Proper use of r'\b...' strings.
#               release number capture improved.
#               option --print-image-name-only option added.
# V0.6 -- jw    env XDG_RUNTIME_DIR=/run/user/1000 added (with -X), HOME=/root added always.
# V0.7 -- 2014-12-09, jw    ported to Ubuntu. docker is known there as docker.io
# V0.8 --             jw    default selective on-cache on the final install command
#                           using a timestamp with refresh and install.
#                           The --no-cache option is more expensive than expected. It
#                           disables both using the cache and filling the cache.
# V0.9  -- 2014-12-10, jw  Added changelog print out at end of installation.
# V0.9a -- 2014-12-11, jw  Added informative -T -P options for printing configuration.
#                          Fixed CentOS_6_PHP54 to really enable remi.
#                          wget -nv non-verbose -- makes logfiles more readable.
# V0.9b                jw  Added CentOS_6_PHP55 and CentOS_6_PHP56 via remi.
#                          Pretty printing a target config with -P obstarget
# V0.9c                jw  Changlog printing needs a wildcard: to catch changelog.gz changelog.Debian.gz
#                          continue wit builtin config after warnings about missing config file.
#                          hint at available targets, when given target is not there.
# V1.0                 jw  osc ls -b obsoleted with ListUrl()
# V1.1  -- 2015-01-08, jw  default verbosity back to normal run.verbose=1.
#                          fixed centos-7 to require epel (for qtwebkit)
# V1.2  -- 2015-01-12, jw  ported to python3.
# V1.3  --                 Adding basic fonts, when running with -X. Message 'package for' improved.
# V1.4  -- 2015-01-19, jw  added --ssh-key option. Non trivial part: make sshd happy on all platforms.
# V1.5  -- 2015-01-30, jw  Diagnostics hint at --download and --config, if no binaries is found.
# V1.6                     yum install can switch to --gpgcheck, to survive internal s2 downloads.
# V1.7                     Improved handling of debian file names in obs_fetch_bin_version()
#                          Added flush() before run() hoping that helps with mangled buffers.
# V1.8  -- 2015-02-03, jw  wget always with -O, needed for upgrade tests
#
# FIXME: yum install returns success, if one package out of many was installed.

from __future__ import print_function	# must appear at beginning of file.

__VERSION__="1.8"

from argparse import ArgumentParser, RawDescriptionHelpFormatter
import json, sys, os, re, time, tempfile
import subprocess, base64, requests


try:
  import urllib.request as urllib2	# python3
except ImportError:
  import urllib2			# python2


target="xUbuntu_14.04"		# default value

default_obs_config = {
  "_comment": "Written by "+sys.argv[0]+" -- edit also the builtin template",
  "obs":
    {
      "https://api.opensuse.org":
        {
          "aliases": ["obs"],
          "prj_re": "^(isv:ownCloud:|home:jnweiger)",
          "download":
            {
              "public":   "http://download.opensuse.org/repositories/",
              "api":      "https://[OBS_USER]:[OBS_PASS]@api.opensuse.org/build/[OBS_PROJ]/[OBS_TARGET]/[OBS_ARCH]/[OBS_PACK]"
            },
          "map":
            {
              "public": { "openSUSE:13.1": "/pub/opensuse/distribution/13.1/repo/oss" }
            }
        },
    },
  "target":
    {
      "xUbuntu_14.10":   { "fmt":"APT", "pre": ["wget","apt-transport-https"], "from":"ubuntu:14.10" },
      "xUbuntu_14.04":   { "fmt":"APT", "pre": ["wget","apt-transport-https"], "from":"ubuntu:14.04" },
      "xUbuntu_13.10":   { "fmt":"APT", "pre": ["wget","apt-transport-https"], "from":"ubuntu:13.10" },
      "xUbuntu_13.04":   { "fmt":"APT", "pre": ["wget","apt-transport-https"], "from":"ubuntu:13.04" },
      "xUbuntu_12.10":   { "fmt":"APT", "pre": ["wget","apt-transport-https"], "from":"ubuntu:12.10" },
      "xUbuntu_12.04":   { "fmt":"APT", "pre": ["wget","apt-transport-https"], "from":"ubuntu:12.04" },
      "Debian_6.0":      { "fmt":"APT", "pre": ["wget","apt-transport-https"], "from":"debian:6.0" },
      "Debian_7.0":      { "fmt":"APT", "pre": ["wget","apt-transport-https"], "from":"debian:7" },

      "CentOS_7":        { "fmt":"YUM", "from":"""centos:centos7
RUN yum install -y --nogpgcheck wget
RUN wget -nv http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm -O epel-7.rpm
RUN rpm -ivh epel-7.rpm
""" },
      "CentOS_6":        { "fmt":"YUM", "from":"""centos:centos6
RUN yum install -y --nogpgcheck wget
RUN wget -nv http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm -O epel-6.rpm
RUN rpm -ivh epel-6.rpm
""" },
      "CentOS_6_PHP54@SCL":  { "fmt":"YUM", "pre": ["wget"], "from":"""centos:centos6
RUN yum install -y --nogpgcheck centos-release-SCL
RUN yum install -y --nogpgcheck php54
""" },

      "CentOS_6_PHP54":  { "fmt":"YUM", "from":"""centos:centos6
RUN yum install -y --nogpgcheck wget yum-utils
RUN wget -nv http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm -O epel-6.rpm
RUN wget -nv http://rpms.famillecollet.com/enterprise/remi-release-6.rpm -O remi-6.rpm
RUN rpm -ivh remi-6.rpm epel-6.rpm
RUN yum-config-manager --enable remi
RUN yum install -y --nogpgcheck php
""" },

      "CentOS_6_PHP55":  { "fmt":"YUM", "from":"""centos:centos6
RUN yum install -y --nogpgcheck wget yum-utils
RUN wget -nv http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm -O epel-6.rpm
RUN wget -nv http://rpms.famillecollet.com/enterprise/remi-release-6.rpm -O remi-6.rpm
RUN rpm -ivh remi-6.rpm epel-6.rpm
RUN yum-config-manager --enable remi-php55
RUN yum install -y --nogpgcheck php
""" },

      "CentOS_6_PHP56":  { "fmt":"YUM", "from":"""centos:centos6
RUN yum install -y --nogpgcheck wget yum-utils
RUN wget -nv http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm -O epel-6.rpm
RUN wget -nv http://rpms.famillecollet.com/enterprise/remi-release-6.rpm -O remi-6.rpm
RUN rpm -ivh remi-6.rpm epel-6.rpm
RUN yum-config-manager --enable remi-php56
RUN yum install -y --nogpgcheck php
""" },

      "CentOS_CentOS-6": { "fmt":"YUM", "pre": ["wget"], "from":"centos:centos6" },
      "Fedora_20":       { "fmt":"YUM", "pre": ["wget"], "from":"fedora:20" },
      "Fedora_21":       { "fmt":"YUM", "pre": ["wget"], "from":"fedora:21" },
      "openSUSE_13.2":   { "fmt":"ZYPP","pre": ["ca-certificates"], "from":"opensuse:13.2" },
      "openSUSE_13.1":   { "fmt":"ZYPP","pre": ["ca-certificates"], "from":"opensuse:13.1" }
    }
}

docker_volumes=[]

################################################################################

# import github/owncloud/administration/jenkins/obs_integration/ListUrl.py
class ListUrl:

  def _apache_index(self, url):
    verify='/etc/ssl/ca-bundle.pem'
    if not os.path.exists(verify): verify='/etc/ssl/certs/ca-certificates.crt'	# seen in https://urllib3.readthedocs.org/en/latest/security.html
    if not os.path.exists(verify): verify=True

    r = requests.get(url, verify=verify) 	# default verify=True fails on python3@openSUSE-13.1 with DEFAULT_CA_BUNDLE_PATH=/etc/ssl/cersts/ EISDIR

    if r.status_code != 200:
      raise ValueError(url+" status:"+str(r.status_code))
    r.dirs = []
    r.files = []
    for l in r.content.decode().splitlines():
      # '<img src="/icons/folder.png" alt="[DIR]" /> <a href="7.0/">7.0/</a>       03-Dec-2014 19:57    -   '
      # ''<img src="/icons/tgz.png" alt="[   ]" /> <a href="owncloud_7.0.4-2.diff.gz">owncloud_7.0.4-2.diff.gz</a>                     09-Dec-2014 16:53  9.7K   <a href="owncloud_7.0.4-2.diff.gz.mirrorlist">Details</a>'
      #
      m = re.search("<a\s+href=[\"']?([^>]+?)[\"']?>([^<]+?)[\"']?</a>\s*([^<]*)", l, re.I)
      if m:
        # ('owncloud_7.0.4-2.diff.gz', 'owncloud_7.0.4-2.diff.gz', '09-Dec-2014 16:53  9.7K   ')
        m1,m2,m3 = m.groups()

        if re.match("(/|\?|\w+://)", m1):       # skip absolute urls, query strings and foreign urls
          continue
        if re.match("\.?\./?$", m1):    # skip . and ..
          continue

        m3 = re.sub("[\s-]+$", "", m3)
        if re.search("/$", m1):
          r.dirs.append([m1, m3])
        else:
          r.files.append([m1, m3])
    return r

  def apache(self, url, pre=''):
    if not url.endswith('/'): url += '/'        # directory!
    l = self._apache_index(url)
    r = []
    for f in l.files:
      if self.callback: self.callback(url, pre, f[0], f[1])
      r.append([pre+f[0], f[1]])
    for d in l.dirs:
      if self.callback: self.callback(url, pre, d[0], d[1])
      r.append([pre+d[0], d[1]])
      if self.recursive:
        r.extend(self.apache(url+d[0], pre+d[0]))
    return r

  def __init__(self, callback=None, recursive=True):
    self.callback=callback
    self.recursive=recursive


# Keep in sync with internal_tar2obs.py obs_docker_install.py
def run(args, input=None, redirect=None, redirect_stdout=True, redirect_stderr=True, return_tuple=False, return_code=False, tee=False):
  """
     make the subprocess monster usable
  """

  # be prepared. I have seen overwritten lines in the log when subprocess docker build errors out.
  sys.stdout.flush()	
  sys.stderr.flush()

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
    if run.verbose > 1: in_redirect=" (<< '%s')" % input
    input = input.encode()		# bytes needed for python3

  if run.verbose: print("+ %s%s" % (args, in_redirect))
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
run.verbose=1


def urlopen_auth(url, username, password):
  request = urllib2.Request(url)
  txt = '%s:%s' % (username, password)
  base64string = base64.encodestring(txt.encode())		# encode() needed for python3
  base64string = base64string.decode().replace('\n', '')	# decode() needed for python3
  request.add_header("Authorization", "Basic %s" % base64string)
  return urllib2.urlopen(request)


def check_dependencies():
  run.verbose -= 1
  docker_bin = run(["which", "docker"], redirect_stderr=False)
  if not re.search(r"/docker\b", docker_bin.decode(), re.S):		# decode() needed for python3
    print("""docker not installed? Try:

openSUSE:
 sudo zypper in docker

Debian:
 sudo apt-get install bridge-utils docker.io
 # or for a newer version:
 sudo sh -c "echo deb https://get.docker.com/ubuntu docker main > /etc/apt/sources.list.d/docker.list"
 sudo apt-get update
 sudo apt-get install lxc-docker

Mint (as Debian, plus):
 sudo apt-get install cgroup-lite apparmor

""")
    sys.exit(0)
  docker_pid = run(["pidof", "docker"], redirect_stderr=False)
  if docker_pid == "":
    docker_pid = run(["pidof", "docker.io"], redirect_stderr=False)
  if not re.search(r"\b\d\d+\b", docker_pid.decode(), re.S):
    print("""docker is not running? Try:

openSUSE:
 sudo systemctl enable docker
 sudo systemctl start docker

Debian
 sudo service docker.io start
 # or for the lxc-docker version
 sudo service docker start
 dmesg
 # if you see respawn errors try: apt-get install cgroup-lite apparmor

""")
    sys.exit(0)
  docker_grp = run(["id", "-a"], redirect_stderr=False)
  if not re.search(r"\bdocker\b", docker_grp.decode(), re.S):
    print("""You are not in the docker group? Try:

openSUSE:
 sudo usermod -a -G docker $USER; reboot"

Debian:
 sudo groupadd docker
 sudo gpasswd -a $USER docker; reboot
""")
    sys.exit(0)
  run.verbose += 1


def guess_obs_api(prj, override=None, verbose=True):
  if override:
    for obs in obs_config['obs']:
      if override == obs:
        return obs
      o=obs_config['obs'][obs]
      if 'aliases' in o:
        for a in o['aliases']:
          if override == a:
            print("guess_obs_api: alias="+a+" -> "+obs)
            return obs
    print("Warning: obs_api="+override+" not found in "+args.configfile)
    return override     # not found.
  # actual guesswork
  for obs in obs_config['obs']:
    o=obs_config['obs'][obs]
    if 'prj_re' in o and re.match(o['prj_re'], prj):
      if verbose: print("guess_obs_api: prj="+prj+" -> "+obs)
      return obs
  raise ValueError("guess_obs_api failed for project='"+prj+"', try different project, -A, or update config in "+args.configfile)


def printable_url(url):
  """ remove credentials from url, so that it can be safely printed 
      not used much, we maintain both, url_cred and url."""
  return re.sub("://([^/]*?)@", "://********@", url);


def obs_fetch_bin_version(api, download_item, prj, pkg, target):
  cfg = obs_download_cfg(obs_config['obs'][api], download_item, prj, urltest=False, verbose=False)
  lu = ListUrl()
  bin_seen = ''
  try:
    downloads = lu.apache(cfg['url_cred']+'/'+target)
    for line in downloads:
      bin_seen += re.sub(".*/", "", line[0]) + "\n"
  except:
    pass

  # osc ls -b obsoleted by the above ListUrl()
  # bin_seen = run(["osc", "-A"+api, "ls", "-b", args.project, args.package, target], input="")

  deb_pkg_name=re.sub('_','-',args.package)
  # obs-docker-install_1.0-20141218_amd64.deb
  # cernbox-client_1.7.0-0.jw20141127_amd64.deb
  m = re.search(r'^\s*'+re.escape(deb_pkg_name)+r'_(\d+[^-\s]*)\-(\d+[^_\s]*)_.*?\.deb$', bin_seen, re.M)
  if m: return (m.group(1),m.group(2))
  # owncloud-client_1.7.0_i386.deb
  m = re.search(r'^\s*'+re.escape(deb_pkg_name)+r'_(\d+[^_\s]*)_.*?\.deb$', bin_seen, re.M)
  if m: return (m.group(1),'')

  # cloudtirea-client-1.7.0-4.1.i686.rpm
  m = re.search(r'^\s*'+re.escape(args.package)+r'-(\d+[^-\s]*)\-([\w\.]+?)\.(x86_64|i\d86|noarch)\.rpm$', bin_seen, re.M)
  if m: return (m.group(1),m.group(2))
  print("package "+args.package+" for "+target+" not seen in "+cfg['url']+'/'+target+" :\n"+ bin_seen)
  print("Try one of these:")
  lu.recursive = False
  try:
    all_seen = lu.apache(cfg['url_cred'])
  except:
    all_seen = ()

  if not len(all_seen):
    print("Oops, Nothing here at "+cfg['url']+" --\n Try different --download option or different --config file?")

  for target in all_seen:
    print(re.sub("/$","", target[0]),end=' ')
  print("")
  sys.exit(22)


def docker_from_obs(obs_target_name):
  if obs_target_name in obs_config['target']:
    r = obs_config['target'][obs_target_name]
    r['obs'] = obs_target_name
    return r
  raise ValueError("no docker base image known for '"+obs_target_name+"' - choose other obs target or update config in "+args.configfile)

def obs_download_cfg(config, download_item, prj_path, urltest=True, verbose=True):
  """
    prj_path is appended to url_cred, where all ':' are replaced with ':/'
    a '/' is asserted between url_cred and prj_path.
    url_cred is guaranteed to end in '/'
    url, username, password, are derived from url_cred.
    download_item: public, internal, ...

    Side-Effect:
      The resulting url_cred is tested, and a warning is printed, if it is not accessible.
  """
  if not 'download' in config:
    raise ValueError("obs_download_cfg: cannot read download url from config")
  if not download_item in config["download"]:
    raise ValueError("obs_download_cfg: has no item '"+download_item+"' -- check --download option.")
  url_cred=config["download"][download_item]

  if not prj_path is None:
    mapping=None
    if "map" in config and download_item in config["map"]: mapping=config["map"][download_item]
    if mapping and prj_path in mapping:
      prj_path = mapping[prj_path]
      if verbose: print("prj path mapping -> ", prj_path)
    else:
      prj_path = re.sub(':',':/',prj_path)

    ## if our mapping or prj_path is a rooted path, strip
    ## path components from url_cred, if any.
    if re.match(r'/',prj_path):
      m=re.match(r'(.*://[^/]+)', url_cred)
      if m: url_cred = m.group(1)

    if not re.search(r'/$', url_cred) and not re.match(r'/', prj_path): url_cred += '/'
    url_cred += prj_path
  if not re.search(r'/$', url_cred): url_cred += '/'
  data = { "url_cred":url_cred }

  # yet another fluffy url parser ahead
  m=re.match(r'(\w+://)([^/]+)(/.*)', url_cred)
  if m:
    # https://
    url_proto = m.group(1)
    # meself:pass1234@obs.owncloud.com:8888
    server_cred = m.group(2)
    # /path/where/...
    url_path = m.group(3)
    m=re.match(r'(.*)@(.*)$', server_cred)
    if m:
      # meself:pass1234
      cred = m.group(1)
      # obs.owncloud.com:8888
      server = m.group(2)
      m=re.match(r'(.*):(.*)', cred)
      if m:
        data['username'] = m.group(1)
        data['password'] = m.group(2)
      else:
        data['username'] = cred
      data['url'] = url_proto + server + url_path
    else:
      data['url'] = url_proto + server_cred + url_path
  else:
    data['url'] = url_cred      # oops.

  if not urltest: return data

  try:
    if verbose: print("testing "+data['url']+" ...")
    if 'username' in data and 'password' in data:
      uo = urlopen_auth(data['url'], data['username'], data['password'])
    else:
      uo = urllib2.urlopen(urllib2.Request(data['url']))
    text = uo.readlines()
    if not re.search(r'\b'+re.escape(target)+r'\b', str(text)):
      raise ValueError("target="+target+" not seen at "+data['url'])
    if verbose: print(" ... %d bytes read, containing '%s', good." % (len(str(text)), target))
  except Exception as e:
    if args.keep_going:
      print("WARNING: Cannot read "+data['url']+"\n"+str(e))
      print("\nTry a different --download option or wait 10 sec...")
      time.sleep(10)
    else:
      raise e

  return data

################################################################################

docker_cmd_clean_c=" docker ps -a  | grep Exited   | awk '{ print $1 }' | xargs docker rm"
docker_cmd_clean_i=" docker images | grep '<none>' | awk '{ print $3 }' | xargs docker rmi\n"

ap = ArgumentParser(
  formatter_class=RawDescriptionHelpFormatter,
  epilog="""Example:
 """+sys.argv[0]+""" isv:ownCloud:desktop/owncloud-client CentOS_CentOS-6

Suggested cleanup:
 """+docker_cmd_clean_c+"\n "+docker_cmd_clean_i+"""

Version: """+__VERSION__,
  description="Create docker images for RPM and DEB packages built with openSUSE Build Service (public or other instance)."
)

ap.add_argument("-p", "--platform", dest="target", metavar="TARGET", help="obs build target name. Default: "+target)
ap.add_argument("-f", "--base-image", "--from", metavar="IMG", help="docker base image to start with. Exclusive with specifying a -p platform name")
ap.add_argument("-V", "--version", default=False, action="store_true", help="print version number and exit")
ap.add_argument("-d", "--download", default='public', metavar="SERVER", help='use a different download server. Try "internal" or a full url. Default: "public"')
ap.add_argument("-c", "--configfile", default='obs_docker.json', metavar="FILE", help='specify different config file. Default: generate a default file if missing, so that you can edit')
ap.add_argument("-W", "--writeconfig", default=False, action="store_true", help='Write a default config file and exit. Default: use existing config file')
ap.add_argument("-A", "--obs-api", help="Identify the build service. Default: guessed from project name")
ap.add_argument("-n", "--image-name", help="Specify the name for the docker image. Default: construct a name and print")
ap.add_argument("-I", "--print-image-name-only", default=False, action="store_true", help="construct a name and exit after printing")
ap.add_argument("-P", "--print-config-only", default=False, action="store_true", help="show the current project and target configuration and exit after printing. An optional target argument (see also -T) can be used to pretty print only one target configuration.")
ap.add_argument("-T", "--list-targets-only", default=False, action="store_true", help="show a list of configured build target names and exit after printing")
ap.add_argument("-e", "--extra-packages", help="Comma separated list of packages to pre-install. Default: only per 'pre' in the config file")
ap.add_argument("-q", "--quiet", default=False, action="store_true", help="Print less information while working. Default: babble a lot")
ap.add_argument("-k", "--keep-going", default=False, action="store_true", help="Continue after errors. Default: abort on error")
ap.add_argument("-N", "--no-operation", default=False, action="store_true", help="Print docker commands to create an image only. Default: create an image")
ap.add_argument("-R", "--rm", default=False, action="store_true", help="Remove intermediate docker containers after a successful build")
ap.add_argument("--no-cache", default=False, action="store_true", help="Do not use cache when building the image. Default: use docker cache as available")
ap.add_argument("--nogpgcheck", default=False, action="store_true", help="Ignore broken or missing keys. Default: yum check, zypper auto-import")
ap.add_argument("-X", "--xauth", default=False, action="store_true", help="Prepare a docker image that can connect to your X-Server.")
ap.add_argument("-S", "--ssh-key", help="Import an ssh-key (e.g. ~/.ssh/id_dsa.pub) and start an ssh server with the default docker run CMD.")
ap.add_argument("project", metavar="PROJECT", nargs="?", help="obs project name. Alternate syntax to PROJ/PACK")
ap.add_argument("package", metavar="PACKAGE",  nargs="?", help="obs package name, or PROJ/PACK")
ap.add_argument("platform",metavar="PLATFORM", nargs="?", help="obs build target name. Alternate syntax to -p. Default: "+target)
ap.add_argument("--run", "--exec", nargs="+", metavar="SHELLCMDARGS", help="Execute a command (with parameters) via docker run. Default: build only and print exec instructions.")
args = ap.parse_args()  # --help is automatic

if args.version: ap.exit(__VERSION__)
if args.print_image_name_only:
  args.quiet=True
  args.no_operation=True
if args.quiet: run.verbose=0


context_dir = tempfile.mkdtemp(prefix="obs_docker_install_context_")
docker_cmd_cmd="/bin/bash"
extra_docker_cmd = []
extra_packages = []
if args.extra_packages: extra_packages = re.split(r"[\s,]", args.extra_packages)

if args.writeconfig:
  if os.path.exists(args.configfile):
    print("Will not overwrite existing "+args.configfile)
    print("Please use -c to choose a different name, or move the file away")
    sys.exit(1)
  cfp = open(args.configfile, "w")
  json.dump(default_obs_config, cfp, indent=4, sort_keys=True)
  cfp.write("\n")
  cfp.close()
  print("default config written to " + args.configfile)
  sys.exit(0)

if not os.path.exists(args.configfile):
  print("Config file does not exist: "+args.configfile)
  print("Use -W to generate the file, or use -c to choose different config file")

  # either exit here, or be nice and use the builtin defaults.
  # sys.exit(1)
  obs_config = default_obs_config
else:
  try:
    cfp = open(args.configfile)
    obs_config = json.load(cfp)
  except Exception as e:
    print("ERROR: loading "+args.configfile+" failed: ", e)
    print("")
    obs_config = default_obs_config

if args.print_config_only:
  import pprint
  if args.project:
    cfg=obs_config['target'][args.project]
    print("FROM "+cfg['from']+"\n# ",end='')
    del(cfg['from'])
    pprint.pprint(cfg)
  else:
    pprint.pprint(obs_config)
  sys.exit(0)

if args.list_targets_only:
  print("OBS platform          Docker base image")
  print("---------------------------------------")
  for t in obs_config['target']:
    xx = docker_from_obs(t)['from']
    xx = re.sub("\n.*", "", xx)
    print("%-20s  %s" % (t, xx))
  sys.exit(0)

if args.project is None:
  print("need project/package name")
  sys.exit(1)

m = re.match(r'(.*)/(.*)', args.project)
if m is None and args.package is None:
  print("need both, project and package")
  sys.exit(1)
if m:
  args.platform = args.package
  args.package = m.group(2)
  args.project = m.group(1)

if args.target:   target=args.target
if args.platform: target=args.platform
if args.target and args.platform:
  print("specify either a build target platform with -p or as a third parameter. Not both")
  sys.exit(1)
target = re.sub(':','_', target)        # just in case we get the project name instead of the build target name

obs_api=guess_obs_api(args.project, args.obs_api, not args.quiet)
try:
  version,release=obs_fetch_bin_version(obs_api, args.download, args.project, args.package, target)
except Exception as e:
  if args.keep_going:
    print(str(e))
    version,release = '',''
  else:
    raise e

docker=docker_from_obs(target)

if args.base_image:
  print("Default docker FROM "+docker['from'])
  print("Command line docker FROM "+args.base_image)
  if re.search(r'\n', docker['from']) and not re.search(r'\n', args.base_image):
    print("WARNING: multiline FROM replaced with simple FROM!\n")
    time.sleep(2)
  docker['from'] = args.base_image

if not args.no_operation:
  if args.keep_going:
    try:
      check_dependencies()
    except:
      pass
  else:
    check_dependencies()

download=obs_download_cfg(obs_config["obs"][obs_api], args.download, args.project, verbose=not args.quiet, urltest=not args.no_operation)

if args.image_name:
  image_name = args.image_name
else:
  image_name = args.package+'-'+version+'-'+release+'-'+target
  # docker disallows upper case, and many special chars. Grrr.
  image_name = re.sub('[^a-z0-9-_\.]', '-', image_name.lower())

if args.print_image_name_only:
  print(image_name)
  sys.exit(0)

if args.xauth:
  xauthdir="/tmp/.docker"
  xauthfile=xauthdir+"/wildcardhost.xauth"
  xa_cmd="xauth nlist :0 | sed -e 's/^0100/ffff/' | xauth -f '"+xauthfile+"' nmerge -"
  if not args.no_operation:
    run(["rm", "-rf", xauthdir])
    if not os.path.isdir(xauthdir): os.makedirs(xauthdir)       # mkdir -p $xauthdir
    open(xauthfile, "w").write("")                              # touch $xauthfile
    run(["chgrp", "docker", xauthfile], redirect_stderr=False)
    run(["sh", "-c", xa_cmd], redirect_stderr=False)
    os.chmod(xauthfile, 0o660)                           # chmod 660 $xauthfile
  xsock="/tmp/.X11-unix"
  docker_volumes.append(xsock+':'+xsock)
  docker_volumes.append(xauthfile+':'+xauthfile)

  # add basic fonts, so that a GUI becomes readable.
  if re.search(r'suse', target, re.I): 			extra_packages.extend(['xorg-x11-fonts-core'])
  if re.search(r'centos|rhel|fedora', target, re.I): 	extra_packages.extend(['gnu-free-sans-fonts'])
  if re.search(r'ubuntu|debian', target, re.I):		extra_packages.extend(['fonts-dejavu-core'])

if args.ssh_key:
  if args.ssh_key.endswith(".pub"):
    if not args.no_operation: run(["cp", args.ssh_key, context_dir+'/authorized_keys'])
    extra_docker_cmd.extend(['RUN mkdir /root/.ssh', 'ADD authorized_keys /root/.ssh/authorized_keys'])
    # tested with centos:
    extra_docker_cmd.extend(["RUN sed '/pam_loginuid.so/s/^/#/g' -i /etc/pam.d/*"])
  else:
    print("ssh-key '"+args.ssh_key+"' does not end in '.pub' is not a plain file. Ignored.");
  # add ssh server
  if re.search(r'suse', target, re.I):
    extra_packages.extend(['openssh'])
    docker_cmd_cmd='service sshd start ; ip a | grep global ; exec /bin/bash'
  if re.search(r'centos|rhel|fedora', target, re.I):
    extra_packages.extend(['openssh-server'])
    docker_cmd_cmd='service sshd start ; ip a | grep global ; exec /bin/bash'
  if re.search(r'ubuntu|debian', target, re.I):
    extra_packages.extend(['openssh-server'])
    docker_cmd_cmd='mkdir -p /var/run/sshd; /usr/sbin/sshd; ip a | grep global ; exec /bin/bash'


docker_run=["docker","run","-ti"]
for vol in docker_volumes:
  docker_run.extend(["-v", vol])
docker_run.append(image_name)
print("#+ " + " ".join(docker_run))

## multi line docker commands are explicitly allowed in 'from'!
dockerfile="FROM "+docker['from']+"\n"
dockerfile+="ENV TERM ansi\n"
dockerfile+="ENV HOME /root\n"

wget_cmd="wget -nv"
if "username" in download: wget_cmd+=" --user '"+download["username"]+"'"
if "password" in download: wget_cmd+=" --password '"+download["password"]+"'"
wget_cmd+=" "+download["url"]
if not re.search(r'/$', wget_cmd): wget_cmd+='/'

now=time.strftime('%Y%m%d%H%M')
start_time=time.time()
d_endl="\n"
if args.keep_going: d_endl = " || true\n"

if docker["fmt"] == "APT":
  if args.nogpgcheck: print("Option nogpgcheck not implemented for APT")
  dockerfile+="ENV DEBIAN_FRONTEND noninteractive\n"
  dockerfile+="RUN apt-get -q -y update"+d_endl
  if "pre" in docker and len(docker["pre"]):
    dockerfile+="RUN apt-get -q -y install "+" ".join(docker["pre"])+d_endl
  dockerfile+="RUN "+wget_cmd+target+"/Release.key -O Release.key"+d_endl
  dockerfile+="RUN apt-key add - < Release.key"+d_endl
  dockerfile+="RUN echo 'deb "+download["url_cred"]+"/"+target+"/ /' >> /etc/apt/sources.list.d/"+args.package+".list"+d_endl
  dockerfile+="RUN apt-get -q -y update"+d_endl
  if extra_packages: 	dockerfile+="RUN apt-get -q -y install "+' '.join(extra_packages)+d_endl
  if extra_docker_cmd:	dockerfile+=d_endl.join(extra_docker_cmd)+d_endl
  dockerfile+="RUN date="+now+" apt-get -q -y update && apt-get -q -y install "+args.package+d_endl
  dockerfile+="RUN zcat /usr/share/doc/"+args.package+"/changelog*.gz  | head -20"+d_endl
  dockerfile+="RUN echo 'apt-get install "+args.package+"' >> ~/.bash_history"+d_endl

elif docker["fmt"] == "YUM":
  yum_install = 'yum install -y'
  if args.nogpgcheck: yum_install += ' --nogpgcheck'
  dockerfile+="RUN yum clean expire-cache"+d_endl
  if "pre" in docker and len(docker["pre"]):
    dockerfile+="RUN "+yum_install+" "+" ".join(docker["pre"])+d_endl
  dockerfile+="RUN "+wget_cmd+target+'/'+args.project+".repo -O /etc/yum.repos.d/"+args.project+".repo"+d_endl
  if extra_packages:	dockerfile+="RUN "+yum_install+" "+" ".join(extra_packages)+d_endl
  if extra_docker_cmd:	dockerfile+=d_endl.join(extra_docker_cmd)+d_endl
  dockerfile+="RUN date="+now+" yum clean expire-cache && "+yum_install+" "+args.package+d_endl
  dockerfile+="RUN rpm -q --changelog "+args.package+" | head -20"+d_endl
  dockerfile+="RUN echo '"+yum_install+" "+args.package+"' >> ~/.bash_history"+d_endl

elif docker["fmt"] == "ZYPP":
  if args.nogpgcheck: print("Option nogpgcheck not implemented for ZYPP")
  dockerfile+="RUN zypper --non-interactive --gpg-auto-import-keys refresh"+d_endl
  if "pre" in docker and len(docker["pre"]):
    dockerfile+="RUN zypper --non-interactive --gpg-auto-import-keys install "+" ".join(docker["pre"])+d_endl
  dockerfile+="RUN zypper --non-interactive --gpg-auto-import-keys addrepo "+download["url_cred"]+target+"/"+args.project+".repo"+d_endl
  if extra_packages:	dockerfile+="RUN zypper --non-interactive --gpg-auto-import-keys install "+" ".join(extra_packages)+d_endl
  if extra_docker_cmd:	dockerfile+=d_endl.join(extra_docker_cmd)+d_endl
  dockerfile+="RUN date="+now+" zypper --non-interactive --gpg-auto-import-keys refresh && zypper --non-interactive --gpg-auto-import-keys install "+args.package+d_endl
  dockerfile+="RUN rpm -q --changelog "+args.package+" | head -20"+d_endl
  dockerfile+="RUN echo 'zypper install "+args.package+"' >> ~/.bash_history"+d_endl

else:
  raise ValueError("dockerfile generator not implemented for fmt="+docker["fmt"])

if args.xauth:
  dockerfile+="ENV DISPLAY unix:0\n"
  dockerfile+="ENV XDG_RUNTIME_DIR /run/user/1000\n"
  dockerfile+="ENV XAUTHORITY "+xauthfile+"\n"
  dockerfile+='RUN : "'+xa_cmd+'"'+"\n"
dockerfile+='RUN : "'+" ".join(docker_run)+'"'+"\n"
dockerfile+='CMD '+docker_cmd_cmd+"\n"


# print(obs_api, download, image_name, target, docker)

r=0
docker_build=["docker", "build"]
if args.rm: docker_build.append("--rm")
if args.quiet: docker_build.append("-q")
if args.no_cache: docker_build.append("--no-cache")
docker_build.extend(["-t", image_name, context_dir])

if args.no_operation:
  print(dockerfile)
  print("\nYou can use the above Dockerfile to create an image like this:\n "+" ".join(docker_build)+"\n")
else:
  fd=open(context_dir+"/Dockerfile", "w")
  fd.write(dockerfile)
  fd.close()
  run.verbose += 1
  print(dockerfile)
  # using stdin would silently disable ADD instructions.
  r=run(docker_build, redirect_stdout=False, redirect_stderr=False, return_code=True)
  run.verbose -= 1
  run(['echo', 'rm', '-rf', context_dir])
  if not args.quiet:
    if r:
      print("Failed with non-zero exit code="+str(r)+". Check for errors in the above log.\n")
      args.run = False
    else:
      print("Image successfully created. Check for warnings in the above log.\n")
print(time.strftime("build time: %H:%M:%S", time.gmtime(time.time()-start_time)))

if not args.rm and not r and not args.quiet:
  print("You may remove unused container/images with e.g.\n "+docker_cmd_clean_c+"\n "+docker_cmd_clean_i+"\n")

if not r and not args.run:
  print("You can run the new image with:\n "+" ".join(docker_run))

if args.run:
  if re.search(r'[\s;&<>"]', args.run[0]): args.run=['/bin/bash', '-c', " ".join(args.run)]
  r = run(docker_run+args.run, redirect_stderr=False, redirect_stdout=False, return_code=True)

sys.exit(r)
