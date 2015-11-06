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
# V1.9  -- 2015-02-04, jw  --dockerfile added. simplified output of -N
# V2.0  -- 2015-02-08, jw  can now handle @suffixes in target names. Example CentOS_6@SCL-PHP54
# V2.1  -- 2015-02-14, jw  Option --cleanup added. cleanup commands improved.
# V2.2  -- 2015-02-18, jw  fixed --dockerfile to never include any extras.
# V2.3  -- 2015-02-21, jw  docker group is not needed when running as root.
# V2.4  -- 2015-02-24, jw  renamed 'pre' to 'inst', as this installs packages.
#                          Defined 'pre' as prefix docker file snippet.
#                          - added a 12.3 base image. (officially EOL)
# V2.5  -- 2015-03-01, jw  rpm --import ... repodata/repomd.xml.key added for YUM.
# V2.6  -- 2015-03-04, jw  also accept Ubuntu* without leading x.
# V2.7  -- 2015-03-16, jw  added docker_on_aufs() to help workaround aufs-specific issues.
# V2.8  -- 2015-03-17, jw  'aufs' in json config is now honored.
# V2.9  -- 2015-03-23, jw  fixed image name collision by including server and project in the name.
# V2.10 -- 2015-03-30, jw  converted config file format from json to yaml. Human readability is key!
#			   aufs changed to aufs_hack and no longer automatic. It is now triggered by env AUFS_HACK=1 ...
#                          added yaml_load_expand(): to use 'base' elements in 'target' as inheritance templates.
# V2.11 -- 2015-04-10, jw  added support for -- run -ti -p 888:80, using the 'run' snippets in the yaml file.
# V2.12	-- 2015-05-18, jw  survive missing [run] in yaml. Added default run snippets to builtin yaml.
#                          Error fallback added: make one attempt to create an image despite install errors.
# V2.13 -- 2015-05-18, jw  Fixed '--dump run' to work with default target too. Apache start code as default start.sh script.
#			   Try obs target xUbuntu* if the specified Ubuntu* is not there.
#                          Printed Dockerfile has a hint about start.sh script if one exists. 
# V2.14 -- 2015-06-16, jw  Directly printing start.sh with -D now as a comment. Hint removed.
# V2.15 -- 2015-06-16, jw  mention startfile in as bash --rcfile /root/start.sh
#                          run apt-get install with -V to show version numbers.
# V2.16 -- 2015-06-29, jw  Support start.sh with ssh server.
# V2.17 -- 2015-07-01, jw  run_tstamp introduced to switch off timestamp printing with -D
# V2.18 -- 2015-07-03, jw  matched_package_run_script() return value is format() expanded for
#                          {ObsApi}/{Project}/{Package}/{Platform}
#                          run: snippets for -client added to run owncloudcmd -v or similar.
# V2.19 -- 2015-07-08, jw  Disabled run_tstamp alltogether. 
#                          Using yum clean all instead of yum clean expire-cache.
# V2.20 -- 2016-08-20, jw  Moving ADD further down to allow more caching.
#                          Added run_nocache using image_name.
# V2.21 -- 2015-09-17, jw  Option -S prints out the dockerfile as a plain shell script.
# V2.22 -- 2015-11-05, jw  format DNF added, used with Fedora_22
#
# FIXME: yum install returns success, if one package out of many was installed.

from __future__ import print_function	# must appear at beginning of file.

__VERSION__="2.22"

from argparse import ArgumentParser, RawDescriptionHelpFormatter
import yaml, sys, os, re, time, tempfile
import subprocess, base64, requests


try:
  import urllib.request as urllib2	# python3
except ImportError:
  import urllib2			# python2


target="Ubuntu_14.10"		# default value

