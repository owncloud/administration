#!/bin/bash

OS=ubuntu
SERVER=apache
DB=mysql
PORT=8888
DATA_VOLUME_DIR="/data-vol"

while getopts "o:s:d:p:h" opt; do
  case $opt in
    o)
      ([ $OPTARG == ubuntu ] || [ $OPTARG == centos ]) && OS=$OPTARG
      ;;
    s)
      ([ $OPTARG == apache ] || [ $OPTARG == nginx ]) && SERVER=$OPTARG
      ;;
    d)
      ([ $OPTARG == mysql ] || [ $OPTARG == sqlite ]) && DB=$OPTARG
      ;;
    p) 
      PORT=$OPTARG
      ;;
    d)
      if [ -d $OPTARG ]; then 
        DATA_VOLUME_DIR=$OPTARG
      fi
      ;;
    h)
      echo "Start ownCloud Docker Container"
      echo  
      echo "  ocstart-docker.sh [ Options ]"
      echo
      echo "  Options: "
      echo "  -o          ubuntu, TODO: centos      default: ubuntu"
      echo "  -s          apache, nginx             default: apache"
      echo "  -d          sqlite, mysql             default: sqlite"
      echo "  -p          <Port>                    default: 8888"
      echo "  -d          <Dir> to mount in docker  default: /data-vol"
      echo "  -h          This help screen"
      echo
      exit
      ;;
  esac
done

BASE_PATH=$(dirname $0)
cd $BASE_PATH

[ -d $DATA_VOLUME_DIR ] || mkdir $DATA_VOLUME_DIR

SERVER_IMAGE_NAME="oc-$SERVER-$OS"
DB_IMAGE_NAME="db-$DB-$OS"
DATA_IMAGE_NAME="data-vol-$OS"

SERVER_NAME="oc-server"
DB_NAME="oc-$DB"
DATA_NAME="oc-data"

echo "Restart test system"
docker rm -f $DATA_NAME 
docker rm -f $DB_NAME 
docker rm -f $SERVER_NAME 

echo "Start ownCloud server $SERVER on port $PORT with database $DB"

docker run -dv $DATA_VOLUME_DIR:/data-vol --name=$DATA_NAME $DATA_IMAGE_NAME


if [ $DB == sqlite ]; then
  DB_LINK=""
fi
if [ $DB == mysql ]; then
  docker run -d -e MYSQL_PASS="rootpass" --name=$DB_NAME $DB_IMAGE_NAME
  DB_LINK=" --link=$DB_NAME:db"
fi


if [ $SERVER == apache ]; then
  docker run -dp $PORT:80 -h $SERVER_NAME --name=$SERVER_NAME $DB_LINK --volumes-from $DATA_NAME $SERVER_IMAGE_NAME /sbin/my_init --enable-insecure-key
fi

if [ $SERVER == nginx ]; then
  docker run -dp $PORT:8000/tcp -h $SERVER_NAME --name=$SERVER_NAME $DB_LINK --volumes-from $DATA_NAME $SERVER_IMAGE_NAME /sbin/my_init --enable-insecure-key
fi


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

