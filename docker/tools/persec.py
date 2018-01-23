#! /usr/bin/python
#
# persec.py - a tool to add rate info (difference per second) to a tabular listings containing numeric column
# it looks for a tmp file from a previous run. If found, it generates an additional column
# using the precise time stamp of the tmp file to measure the elaped time since the last call.
# Then it compute the diffs on that column.
#
# See also: smartctl
#
# (C) 2018 jw@owncloud.com
# Distribute under GPLv2 or ask
#
# Example usage:
#
# smartctl -A /dev/sda | persec -c 10
# diskerrors | persec -c 5
#
############
#
# v0.1 2018-01-23, jw@owncloud.com
#		initial draught
#
############
from __future__ import print_function	# python2/3 compatibility
import sys, os, re
import argparse, hashlib, json, time

fd = sys.stdin
ratecol = 10
ratefmt="%8.1f%s/s"
rateunit=""
ratediv=1
ratename="RATE"

parser = argparse.ArgumentParser(
                usage="\n\tsmartctl -A /dev/sda | %(prog)s [-c 10]\n\twatch -n 9 'diskerrors | %(prog)s -c 5'",
                description='Prepend namespace/docker info to tabular output containing PIDs.')
parser.add_argument('--column', '-c', metavar='RATECOL', type=int,
                    help='column where numeric data is to be diffed. Default=10.', default=ratecol)
parser.add_argument('--unit', '-u', metavar='RATEUNIT',
                    help='unit for the rate format. Possible units start with K, M or G. The numeric value is divided by powers of 1024 according to the first letter. Default as is.', default=rateunit)
parser.add_argument('--name', '-n', metavar='HEADER',
                    help='title for the added column if the first line is a (non-numeric) header line. Default="RATE"', default=ratename)
parser.add_argument('--fmt', '-f', metavar='RATEFMT',
                    help='Format string for the rate column. Default="%%8.1f%%s/s"', default=ratefmt)

if fd.isatty():
  parser.print_help()
  sys.exit(1)
args = parser.parse_args()
ratecol = args.column
ratefmt = args.fmt
rateunit = args.unit
ratename = args.name

if   rateunit == '':  ratediv=1
elif rateunit[0].upper() == 'K': ratediv=1024
elif rateunit[0].upper() == 'M': ratediv=1024*1024
elif rateunit[0].upper() == 'G': ratediv=1024*1024*1024
else:
  parser.print_help()
  print("\nUnknown unit "+rateunit+" -- try something with K, M or G", file=sys.stderr)
  sys.exit(1)

pat = re.compile('((?:\s*\S+\s+){%d}\s*)(\S+)(.*)' % (ratecol-1))

tstamp = time.time()
file = { 'lines': [],  'tstamp': tstamp, 'maxlen': 0, 'ratecol': ratecol, 'ratefmt': ratefmt, 'values': [] }
lnr = 0
for line in fd:
  line = line.rstrip()
  m = re.match(pat, line)
  value = None
  try:
    value = int(m.group(2))
  except:
    pass
  if len(line) > file['maxlen']:
    file['maxlen'] = len(line)
  if value == None and lnr == 0:
    file['values'].append(ratename)
  else:
    file['values'].append(value)
  file['lines'].append(line)
  lnr += 1

envtext = ''
for e in sorted(os.environ.keys()):
  envtext += e+ "=" + os.environ[e] + "\n"
for a in sys.argv:
  envtext += a + "\n"
tmpname="/tmp/persec."+hashlib.md5(envtext).hexdigest()[:10]+".tmp"

try:
  with open(tmpname) as ifd:
    oldfile = json.load(ifd)
except:
  oldfile = None

with open(tmpname, "wb") as ofd:
  json.dump(file, ofd)

if oldfile is None:
  for line in file['lines']:
    print(line)
else:
  for n in range(len(file['lines'])):
    lfmt = "%-"+str(file['maxlen'])+"s"
    try:
      rate = oldfile['values'][n]
      rate = int(rate)
      dt = tstamp - oldfile['tstamp']
      if dt == 0.0: rate = None
      rate = (file['values'][n]-rate)/dt/ratediv
      fmt = lfmt+" "+ratefmt
    except:
      if rate is None: rate = '-'
      rate=str(rate)
      fmt = lfmt+" %s%0.0s"	# %0.0s is a trick to hide the unit in the header...
    print(fmt % (file['lines'][n], rate, rateunit))

msg = "\n# using "+tmpname
if oldfile is not None:
  msg += " age: %.1f sec" % (tstamp - oldfile['tstamp'])
print(msg)	# unless quiet