default_obs_config_yaml = "# Written by "+sys.argv[0]+""" -- edit also the builtin template
obs:
  https://api.opensuse.org:
    aliases: [obs]
    download:
      internal: http://download.opensuse.org/repositories/
      public: http://download.opensuse.org/repositories/
    map:
      public:
        'openSUSE:13.1': /pub/opensuse/distribution/13.1/repo/oss
    prj_re: ^(isv:ownCloud:|home:jnweiger)

target:
  CentOS_6:
    aufs_hack: |
      RUN wget -nv http://download.opensuse.org/repositories/isv:/ownCloud:/devel/CentOS_CentOS-6/isv:ownCloud:devel.repo -O /etc/yum.repos.d/isv:ownCloud:devel.repo
      RUN yum install -y --nogpgcheck libcap-dummy      # workaround aufs issue with cpio.
    fmt: YUM
    from: centos:centos6
    inst: [wget, samba-client]
    run:
      '^(owncloud)$': |
        yum install -y mysql-server
        yum install -y php-mysql
        service mysqld start
        sleep 5
        /usr/bin/mysqladmin -u root password root
        service httpd start
        sleep 2
        curl -s localhost:80/owncloud/ | grep pass
        php --version

      '(-client)$': |
        $(rpm -ql {Package} | grep -e '^/usr/bin/.*cmd$') -v

      '': |

  CentOS_CentOS-6:
    base: [CentOS_6]
    pre: |
      RUN yum install -y --nogpgcheck wget
      RUN wget -nv http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
      RUN rpm -ivh epel-release-6-8.noarch.rpm

  CentOS_6@SCL-PHP54:
    base: [CentOS_6]
    pre: |
      RUN yum install -y --nogpgcheck centos-release-SCL
      RUN yum install -y --nogpgcheck php54

  CentOS_6_PHP54:
    base: [CentOS_6]
    pre: |
      RUN yum install -y --nogpgcheck wget yum-utils
      RUN wget http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
      RUN wget -nv http://rpms.famillecollet.com/enterprise/remi-release-6.rpm
      RUN rpm -ivh remi-release-6*.rpm epel-release-6*.rpm
      RUN yum-config-manager --enable remi
      RUN yum install -y --nogpgcheck php

  CentOS_6_PHP55:
    base: [CentOS_6]
    pre: |
      RUN yum install -y --nogpgcheck wget yum-utils
      RUN wget -nv http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
      RUN wget -nv http://rpms.famillecollet.com/enterprise/remi-release-6.rpm
      RUN rpm -ivh remi-release-6*.rpm epel-release-6*.rpm
      RUN yum-config-manager --enable remi,remi-php55
      RUN yum install -y --nogpgcheck php

  CentOS_6_PHP56:
    base: [CentOS_6]
    pre: |
      RUN yum install -y --nogpgcheck wget yum-utils
      RUN wget -nv http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
      RUN wget -nv http://rpms.famillecollet.com/enterprise/remi-release-6.rpm
      RUN rpm -ivh remi-release-6*.rpm epel-release-6*.rpm
      RUN yum-config-manager --enable remi,remi-php56
      RUN yum install -y --nogpgcheck php

  CentOS_7:
    aufs_hack: |
      RUN wget -nv http://download.opensuse.org/repositories/isv:/ownCloud:/devel/CentOS_7/isv:ownCloud:devel.repo -O /etc/yum.repos.d/isv:ownCloud:devel.repo
      RUN yum install -y --nogpgcheck libcap-dummy      # workaround aufs issue with cpio.
    fmt: YUM
    from: centos:centos7
    inst: [wget]
    pre: |
      RUN yum install -y --nogpgcheck wget
      RUN wget -nv http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm
      RUN rpm -ivh epel-release-7*.rpm

  CentOS_CentOS-7: { base: [CentOS_7] }

  Fedora_20:
    aufs_hack: |
      RUN rpm --import http://download.opensuse.org/repositories/isv:/ownCloud:/devel/Fedora_20/repodata/repomd.xml.key
      RUN wget -nv http://download.opensuse.org/repositories/isv:/ownCloud:/devel/Fedora_20/isv:ownCloud:devel.repo -O /etc/yum.repos.d/isv:ownCloud:devel.repo
      RUN yum install -y --nogpgcheck libcap-dummy      # workaround aufs issue with cpio.
    fmt: YUM
    from: fedora:20
    inst: [wget]
    run:
      '^(owncloud)$': |
        mysql_install_db
        chown -R mysql:mysql /var/lib/mysql
        chown -R mysql:mysql /var/log/mariadb/
        service mariadb start
        sleep 3
        /usr/bin/mysqladmin -u root password root
        service httpd start
        sleep 1
        curl -s localhost:80/owncloud/ | grep pass
        php --version

      '(-client)$': |
        $(rpm -ql {Package} | grep -e '^/usr/bin/.*cmd$') -v

      '': |
        service httpd start

  Fedora_21: { base: [Fedora_20], fmt: YUM, from: 'fedora:21' }
  Fedora_22: { base: [Fedora_20], fmt: DNF, from: 'fedora:22' }

  Debian_6.0:
    fmt: APT
    from: debian:6.0
    inst: [wget, apt-transport-https]
    run:
      '^(owncloud|owncloud-enterprise)$': |
        service mysql start
        sleep 3
        /usr/bin/mysqladmin -u root password root
        service apache2 start
        sleep 1
        curl -s localhost:80/owncloud/ | grep pass
        php --version

      '(-client)$': |
        $(dpkg -L {Package} | grep -e '^/usr/bin/.*cmd$') -v

      '': |
        service apache2 start

  Debian_7.0: { base: [Debian_6.0], from: 'debian:7' }
  Debian_8.0: { base: [Debian_6.0], from: 'debian:8' }

  Ubuntu_12.04: { base: [Debian_6.0], from: 'ubuntu:12.04' }
  Ubuntu_12.10: { base: [Debian_6.0], from: 'ubuntu:12.10' }
  Ubuntu_13.04: { base: [Debian_6.0], from: 'ubuntu:13.04' }
  Ubuntu_13.10: { base: [Debian_6.0], from: 'ubuntu:13.10' }
  Ubuntu_14.04: { base: [Debian_6.0], from: 'ubuntu:14.04' }
  Ubuntu_14.10: { base: [Debian_6.0], from: 'ubuntu:14.10' }
  Ubuntu_15.04: { base: [Debian_6.0], from: 'ubuntu:15.04' }

  # xUbuntu* are simply aliases for Ubuntu*
  xUbuntu_12.04: { base: [Ubuntu_12.04] }
  xUbuntu_12.10: { base: [Ubuntu_12.10] }
  xUbuntu_13.04: { base: [Ubuntu_13.04] }
  xUbuntu_13.10: { base: [Ubuntu_13.10] }
  xUbuntu_14.04: { base: [Ubuntu_14.04] }
  xUbuntu_14.10: { base: [Ubuntu_14.10] }
  xUbuntu_15.04: { base: [Ubuntu_15.04] }

  openSUSE_13.1:
    fmt: ZYPP
    from: opensuse:13.1
    inst: [ca-certificates]
    run:
      '(-client)$': |
        $(rpm -ql {Package} | grep -e '^/usr/bin/.*cmd$') -v

      '': |
        service apache2 start

  SLE_12:        { base: [openSUSE_13.1], pre: '# attention: using openSUSE base image!!!' }
  openSUSE_13.2: { base: [openSUSE_13.1], from: 'opensuse:13.2' }
  openSUSE_12.3: { base: [openSUSE_13.1], from: 'flavio/opensuse-12-3' }

"""

