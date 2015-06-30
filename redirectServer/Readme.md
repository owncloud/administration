# Redirect for Multi Tenancy installations

You can setup a central server, which dispatches connections to the right ownCloud instance, e.g. based on the username.
Consider several ownClouds running under subdomains or pathes like

* https://instance1.domain.com
* https://instance2.domain.com
* https://instance3.domain.com

while the user doesn't know about the instances and only sees the central server

* https://domain.com

The idea is, an ownCloud user with an login name ```felix@instance2.domain.com``` gets redirected to use the  ```https://instance2.domain.com``` automatically.

The redirects need to be done for the web frontend, desktop sync clients and mobile apps.

## Sync client and mobile apps

On connection the clients are requesting

1. status.php
2. remote.php/webdav

with an authentication attempt in the second.

The ```status.php``` needs to be on the central server, just to proceed with the authentication.
Now in ```remote.php``` the username can be evaluated to distinguish the correct instance and redirect.

All you need on the central server are those two files, and you can customize the code for the selection of the instances.

## Web frontend

Needs to be done.

## Example

The code is running in an example deployment.

You can connect with a sync client to the central redirect server: 

```
https://owncloud.achernar.uberspace.de
```

Possible usernames:

* test@instance1.com
* test@instance2.com
* test@instance3.com

which get redirected to ```https://owncloud.achernar.uberspace.de/instanceX```.
Password is: ```secret```.

Try with curl:

```
curl -v -L -u'test@instance3.com:secret' https://owncloud.achernar.uberspace.de/remote.php/webdav/
```
