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

Inside the docker folder some scripts are available

build-docker.sh
---------------

Build all docker images 

```
./build-docker.sh
```

start-docker.sh
---------------

Runs ownCloud in docker container with selected os, server, db ...


```
./start-docker.sh [options]
```
Options: 
* -o          ubuntu, TODO: centos      default: ubuntu
* -s          apache, nginx             default: apache
* -d          sqlite, mysql             default: sqlite
* -p          <Port>                    default: 8888
* -d          <Dir> to mount in docker  default: /data-vol
* -h          help screen