def yaml_load_expand(stream_thing):
  y = yaml.load(stream_thing)
  for k in y['target'].keys():
    t = y['target'][k]
    base_seen = []
    for depth in range(5):	# may be needed, if a base has anotherbase, we a parsing them in random order.
      if 'base' in t:
        t_base = t['base']
        del(t['base'])
        for b in t_base:
          if not b in base_seen:
            for bk in y['target'][b].keys():
              if not bk in t:
                t[bk] = y['target'][b][bk]
          base_seen.append(b)
  return y

default_obs_config = yaml_load_expand(default_obs_config_yaml)

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

  if os.getuid():
    # assert we run as root or have the docker group.
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


def docker_on_aufs():
  """ return true if docker is running with the Storage Backend aufs.
      AUFS has issues with setting filesystem capabilities, and thus
      e.g. httpd cannot be installed on a Fedora system inside docker.
  """
  # docker_info = run(["docker", "info"], redirect_stdout=True)
  # Storage Driver: aufs
  # if (re.search('^Storage\s+Driver:\s*aufs\s*$', docker_info, re.M)):
  #   using_aufs = True
  using_aufs = os.getenv('AUFS_HACK') or '0'
  if using_aufs != '0' and using_aufs != '':
    return True
  return False


def obs_fetch_bin_version(api, download_item, prj, pkg, target, retry=True):
  cfg = obs_download_cfg(obs_config['obs'][api], download_item, prj, urltest_target=None, verbose=False)
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
  if m: return (m.group(1),m.group(2),target)
  # owncloud-client_1.7.0_i386.deb
  m = re.search(r'^\s*'+re.escape(deb_pkg_name)+r'_(\d+[^_\s]*)_.*?\.deb$', bin_seen, re.M)
  if m: return (m.group(1),'',target)

  # cloudtirea-client-1.7.0-4.1.i686.rpm
  m = re.search(r'^\s*'+re.escape(args.package)+r'-(\d+[^-\s]*)\-([\w\.]+?)\.(x86_64|i\d86|noarch)\.rpm$', bin_seen, re.M)
  if m: return (m.group(1),m.group(2),target)
  if retry and re.match('^Ubuntu', target):
    print("retrying x"+target+" instead of "+target)
    return obs_fetch_bin_version(api, download_item, prj, pkg, 'x'+target, retry=False)

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
  raise ValueError("no config known for target '"+obs_target_name+"' - choose other obs target or update config in "+args.configfile)


