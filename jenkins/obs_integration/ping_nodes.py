#!/usr/bin/python
#
# (c) 2014 jw@owncloud.com
# GPLv2.0 or ask.
################################
# https://python-jenkins.readthedocs.org/en/latest/

import jenkinsapi
from jenkinsapi.jenkins import Requester
from jenkinsapi.jenkins import Jenkins
from pprint import pprint
import base64,os,ConfigParser

cp = ConfigParser.ConfigParser()
cp.read(os.path.expanduser('~/.jenkins'))
cfg=dict(cp.items('api'))
if not cfg.has_key('password'): cfg['password']=base64.decodestring(cfg['xpassword'])
# API docs say this should work, too. It does not.
# cfg['password']=cfg['token']

j = Jenkins(cfg['baseurl'], username=cfg['username'], password=cfg['password'], requester=Requester(cfg['username'],cfg['password'], baseurl=cfg['baseurl'], ssl_verify=False))

print(cfg['baseurl'])
for nodename in ('new-mac-builder', 'Solid Gear Mac'):
  print(" node %s is" % nodename),
  node = j.get_node(nodename)
  if node.is_idle(): print(" idle"),
  if node.is_online(): print(" online"),
  if node.is_temporarily_offline(): print(" offline"),
  print(".")
