# Redirect for Multi Tenancy installations

You can setup a central server, which dispatches connections to the right ownCloud instance, e.g. based on the username.
Consider several ownClouds running under subdomains or pathes like

* https://instance1.domain.com
* https://instance2.domain.com
* https://instance3.domain.com

while the user doesn't know about the instances and only sees the central server

* https://domain.com

The idea is, an ownCloud user with an login name ```felix@instance2.domain.com``` gets redirected to use the  ```https://instance2.domain.com``` automatically.

The redirects can be done for desktop sync clients and mobile apps.

## Sync Client

On connection the clients are requesting

1. status.php
2. remote.php/webdav

with an authentication attempt in the second.

The ```status.php``` needs to be on the central server, just to proceed with the authentication.
Now in ```remote.php``` the username can be evaluated to distinguish the correct instance and redirect.

All you need on the central server are those two files, and you can customize the code for the selection of the instances.

##  Mobile Apps

Released versions with this included.
* Android: 1.7.2 version
* iOS: 3.4.4 version

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

Or try with curl:

```
curl -v -L -u'test@instance3.com:secret' https://owncloud.achernar.uberspace.de/remote.php/webdav/
```

## Flow Sequence Diagram (Desktop 2.7)

![Sequence Diagram](http://www.plantuml.com/plantuml/png/hP9FRzf04CNlV8eHf_PW5YXIAwkjaYPDXGe98aLSV9ci9sMLzUvg_nZHJz-rmOrHJTGalS3wQUOtRtVUcVDeVIXa3xdN5iwbuDGpKHDS65GUBgIW-8SE-fVa7hms1wb_L3RJ-Y6Okknml2LRaitKndlZKiPaBGzSBGy6xBX_gfn7nQacwAswa3haVzH7YZWeRKwlTWt9vyPi2l6NBEnhOBMSdRRHwnsQOll1UGhVllxugoFMnj4-k87PcARfOv8yTes7GxZvtWbSB6yMLzFhoowgfK9xggXiItSvbgoJFXcEOAKm-8ssuXVbcLglrybv_8wbWgEd5BwW4nmieIm-PVtv3fRLCNlYYRYblEf7wVw3yKmb0Vh1aLLOK6gs_Swhl8jNcUkISbYGBL350hdBr4npz4Ah54vkksDcstQJbqxZ3UmbrblWyV0zp8Fq8hcjuz0rluaGqzonSbJFuLMY6KU3Tq8AByXr3cXYz3nivVlbkEh-MA97wrZp0cmq_Z0mwkS9wcGuWMljuKe7bRVX-w2bi9g2s-YjorGkd96uIohgcmR_jdilpxirSYzAuNUlVCXnZKHZ75FQYtknZw6BaeW3ZyKdPxqsYzKYxeMarXh-DOLdfF9GoDy0)

```plantuml
@startuml
actor Alice
participant Client as "Desktop Client"
participant Lookup as "Lookup Server\nhttps://lookup.server../"
participant Instance as "ownCloud Instance\nhttps://instance.server../"

Alice -> Client : enter server URL\nhttps://lookup.server../

Client -> Lookup : GET\nhttps://lookup.../status.php
Client <-- Lookup : 200 OK

Client -> Lookup : PROPFIND\nhttps://lookup.../remote.php/webdav/
Client <-- Lookup : 401 Unauthorized\nWWW-Authenticate: Basic realm=\"My Realm\"

Alice -> Client : enter credentials

Client -> Lookup : PROPFIND\nhttps://lookup.../remote.php/webdav/\n-u "username:pw"
Client <-- Lookup : 301 Moved Permanently\nLocation: https://instance.server../remote.php/webdav/

Client -> Instance : PROPFIND\nhttps://instance.../remote.php/webdav/\n-u "username:pw"
Client <-- Instance : 207 Multi-Status

Client -> Instance : GET\n/ocs/v1.php/cloud/capabilities
Client <-- Instance : 200 OK

Client -> Instance : GET\n/ocs/v1.php/cloud/user
Client <-- Instance : 200 OK

Client -> Instance : GET\n/dav/avatars/username/128.png
Client <-- Instance : 404 Not Found

Client -> Alice : UI shows\ndisplay-name(username)\nhttps://instance.../

Client -> Instance : GET\n/ocs/v1.php/cloud/activity
Client <-- Instance : 200 OK

Client -> Instance : GET\n/ocs/v2.php/apps/notifications/api/v1/notifications
Client <-- Instance : 200 OK

Client -> Instance : PROPFIND\nhttps://instance.../remote.php/dav/files/username/
Client <-- Instance : 207 Multi-Status
@enduml
```

to edit go to [PlantUML](http://www.plantuml.com/plantuml/uml/hP9FRzf04CNlV8eHf_PW5YXIAwkjaYPDXGe98aLSV9ci9sMLzUvg_nZHJz-rmOrHJTGalS3wQUOtRtVUcVDeVIXa3xdN5iwbuDGpKHDS65GUBgIW-8SE-fVa7hms1wb_L3RJ-Y6Okknml2LRaitKndlZKiPaBGzSBGy6xBX_gfn7nQacwAswa3haVzH7YZWeRKwlTWt9vyPi2l6NBEnhOBMSdRRHwnsQOll1UGhVllxugoFMnj4-k87PcARfOv8yTes7GxZvtWbSB6yMLzFhoowgfK9xggXiItSvbgoJFXcEOAKm-8ssuXVbcLglrybv_8wbWgEd5BwW4nmieIm-PVtv3fRLCNlYYRYblEf7wVw3yKmb0Vh1aLLOK6gs_Swhl8jNcUkISbYGBL350hdBr4npz4Ah54vkksDcstQJbqxZ3UmbrblWyV0zp8Fq8hcjuz0rluaGqzonSbJFuLMY6KU3Tq8AByXr3cXYz3nivVlbkEh-MA97wrZp0cmq_Z0mwkS9wcGuWMljuKe7bRVX-w2bi9g2s-YjorGkd96uIohgcmR_jdilpxirSYzAuNUlVCXnZKHZ75FQYtknZw6BaeW3ZyKdPxqsYzKYxeMarXh-DOLdfF9GoDy0)
