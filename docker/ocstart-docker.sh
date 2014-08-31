#!/bin/bash

if [ ! $1 ]
then 
  echo "Start ownCloud Docker Container"
  echo  
  echo "ocstart-docker.sh OS"
  echo
  echo "OS: ubuntu, WIP: centos"
  echo
  exit
fi

OS=$1
PORT=8888

BASE_PATH=$(dirname $0)
cd $BASE_PATH


# SERVER_IMAGE_NAME="oc-nginx-$OS"
# DB_IMAGE_NAME="db-mysql-$OS"
# DATA_IMAGE_NAME="data-vol-$OS"
#
# SERVER_NAME="oc-server"
# DB_NAME="oc-mysql"
# DATA_NAME="oc-data"
#
# DATA_VOLUME_DIR="/data-vol"
# [ -d $DATA_VOLUME_DIR ] || mkdir $DATA_VOLUME_DIR
#
# echo "Restart test system"
# docker rm -f $SERVER_NAME
# docker rm -f $DB_NAME
# docker rm -f $DATA_NAME
#
# echo "Start ownCloud nginx container with mysql and persistent data"
# docker run -dv $DATA_VOLUME_DIR:/data-vol --name=$DATA_NAME $DATA_IMAGE_NAME
# docker run -d -e MYSQL_PASS="rootpass" --name=$DB_NAME $DB_IMAGE_NAME
# docker run -dp $PORT:8000/tcp -h $SERVER_NAME --name=$SERVER_NAME --link=$DB_NAME:db --volumes-from $DATA_NAME $SERVER_IMAGE_NAME /sbin/my_init --enable-insecure-key


SERVER_IMAGE_NAME="oc-apache-$OS"
DB_IMAGE_NAME="db-mysql-$OS"
DATA_IMAGE_NAME="data-vol-$OS"

SERVER_NAME="oc-server"
DB_NAME="oc-mysql"
DATA_NAME="oc-data"

DATA_VOLUME_DIR="/data-vol"
[ -d $DATA_VOLUME_DIR ] || mkdir $DATA_VOLUME_DIR

echo "Restart test system"
docker rm -f $DATA_NAME 
docker rm -f $DB_NAME 
docker rm -f $SERVER_NAME 

echo "Start ownCloud apache container with mysql and persistent data"
docker run -dv $DATA_VOLUME_DIR:/data-vol --name=$DATA_NAME $DATA_IMAGE_NAME
docker run -d -e MYSQL_PASS="rootpass" --name=$DB_NAME $DB_IMAGE_NAME
docker run -dp $PORT:80 -h $SERVER_NAME --name=$SERVER_NAME --link=$DB_NAME:db --volumes-from $DATA_NAME $SERVER_IMAGE_NAME /sbin/my_init --enable-insecure-key


# SERVER_IMAGE_NAME="oc-apache-$OS"
# SERVER_NAME="oc-server"
# echo "Restart test system"
# docker rm -f $SERVER_NAME > /dev/null 2>&1
#
# echo "Start OwnCloud-apache-Container with sqlite"
# docker run -dp $PORT:80 -h $SERVER_NAME --name=$SERVER_NAME $IMAGE_NAME /sbin/my_init --enable-insecure-key

echo "Discover IP"
#Get IP of ownCLoud-Server
IP=$(docker inspect -f "{{ .NetworkSettings.IPAddress }}" $SERVER_NAME)
while ! ssh -o'UserKnownHostsFile /dev/null' -oStrictHostKeyChecking=no -i configs/insecure_key root@$IP ls -la /data-vol > /dev/null 2>&1
do
  printf "." && sleep 1
done

echo
echo "Data Volume:"
ssh -o'UserKnownHostsFile /dev/null' -oStrictHostKeyChecking=no -i configs/insecure_key root@$IP ls -la /data-vol

echo "Connect with:"
echo "ssh -o'UserKnownHostsFile /dev/null' -oStrictHostKeyChecking=no -i configs/insecure_key root@$IP"

