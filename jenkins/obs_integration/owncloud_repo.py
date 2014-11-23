#!/usr/bin/python
#
# owncloud_repo.py -- tool to find and register a linux repository
#
# (C) 2014 jw@owncloud.com
#

import os, re

def describe_system():
  """
  Return a string that describes the system type we are runnung on.
  """
  try:
    os_release = ''.join(open('/etc/os-release').readlines())
    cpe_name = re.search('.*?(cpe:/[^"]+)', os_release, re.M)
    if cpe_name: return cpe_name.group(1) + ' FROM /etc/os-release'
    name    = re.search('NAME\s*=[\s"\']*(.*)', os_release, re.M)
    version = re.search('VERSION.*(\d+\.\d+)', os_release, re.M)
    if name and version:
      return name.group(1) + ':' + version.group(1) + ' FROM /etc/os-release'
  except:
    pass
  
  return 'Unknown'



def best_obs_target(system_description=None):
  """
  Map a system description string to one of the known 
  build targets in obs / s2.

  valid descriptions include CPE_NAME
  """
  if system_description is None: system_description = describe_system()

  # 'cpe:/o:opensuse:opensuse:13.1'
  m = re.match('cpe:.*opensuse.*:(\d+\.\d+)', system_description, re.I)
  if m: return 'openSUSE:'+m.group(1)

  # no mapping matched? try to return a prefix without whitespace
  system_description = re.sub('\s.*', '', system_description)
  return system_description


if __name__ == '__main__':
  print best_obs_target()