def obs_download_cfg(config, download_item, prj_path, urltest_target=None, verbose=True):
  """
    prj_path is appended to url_cred, where all ':' are replaced with ':/'
    a '/' is asserted between url_cred and prj_path.
    url_cred is guaranteed to end in '/'
    url, username, password, are derived from url_cred.
    download_item: public, internal, ...
    urltest_target can be none, or an obs_target to test with the download url.

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

  if urltest_target is None: return data

  try:
    if verbose: print("testing "+data['url']+" ...")
    if 'username' in data and 'password' in data:
      uo = urlopen_auth(data['url'], data['username'], data['password'])
    else:
      uo = urllib2.urlopen(urllib2.Request(data['url']))
    text = uo.readlines()
    if not re.search(r'\b'+re.escape(urltest_target)+r'\b', str(text)):
      raise ValueError("urltest_target="+urltest_target+" not seen at "+data['url'])
    if verbose: print(" ... %d bytes read, containing '%s', good." % (len(str(text)), urltest_target))
  except Exception as e:
    if args.keep_going:
      print("WARNING: Cannot read "+data['url']+"\n"+str(e))
      print("\nTry a different --download option or wait 10 sec...")
      time.sleep(10)
    else:
      raise e

  return data

def matched_package_run_script(package_name, platform_name, pat_dict):
  """ pat_dict.key() '' is a special case. 
      It is the default that matches only when nothing lese matches.
  """ 
  match_list = []
  ret = None
  for pat in pat_dict.keys():
    if pat == '': continue
    # FIXME: should have package_version instead of package here.
    if re.search(pat, package_name):
      match_list.append(pat)
      ret = pat_dict[pat]
  if (len(match_list) > 1):
    print("ERROR: run("+package_name+") in 'target->"+platform_name+"' matches multiple patterns: ", match_list, file=sys.stderr)
    sys.exit(1)
  if (len(match_list) < 1):
    if '' in pat_dict.keys():
      ret = pat_dict['']
    else:
      print("Warning: run("+package_name+") in 'target->"+platform_name+"' matches no pattern: ", pat_dict.keys(), file=sys.stderr)
  return ret

################################################################################

start_script_pre = [] 
start_script_post = []
docker_cmd_clean_c=" docker ps -a  | grep Exited   | awk '{ print $1 }' | xargs -r docker rm"
docker_cmd_clean_i=" docker images | grep '<none>' | awk '{ print $3 }' | xargs -r docker rmi"
self_cmd = " ".join(sys.argv)

ap = ArgumentParser(
  formatter_class=RawDescriptionHelpFormatter,
  epilog="""Example:
 """+sys.argv[0]+""" isv:ownCloud:desktop owncloud-client CentOS_CentOS-6

 """+sys.argv[0]+""" isv:ownCloud:community:8.0 owncloud xUbuntu_14.10 -- run -ti -p 8888:80 @ /bin/bash /root/start.sh

