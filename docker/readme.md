Overview
========

* ownCloud docker containers for various OS, servers, databases.
* Development of docker images for scaleable ownCloud installations.

Images: 

* Ubuntu
  * ```oc-apache``` ownCloud running in apache
  * ```oc-nginx``` ownCloud running in nginx
  * ```db-mysql``` mysql container
  * ```data-vol``` data persistence container

Setup
=====

Install [Docker](https://www.docker.com/) 

Install docker on a linux machine or linux VM for easy usage.

Run 
===

build-docker.sh
---------------

Build all docker images

start-docker.sh
---------------

Runs ownCloud in docker container with selected OS, server, db ...
TODO: Make script configurable

```
./start-docker.sh ubuntu
```
