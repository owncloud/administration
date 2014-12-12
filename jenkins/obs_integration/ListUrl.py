#!/usr/bin/python
#
# (c) 2014 jw@owncloud.com
# Distribute under GPLv2 or ask
#
# pull (recursive) listings from apache index pages

import re,requests

class ListUrl:

  def _apache_index(self, url):
    r = requests.get(url)
    if r.status_code != 200:
      raise ValueError(url+" status:"+str(r.status_code))
    r.dirs = []
    r.files = []
    for l in r.content.split("\n"):
      # '<img src="/icons/folder.png" alt="[DIR]" /> <a href="7.0/">7.0/</a>       03-Dec-2014 19:57    -   '
      # ''<img src="/icons/tgz.png" alt="[   ]" /> <a href="owncloud_7.0.4-2.diff.gz">owncloud_7.0.4-2.diff.gz</a>                     09-Dec-2014 16:53  9.7K   <a href="owncloud_7.0.4-2.diff.gz.mirrorlist">Details</a>'
      # 
      m = re.search("<a\s+href=[\"']?([^>]+?)[\"']?>([^<]+?)[\"']?</a>\s*([^<]*)", l, re.I)
      if m:
	# ('owncloud_7.0.4-2.diff.gz', 'owncloud_7.0.4-2.diff.gz', '09-Dec-2014 16:53  9.7K   ')
	m1,m2,m3 = m.groups()

	if re.match("(/|\?|\w+://)", m1):	# skip absolute urls, query strings and foreign urls
	  continue
	if re.match("\.?\./?$", m1):	# skip . and ..
	  continue

	m3 = re.sub("[\s-]+$", "", m3)
	if re.search("/$", m1):
	  r.dirs.append([m1, m3])
	else:
	  r.files.append([m1, m3])
    return r

  def apache(self, url, pre=''):
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

def list(url, callback=None, recursive=True):
  lu = ListUrl(callback=callback, recursive=recursive)
  lu.apache(url)

if __name__ == '__main__':
  import sys

  def print_hook(url, path, name, extra):
    print path+name+"\t"+extra

  list(sys.argv[1], callback=print_hook)

