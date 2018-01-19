#! /usr/bin/python
#
# nsinfo.py - a tool to add namespace information (docker containers) to tabular listings containing a column with PIDs
#
# Feature to use with ps output: if there is the word pid in the first line of the output, this column is the
# the one for the process ids, unless -c N is specified.
# The default output is adding a columns NSPID NSSID, plus a third column DOCKER, if docker ps returns a list
# of running containers.
#
# See also: namespaces(7), nsenter(1), setns(2)
#
# (C) 2018 jw@owncloud.com
# Distribute under GPLv2 or ask
#
# Example usage:
#
# ps aux | nsinfo -c 2
#  CONTAINER       NSPID  NSSID USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
#                               root         1  0.0  0.0 185724  5112 ?        Ss   Jan01   0:52 /sbin/init splash
#  wizardly_lewin     12  23821 root      3111  0.0  0.0   4204   832 pts/4    S    23:34   0:00 sleep 21000
#  wizardly_lewin     11  23821 root      3110  0.0  0.0   4204   724 pts/4    S    23:34   0:00 sleep 21234
#  kickass_lumiere     8  16881 root      4698  0.0  0.0   4204   824 pts/2    S+   22:59   0:00 sleep 3455
#                               root      1927  0.0  0.0  90720  3988 ?        S    23:00   0:00 /usr/sbin/CRON -f
#                               testy    16830  0.0  0.2 282056 17952 pts/0    Sl+  19:27   0:00 docker run -ti opensuse:42.3 bash
#  kickass_lumiere     1  16881 root     16881  0.0  0.0  20008  3036 pts/2    Ss   19:27   0:00 bash
#                               testy    16919  0.0  0.0  23508  4584 pts/3    Ss   19:28   0:00 bash
#                               testy    23763  0.0  0.2 357708 20692 pts/3    Sl+  21:11   0:00 docker run -ti opensuse:42.3 bash
#  wizardly_lewin      1  23821 root     23821  0.0  0.0  20012  3136 pts/4    Ss+  21:11   0:00 bash
#                               testy    24688  0.0  0.0   4368   564 ?        S    Jan04   0:00 /usr/sbin/rfkill event
#
# using
#  cat /proc/3111/status | grep NS
#  NStgid: 3111    12
#  NSpid:  3111    12
#  NSpgid: 3111    12
#  NSsid:  23821   1
#
#
############
#
# v0.1 2018-01-17, jw@owncloud.com
#		initial draught
# v0.2 2018-01-18, jw@owncloud.com
#		python3 compatibility, getppid() added for recursive container name lookup.
#
############
from __future__ import print_function	# python2/3 compatibility
import sys, os, re
import argparse

fd = sys.stdin
pidcol = 2
trunccol = 0

parser = argparse.ArgumentParser(
                usage="\n\tps -ef | %(prog)s [-c 2] | egrep '^\S'",
                description='Prepend namespace/docker info to tabular output containing PIDs.')
parser.add_argument('--column', '-c', metavar='PIDCOL', type=int,
                    help='column where process IDs are found. Default=2.', default=pidcol)
parser.add_argument('--nowrap', '-t', action='store_true',
                    help='Do not wrap long lines, truncate at $COLUMNS .')
parser.add_argument('--container-id', '-i', action='store_true',
                    help='Print docker container IDs. Default: names.')

if fd.isatty():
  parser.print_help()
  sys.exit(1)
args = parser.parse_args()
pidcol = args.column
if args.nowrap:
  if not 'COLUMNS' in os.environ:
    try:
      tput_cols = os.popen("tput cols").read().rstrip()
      os.environ['COLUMNS'] = str(int(tput_cols))
    except:
      pass
  if not 'COLUMNS' in os.environ:
    print("Option --nowrap needs tput installed or environment variable $COLUMNS. Try\nexport COLUMNS", file=sys.stderr)
    sys.exit(1)
if args.nowrap:
  try:
    trunccol = int(os.environ['COLUMNS'])
  except:
    pass

pat = re.compile('((?:\s*\S+\s+){%d}\s*)(\S+)(.*)' % (pidcol-1))

def getppid(pid):
  try:
    fd = open("/proc/%s/status" % pid)
    for line in fd:
      m = re.match(r'^PPid:\s+(\d+)', line)
      if m:
        return int(m.group(1))
  except:
    pass
  return 0

def getnsinfo(pid):
  nspid = 0
  nssid = 0
  try:
    fd = open("/proc/%s/status" % pid)
    for line in fd:
      m = re.match(r'^NSpid:\s+\d+\s+(\d+)', line)
      if m: nspid = int(m.group(1))
      m = re.match(r'^NSsid:\s+(\d+)', line)
      if m: nssid = int(m.group(1))
      if nspid > 0 and nssid > 0: break
    fd.close()
  except:
    pass
  return (nspid,nssid)

def getdockerinfo():
  """
  Returns a dictionary where keys are NSPIDs of running containers and values
  are lists of [ CONTAINER_ID, NAME ]
  Example:
   {16881: ['3ed92b04990f', 'kickass_lumiere'], 23821: ['83c76bdc8aa8', 'wizardly_lewin']}
  """
  try:
    fd = os.popen("docker ps -q")
    containers = fd.read().split()
    fd.close()
    info = {}
    for container in containers:
      fd = os.popen("docker inspect %s --format='{{.State.Pid}} {{.Name}}'" % container)
      inspect = fd.read().split(None,2)
      fd.close
      info[int(inspect[0])] = [ container, inspect[1].lstrip('/') ]
    return info
  except:
    return None

dinfo = getdockerinfo()
dinfo_fmt = "%-13.13s"
if not args.container_id:
  l = 0
  for v in dinfo.values():
    if len(v[1]) > l: l = len(v[1])
  dinfo_fmt = "%%-%d.%ds" % (l+1,l+1)

lnr = 0
for line in fd:
  line = line.rstrip()
  if pidcol == 0:
    print("autopidcol not implemented")
    sys.exit(1)
  m = re.match(pat, line)
  try:
    pid = int(m.group(2))
  except:
    pid = 0
  nspid,nssid = getnsinfo(pid)
  pre = "%6d %6d" % (nspid,nssid)
  if nspid == 0:
    if  lnr == 0:
      pre = " NSPID  NSSID"
    else:
      pre = "             "
  if dinfo:
    dnssid = nssid
    while dnssid > 1 and dnssid not in dinfo:
      dnssid = getppid(dnssid)
    if dnssid in dinfo:
      container = dinfo[dnssid][0 if args.container_id else 1]
      if dnssid != nssid: container = container+"*"
      pre0 = dinfo_fmt % container
    else:
      if lnr == 0:
        pre0 = dinfo_fmt % "CONTAINER"
      else:
        pre0 = dinfo_fmt % " "
    pre = pre0 + pre
  line = pre + " " + line
  if trunccol > 0: line = line[:trunccol]
  print(line)
  lnr += 1
