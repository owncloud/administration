#!/usr/bin/python
#
# owncloud_repo.py -- tool to find and register a linux repository
#
# (C) 2014 jw@owncloud.com
#
# 2014-11-23, jw -- Can print matching build target name 
#                   for the current system.

import os, re

def describe_system():
  """
  Return a string that describes the system type we are running on.
  Taken from the ususal suspects in /etc/*-release
  """

  try:
    # ubuntu-12.04, fedora-20, centos-7, opensuse-11.4, debian-7
    os_release = ''.join(open('/etc/os-release').readlines())
    cpe_name = re.search('.*?(cpe:/[^"]+)', os_release, re.M)
    if cpe_name: return cpe_name.group(1) + ' FROM /etc/os-release'
    # NAME="Debian GNU/Linux"
    # NAME=openSUSE
    name    = re.search('^NAME\s*=[\s"\']*([^"\'\s]*)', os_release, re.M)
    version = re.search('^VERSION.*?(\d+(\.\d+)?)', os_release, re.M)
    if name and version:
      return name.group(1) + ':' + version.group(1) + ' FROM /etc/os-release'
  except:
    pass

  try:
    suse_release = ''.join(open('/etc/SuSE-release').readlines())
    # openSUSE 11.4 (x86_64)
    # VERSION = 11.4
    # CODENAME = Celadon
    version = re.search('opensuse\s.*?(\d+(\.\d+)?)', suse_release, re.I)
    if version: return 'openSUSE:'+version.group(1)
  except:
    pass

  try:
    centos_release = ''.join(open('/etc/centos-release').readlines())
    # CentOS release 6.6 (Final)
    # CentOS Linux release 7.0.1406 (Core)
    version = re.match('centos\s.*?(\d+(\.\d+)?)', centos_release, re.I)
    if version: return 'CentOS:'+version.group(1)
  except:
    pass

  try:
    fedora_release = ''.join(open('/etc/fedora-release').readlines())
    # Fedora release 20 (Heisenbug)
    version = re.match('fedora\s.*?(\d+(\.\d+)?)', fedora_release, re.I)
    if version: return 'Fedora:'+version.group(1)
  except:
    pass

  try:
    debian_version = ''.join(open('/etc/debian_version').readlines())
    # 6.0.10
    version = re.match('.*?(\d+(\.\d+)?)', debian_version, re.I)
    if version: return 'Debian:'+version.group(1)
  except:
    pass

  return 'Unknown'



def best_obs_target(system_description=None, use_colon=False):
  """
  Map a system description string to one of the known 
  build targets in obs / s2.

  valid descriptions include CPE_NAME
  """
  if system_description is None: system_description = describe_system()
  sep_u = '_'
  sep_m = '-'
  if use_colon: sep_m = sep_u = ':'

  # "cpe:/o:opensuse:opensuse:13.1"
  # "cpe:/o:fedoraproject:fedora:20"
  # "cpe:/o:centos:centos:7"
  m = re.match('cpe:.*?(\w+):(\d+(\.\d+)?)', system_description, re.I)
  if m: 
    name=m.group(1).capitalize()
    if m.group(1) == 'opensuse': name='openSUSE'
    if m.group(1) == 'fedora':   name='Fedora'
    if m.group(1) == 'centos':   
      name='CentOS'
      return [ name+sep_u+m.group(2), name+sep_u+name+sep_m+m.group(2) ]
    return [ name+sep_u+m.group(2) ]

  m = re.match('CentOS.*?((\d+)(\.\d+)?)', system_description, re.I)
  # centos 7 is written as Centos_7, but centos 6 is written as CentOS_CentOS-6 
  # two digit versions don't currently exist.
  if m: return [ 'CentOS_CentOS'+sep_m+m.group(1), 'CentOS_CentOS'+sep_m+m.group(2), 
                 'CentOS'+sep_u+m.group(1), 'CentOS'+sep_m+m.group(2) ]

  m = re.match('Ubuntu.*?((\d+)(\.\d+)?)', system_description, re.I)
  if m: return [ 'xUbuntu'+sep_u+m.group(1), 'Ubuntu'+sep_u+m.group(1) ]

  # no mapping matched? try to return a prefix without whitespace
  system_description = re.sub('\s.*', '', system_description)
  if use_colon:
    system_description = re.sub('_', ':', system_description)
  else:
    system_description = re.sub(':', '_', system_description)
  return [ system_description ]


if __name__ == '__main__':
  print best_obs_target()