Version: """+__VERSION__,
  description="Create docker images for RPM and DEB packages built with openSUSE Build Service (public or other instance).\nUse env AUFS_HACK=1 to circumvent libcap issues with docker running on aufs.\n"
)

ap.add_argument("-p", "--platform", dest="target", metavar="TARGET", help="obs build target name. Default: "+target)
ap.add_argument("-f", "--base-image", "--from", metavar="IMG", help="docker base image to start with. Exclusive with specifying a -p platform name")
ap.add_argument("-V", "--version", default=False, action="store_true", help="print version number and exit")
ap.add_argument("-d", "--download", default='public', metavar="SERVER", help='use a different download server. Try "internal" or a full url. Default: "public"')
ap.add_argument("-c", "--configfile", default='obs-docker.yaml', metavar="FILE", help='specify different config file. Default: generate a default file if missing, so that you can edit')
ap.add_argument("-W", "--writeconfig", default=False, action="store_true", help='Write a default config file and exit. Default: use existing config file')
ap.add_argument("-A", "--obs-api", help="Identify the build service. Default: guessed from project name")
ap.add_argument("-n", "--image-name", help="Specify the name for the docker image. Default: construct a name and print")
ap.add_argument("--dump", help="Dump an element from the yaml config. supported values: 'from', 'inst', 'pre', 'run', ...")
ap.add_argument("-I", "--print-image-name-only", default=False, action="store_true", help="construct a name and exit after printing")
ap.add_argument("-P", "--print-config-only", default=False, action="store_true", help="show the current project and target configuration and exit after printing. An optional target argument (see also -T) can be used to pretty print only one target configuration.")
ap.add_argument("-T", "--list-targets-only", default=False, action="store_true", help="show a list of configured build target names and exit after printing")
ap.add_argument("-e", "--extra-packages", help="Comma separated list of packages to pre-install. Default: only per 'inst' in the config file")
ap.add_argument("-q", "--quiet", default=False, action="store_true", help="Print less information while working. Default: babble a lot")
ap.add_argument("-k", "--keep-going", default=False, action="store_true", help="Continue after errors. Default: abort on error")
ap.add_argument("-N", "--no-operation", default=False, action="store_true", help="Print docker commands and instructions to create an image only. Default: create an image")
ap.add_argument("-D", "--dockerfile", default=False, action="store_true", help="Output dockerfile to stdout. Default: create an image")
ap.add_argument("-S", "--shell-script", "--script", default=False, action="store_true", help="Print out a shell script. Similar to the --dockerfile output.")
ap.add_argument("-R", "--rm", default=False, action="store_true", help="Remove intermediate docker containers after a successful build")
ap.add_argument("--no-cache", default=False, action="store_true", help="Do not use cache when building the image. Default: use docker cache as available")
ap.add_argument("--nogpgcheck", default=False, action="store_true", help="Ignore broken or missing keys. Default: yum check, zypper auto-import")
ap.add_argument("-X", "--xauth", default=False, action="store_true", help="Prepare a docker image that can connect to your X-Server.")
ap.add_argument("-C", "--cleanup", default=False, action="store_true", help="Run suggested docker cleanup.")
ap.add_argument("--ssh-server", default=False, action="store_true", help="Start an ssh login server with the default docker run CMD and start.sh script.")
ap.add_argument("project", metavar="PROJECT", nargs="?", help="obs project name. Alternate syntax to PROJ/PACK")
ap.add_argument("package", metavar="PACKAGE",  nargs="?", help="obs package name, or PROJ/PACK")
ap.add_argument("platform",metavar="PLATFORM", nargs="?", help="obs build target name. Alternate syntax to -p. Default: "+target)
args,run_args = ap.parse_known_args()  # --help is automatic
if len(run_args) and run_args[0] == '--':
  run_args = run_args[1:]

if args.version: ap.exit(__VERSION__)
if args.print_image_name_only or args.dockerfile or args.shell_script:
  args.quiet=True
  args.no_operation=True
if args.quiet: run.verbose=0

context_dir = tempfile.mkdtemp(prefix="obs_docker_install_context_")
docker_cmd_cmd="/bin/bash"
extra_docker_cmd = []
extra_packages = []
if args.extra_packages: extra_packages = re.split(r"[\s,]", args.extra_packages)

if args.cleanup:
  run.verbose = 2
  run(['sh', '-c', docker_cmd_clean_c], redirect=False)
  run(['sh', '-c', docker_cmd_clean_i], redirect=False)
  sys.exit(0)

if args.writeconfig:
  if os.path.exists(args.configfile):
    print("Will not overwrite existing "+args.configfile)
    print("Please use -c to choose a different name, or move the file away")
    sys.exit(1)
  cfp = open(args.configfile, "w")
  cfp.write(default_obs_config_yaml)
  # json.dump(default_obs_config, cfp, indent=4, sort_keys=True)
  # cfp.write("\n")
  cfp.close()
  print("default config written to " + args.configfile)
  sys.exit(0)

if not os.path.exists(args.configfile):
  if not args.dockerfile and not args.shell_script:
    print("Config file does not exist: "+args.configfile)
    print("Use -W to generate the file, or use -c to choose different config file")

  # either exit here, or be nice and use the builtin defaults.
  # sys.exit(1)
  obs_config = default_obs_config
else:
  try:
    cfp = open(args.configfile)
    obs_config = yaml_load_expand(cfp)
  except Exception as e:
    print("ERROR: loading "+args.configfile+" failed: ", e)
    print("")
    obs_config = default_obs_config

if args.print_config_only:
  import pprint
  if args.platform:
    cfg=obs_config['target'][args.platform]
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
    xx = re.sub("\n.*", "", xx)		# should be empty anyway, since we use 'pre' now.
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
obs_target = re.sub("@.*$", "", target)	# strip away @SCL or similar suffix.

if args.dump:
  cfg=obs_config['target'][target]
  if args.dump in cfg:
    if args.dump == 'run':	# this one matches package names.
      print(matched_package_run_script(args.package, target, cfg[args.dump]))
    else:
      print(cfg[args.dump])
  else:
    if not args.quiet:
      print("ERROR: " + args.dump + " not in 'target->" + target + "', try one of these:\n", cfg.keys(), file=sys.stderr)
  sys.exit(0)

obs_api=guess_obs_api(args.project, args.obs_api, not args.quiet)
try:
  version,release,obs_target=obs_fetch_bin_version(obs_api, args.download, args.project, args.package, obs_target)
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

# Do you know the ternary operator in python? Here is one:
download=obs_download_cfg(obs_config["obs"][obs_api], args.download, args.project, verbose=not args.quiet, urltest_target=None if args.no_operation else obs_target)

if args.image_name:
  image_name = args.image_name
else:
  image_name = args.package+'-'+version+'-'+release
  server=obs_config['obs'][obs_api]
  if 'aliases' in server and len(server['aliases']):
    server_name = server['aliases'][0]
  else:
    server_name = re.sub('^\w+://','', obs_api)
  image_name = image_name + '-' + server_name + '-' + args.project + '-' + target
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
  if re.search(r'suse', obs_target, re.I): 			extra_packages.extend(['xorg-x11-fonts-core'])
  if re.search(r'centos|rhel|fedora', obs_target, re.I): 	extra_packages.extend(['gnu-free-sans-fonts'])
  if re.search(r'ubuntu_1[4567]', obs_target, re.I):		extra_packages.extend(['fonts-dejavu-core'])

if args.ssh_server:
  if not args.quiet:
    print("Installing an ssh-server. To log in later without password, you can try 'docker run -v ~/.ssh/id_dsa.pub:/authorized_keys ... ' or similar.")
  docker_volumes.append('~/.ssh/id_dsa.pub:/authorized_keys')
  extra_docker_cmd.extend(['RUN mkdir /root/.ssh'])
  # tested with centos:
  extra_docker_cmd.extend(["RUN sed '/pam_loginuid.so/s/^/#/g' -i /etc/pam.d/*"])

  # add ssh server to start.sh and run cmd.
  start_script_post.extend(['chmod 700 /root/.ssh', 'chmod go-w /root', 'chmod 600 /root/.ssh/authorized_keys || true', 'cat /authorized_keys >> /root/.ssh/authorized_keys || true' ])
  if re.search(r'suse', obs_target, re.I):
    extra_packages.extend(['openssh'])
    docker_cmd_cmd='cat /authorized_keys >> /root/.ssh/authorized_keys || true; service sshd start ; ip a | grep global ; exec /bin/bash'
    start_script_post.extend(['service sshd start'])
  if re.search(r'centos|rhel|fedora', obs_target, re.I):
    extra_packages.extend(['openssh-server'])
    docker_cmd_cmd='cat /authorized_keys >> /root/.ssh/authorized_keys || true; service sshd start ; ip a | grep global ; exec /bin/bash'
    start_script_post.extend(['service sshd start'])
  if re.search(r'ubuntu|debian', obs_target, re.I):
    extra_packages.extend(['openssh-server'])
    docker_cmd_cmd='cat /authorized_keys >> /root/.ssh/authorized_keys || true; mkdir -p /var/run/sshd; /usr/sbin/sshd; ip a | grep global ; exec /bin/bash'
    start_script_post.extend(['mkdir -p /var/run/sshd', '/usr/sbin/sshd'])
  start_script_post.extend(['ip a | grep global'])


docker_run_int=["docker","run"]
atSign=False

if run_args and run_args[0]!="run":
  print("Keyword can only be 'run'")
  print("Usage: obs-docker-install ee:8.0 owncloud-enterprise xUbuntu_14.10 -- run -ti -p 8888:80 @ /bin/bash /root/start.sh")
  sys.exit(1)
for item in run_args[1:]: 
  if(item=='@'):
    atSign=True
    docker_run_int.append(image_name)
  else:
    docker_run_int.append(item)
if not atSign and run_args:
  # print("run: Use @ for ImageName after docker run options, and before docker run shell command.")
  # sys.exit(1)
  ## user normally does not provide an image name or command to run. We do that oourselves...
  ## CAUTION: Keep in sync with dockerfile+=ADD ... below
  docker_run_int.extend([image_name, '/bin/bash', '/root/start.sh'])
  
startfile=None
docker_run=["docker","run","-ti"]	# docker_run is printed as a hint only.
for vol in docker_volumes:
  docker_run.extend(["-v", vol])
docker_run.append(image_name)
if args.dockerfile or args.shell_script:
  print("# autogenerated by:  " + self_cmd)
else:
  print("#+ " + " ".join(docker_run))



## multi line docker commands are no longer supported in 'from', use 'pre'!
dockerfile = "FROM "+docker['from']+"\n"
dockerfile_tail = 'CMD '+docker_cmd_cmd+"\n"
run_script = None

if 'run' in obs_config['target'][target]:	# and not args.dockerfile:
  run_script=matched_package_run_script(args.package, target, obs_config['target'][target]['run'])

  if run_script:
    # FIXME: we should rather have a start.d/*.sh directory, than pasting it all together.
    if len(start_script_pre):  run_script = "\n".join(start_script_pre) + "\n" + run_script
    if len(start_script_post): run_script += "\n" + "\n".join(start_script_post) + "\n"
    run_script = run_script.format(Package=args.package, Platform=target, Project=args.project, ObsApi=obs_api)

    if not args.shell_script:
      script_commented = re.sub('^', '# ', run_script, flags=re.M)
      print("## run script /root/start.sh:\n" + script_commented + "\n##\n")
    startfile = context_dir+'/start.sh'
    f = open(startfile,'w')
    f.write(run_script)
    os.fchmod(f.fileno(),0o755)
    f.close()
    startfile = '/root/start.sh'
    # CAUTION: Keep in sync with docker_run_int.extend(image_name, ...) above
    if args.dockerfile or args.shell_script: dockerfile_tail += '# '
    dockerfile_tail += 'ADD ./start.sh /root/\n'
  
if 'pre' in docker:
  dockerfile += docker['pre']
  if not re.search(r'\n$', dockerfile):
    dockerfile += "\n"
dockerfile += "ENV TERM=ansi HOME=/root\n"


wget_cmd="wget -nv"
if "username" in download: wget_cmd+=" --user '"+download["username"]+"'"
if "password" in download: wget_cmd+=" --password '"+download["password"]+"'"
wget_cmd+=" "+download["url"]
if not re.search(r'/$', wget_cmd): wget_cmd+='/'

now=time.strftime('%Y%m%d%H%M')
start_time=time.time()
d_endl="\n"
if args.keep_going: d_endl = " || true\n"

# With image_name, caching depends on the build release number of the package.
# (Used to be a timestamp, which is too much.
if args.dockerfile or args.shell_script:
  run_nocache = 'RUN'
else:
  run_nocache = 'RUN image_name='+image_name

if docker["fmt"] == "APT":
  if args.nogpgcheck: print("Option nogpgcheck not implemented for APT")
  dockerfile += "ENV DEBIAN_FRONTEND=noninteractive\n"
  dockerfile += "RUN apt-get -q -y update"+d_endl
  if "inst" in docker and len(docker["inst"]):
    dockerfile += "RUN apt-get -q -y -V install "+" ".join(docker["inst"])+d_endl

  if docker_on_aufs() and 'aufs' in docker:
    dockerfile += docker['aufs']
    if not re.search(r'\n$', dockerfile): dockerfile += "\n"
  
  dockerfile += "RUN "+wget_cmd+obs_target+"/Release.key -O - | apt-key add -"+d_endl
  dockerfile += "RUN echo 'deb "+download["url_cred"]+"/"+obs_target+"/ /' >> /etc/apt/sources.list.d/"+args.package+".list"+d_endl
  dockerfile += "RUN apt-get -q -y update"+d_endl
  if extra_packages: 	dockerfile += "RUN apt-get -q -y -V install "+' '.join(extra_packages)+d_endl
  if extra_docker_cmd:	dockerfile += d_endl.join(extra_docker_cmd)+d_endl
  dockerfile += run_nocache +" apt-get -q -y update && apt-get -q -y -V install "+args.package
  dockerfile_tail += "RUN zcat /usr/share/doc/"+args.package+"/changelog*.gz  | head -20"+d_endl
  # dockerfile_tail += "RUN echo 'apt-get -V install "+args.package+"' >> ~/.bash_history"+d_endl


elif docker["fmt"] == "DNF":
  dnf_install = 'dnf install -y'
  if args.nogpgcheck: dnf_install += ' --nogpgcheck'
  dockerfile += "RUN dnf clean all"+d_endl 	#expire-cache"+d_endl
  if "inst" in docker and len(docker["inst"]):
    dockerfile += "RUN "+dnf_install+" "+" ".join(docker["inst"])+d_endl

  if docker_on_aufs() and 'aufs' in docker:
    dockerfile += docker['aufs']
    if not re.search(r'\n$', dockerfile): dockerfile += "\n"
  
  dockerfile += "RUN rpm --import "+download["url_cred"]+"/"+obs_target+"/repodata/repomd.xml.key"+d_endl
  dockerfile += "RUN "+wget_cmd+obs_target+'/'+args.project+".repo -O /etc/yum.repos.d/"+args.project+".repo"+d_endl
  if extra_packages:	dockerfile += "RUN "+dnf_install+" "+" ".join(extra_packages)+d_endl
  if extra_docker_cmd:	dockerfile += d_endl.join(extra_docker_cmd)+d_endl
  dockerfile += run_nocache+" "+dnf_install+" "+args.package
  dockerfile_tail += "RUN rpm -q --changelog "+args.package+" | head -20"+d_endl
  # dockerfile_tail += "RUN echo '"+dnf_install+" "+args.package+"' >> ~/.bash_history"+d_endl


elif docker["fmt"] == "YUM":
  yum_install = 'yum install -y'
  if args.nogpgcheck: yum_install += ' --nogpgcheck'
  dockerfile += "RUN yum clean all"+d_endl 	#expire-cache"+d_endl
  if "inst" in docker and len(docker["inst"]):
    dockerfile += "RUN "+yum_install+" "+" ".join(docker["inst"])+d_endl

  if docker_on_aufs() and 'aufs' in docker:
    dockerfile += docker['aufs']
    if not re.search(r'\n$', dockerfile): dockerfile += "\n"
  
  dockerfile += "RUN rpm --import "+download["url_cred"]+"/"+obs_target+"/repodata/repomd.xml.key"+d_endl
  dockerfile += "RUN "+wget_cmd+obs_target+'/'+args.project+".repo -O /etc/yum.repos.d/"+args.project+".repo"+d_endl
  if extra_packages:	dockerfile += "RUN "+yum_install+" "+" ".join(extra_packages)+d_endl
  if extra_docker_cmd:	dockerfile += d_endl.join(extra_docker_cmd)+d_endl
  dockerfile += run_nocache+" yum clean all && "+yum_install+" "+args.package
  dockerfile_tail += "RUN rpm -q --changelog "+args.package+" | head -20"+d_endl
  # dockerfile_tail += "RUN echo '"+yum_install+" "+args.package+"' >> ~/.bash_history"+d_endl

elif docker["fmt"] == "ZYPP":
  if args.nogpgcheck: print("Option nogpgcheck not implemented for ZYPP")
  dockerfile += "RUN zypper --non-interactive --gpg-auto-import-keys refresh"+d_endl
  if "inst" in docker and len(docker["inst"]):
    dockerfile += "RUN zypper --non-interactive --gpg-auto-import-keys install "+" ".join(docker["inst"])+d_endl

  if docker_on_aufs() and 'aufs' in docker:
    dockerfile += docker['aufs']
    if not re.search(r'\n$', dockerfile): dockerfile += "\n"
  
  dockerfile += "RUN zypper --non-interactive --gpg-auto-import-keys addrepo "+download["url_cred"]+obs_target+"/"+args.project+".repo"+d_endl
  if extra_packages:	dockerfile += "RUN zypper --non-interactive --gpg-auto-import-keys install "+" ".join(extra_packages)+d_endl
  if extra_docker_cmd:	dockerfile += d_endl.join(extra_docker_cmd)+d_endl

  dockerfile += run_nocache+" zypper --non-interactive --gpg-auto-import-keys refresh && zypper --non-interactive --gpg-auto-import-keys install "+args.package
  dockerfile_tail += "RUN rpm -q --changelog "+args.package+" | head -20"+d_endl
  # dockerfile_tail += "RUN echo 'zypper install "+args.package+"' >> ~/.bash_history"+d_endl

else:
  raise ValueError("dockerfile generator not implemented for fmt="+docker["fmt"])

if args.xauth:
  dockerfile_tail += "ENV DISPLAY=unix:0 XDG_RUNTIME_DIR=/run/user/1000 XAUTHORITY="+xauthfile+"\n"
  dockerfile_tail += 'RUN : "'+xa_cmd+'"'+"\n"

# dockerfile_ign has the most-likely-command-to-fail wrapped with '|| true', so that it does not bail out.
dockerfile_ign = dockerfile + " || true" + d_endl + dockerfile_tail
dockerfile     = dockerfile +              d_endl + dockerfile_tail


if args.dockerfile or args.shell_script:
  run(['rm', '-rf', context_dir])
  if args.shell_script:
    # convert the dockerfile into a shell script
    dockerfile = re.sub('^FROM(.*)', 'docker run -ti\\1 /bin/bash', dockerfile)
    dockerfile = re.sub('^ENV\s+', 'export ', dockerfile, flags=re.M)
    dockerfile = re.sub('^RUN\s+', '', dockerfile, flags=re.M)
    dockerfile = re.sub('^CMD .*', '', dockerfile, flags=re.M)
    dockerfile = re.sub('^(#\s+)?ADD .*', '', dockerfile, flags=re.M)
    if run_script:
      dockerfile += "\n\n## run script /root/start.sh:\n" + run_script
  print(dockerfile)
  sys.exit(0)

# print(obs_api, download, image_name, target, docker)

r=0
docker_build=["docker", "build"]
if args.rm: docker_build.append("--rm")
if args.quiet: docker_build.append("-q")
if args.no_cache: docker_build.append("--no-cache")
docker_build.extend(["-t", image_name, context_dir])


if args.no_operation:
  run(['rm', '-rf', context_dir])
  print(dockerfile)
  docker_build[-1] = '"dirname(Dockerfile)"'
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
  if not args.quiet:	# FIXME: quiet also suppresses the rebuild on error??
    if r:
      print("Failed with non-zero exit code="+str(r)+". Check for errors in the above log.\n")
      run_args = None

      fd=open(context_dir+"/Dockerfile", "w")
      fd.write(dockerfile_ign) 		# fallback to the error-ignoring Dockerfile
      fd.close()
      r2 = run(docker_build, redirect_stdout=False, redirect_stderr=False, return_code=True)
      if not r2:
        print("\n\nERROR: Image build failed. Rebuilt ignoring errors.  Try to rerun the last command from the shell inside\n "+" ".join(docker_run)+"\n\n")

    else:
      print("Image successfully created. Check for warnings in the above log.\n")
  run(['rm', '-rf', context_dir])

print(time.strftime("build time: %H:%M:%S", time.gmtime(time.time()-start_time)))

if not args.rm and not r and not args.quiet:
  print("You may remove unused container/images with e.g.\n "+docker_cmd_clean_c+"\n "+docker_cmd_clean_i+"\n")

if not r and not run_args:
  if startfile is not None:
    docker_run.extend(['bash', '--rcfile', startfile])
  print("You can run the new image with:\n "+" ".join(docker_run))

#if args.run:
#  if re.search(r'[\s;&<>"]', args.run[0]): args.run=['/bin/bash', '-c', " ".join(args.run)]
if run_args:
  if run_args[0]=="run":
    r = run(docker_run_int, redirect_stderr=False, redirect_stdout=False, return_code=True)
  else:
    print("Keyword can only be 'run', not ", run_args)
    print("Usage: obs-docker-install ee:8.0 owncloud-enterprise "+target+" -- run -ti -p 8888:80 [@ /bin/bash /root/start.sh]")
sys.exit(r)
