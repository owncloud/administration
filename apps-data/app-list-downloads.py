#!/usr/bin/python
#
# app-list-downloads.py retrieves the details for one app from the database
# and prints it out as a json file.
# 
# Prerequisites:
#  yum install MySQL-python
#  apt in python-mysqldb

import MySQLdb
import sys
import json
from ConfigParser import ConfigParser

cfg = ConfigParser()
cfg.read('database.cfg')

try:
  appname = sys.argv[1]
except:
  appname = 'Tasks'

# Example output for 'Tasks' as seen 2017-01-31:
# [
#   {
#     "url": "http://apps.owncloud.com/CONTENT/content-files/164356-tasks.zip", 
#     "compat": [ "9.1", "9.2" ], "version": "0.9.4"
#   },
#   {
#     "url": "https://github.com/owncloud/tasks/releases/download/v0.6/tasks.zip", 
#     "compat": [ "8.0", "8.0" ], "version": "0.6"
#   },
#   {
#     "url": "https://github.com/owncloud/tasks/releases/download/v0.5/tasks.zip", 
#     "compat": [ "7.0", "7.0" ], "version": "0.5"
#   },
#   {
#     "url": "https://github.com/owncloud/tasks/releases/download/v0.8/tasks.zip", 
#     "compat": [ "8.1", "8.1" ], "version": "0.8"
#   },
#   {
#     "url": "https://github.com/owncloud/tasks/releases/download/v0.8.1/tasks.zip", 
#     "compat": [ "8.2", "8.2" ], "version": "0.8.1"
#   },
#   {
#     "url": "https://github.com/owncloud/tasks/releases/download/v0.9.2/tasks.zip", 
#     "compat": [ "9.0", "9.0" ], "version": "0.9.2"
#   }
# ]

default_dl = 'apps.owncloud.com/CONTENT/content-files/'

ver_map = {
  12: '9.1',
  13: '9.2',
  200: '7.0',
  300: '8.0',
  400: '8.1',
  500: '8.2',
  600: '9.0',
  700: '9.1',
  800: '9.2',
}

db = MySQLdb.connect(
	cfg.get('database', 'db_host'), 
	cfg.get('database', 'db_user'), 
	cfg.get('database', 'db_pass'), 
	cfg.get('database', 'db_name'))

cursor = db.cursor(MySQLdb.cursors.DictCursor)
cursor.execute("""SELECT id, user, type, version, 
	download1, downloadlink1, depend, depend2,
	downloadlink2,  downloadversion2,  downloadfiletype2,
	downloadlink3,  downloadversion3,  downloadfiletype3,
	downloadlink4,  downloadversion4,  downloadfiletype4,
	downloadlink5,  downloadversion5,  downloadfiletype5,
	downloadlink6,  downloadversion6,  downloadfiletype6,
	downloadlink7,  downloadversion7,  downloadfiletype7,
	downloadlink8,  downloadversion8,  downloadfiletype8,
	downloadlink9,  downloadversion9,  downloadfiletype9,
	downloadlink10, downloadversion10, downloadfiletype10,
	downloadlink11, downloadversion11, downloadfiletype11,
	downloadlink12, downloadversion12, downloadfiletype12,
	name FROM content WHERE name = %s""", (appname,))
row = cursor.fetchone()
db.close()
dl = [ 
       { 
         'version': row['version'],
         'url': row['downloadlink1'] + default_dl + row['download1'],
	 'compat': [ ver_map[row['depend']], ver_map[row['depend2']] ]
       }
     ]
for i in range(2, 13):
  if row['downloadfiletype'+str(i)]:
    dl.append({ 
      'version': row['downloadversion'+str(i)].strip('v'),
      'url':     row['downloadlink'+str(i)],
      'compat':  [ ver_map[row['downloadfiletype'+str(i)]] ] * 2
    })
	 

print json.dumps(dl, ensure_ascii=True, sort_keys=True, indent=2)

