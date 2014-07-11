#!/usr/bin/python

import jenkinsapi
from jenkinsapi.jenkins import Requester
from jenkinsapi.jenkins import Jenkins
from pprint import pprint
import base64,os,ConfigParser

cp = ConfigParser.ConfigParser()
cp.read(os.path.expanduser('~/.jenkins'))
cfg=dict(cp.items('api'))
cfg['password']=base64.decodestring(cfg['xpassword'])

j = Jenkins(cfg['baseurl'], username=cfg['username'], password=cfg['password'], requester=Requester(cfg['username'],cfg['password'], baseurl=cfg['baseurl'], ssl_verify=False))

print(cfg['baseurl'])
for nodename in ('new-mac-builder', 'Solid Gear Mac'):
  print(" node %s is" % nodename),
  node = j.get_node(nodename)
  if node.is_idle(): print(" idle"),
  if node.is_online(): print(" online"),
  if node.is_temporarily_offline(): print(" offline"),
  print(".")
