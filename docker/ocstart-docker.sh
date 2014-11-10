#!/bin/bash

OS=ubuntu
SERVER=apache
DB=mysql
PORT=8888
VOLUME_DIR="/data-vol"
SERVER_INSTANCES=3

SSH="/sbin/my_init --enable-insecure-key"

# change permission of key otherwise it wouldn't be used
chmod 600 configs/insecure_key

while getopts "o:s:d:p:i:h" opt; do
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
        VOLUME_DIR=$OPTARG
      fi
      ;;
    i)
      [ "$OPTARG" -ge 1 -a "$OPTARG" -le 32 ] && SERVER_INSTANCES=$OPTARG
      ;;
    h)
      echo "Start ownCloud Docker Container"
      echo  
      echo "  ocstart-docker.sh [ Options ]"
      echo
      echo "  Options: "
      echo "  -o          ubuntu, TODO: centos            default: ubuntu"
      echo "  -s          apache, nginx                   default: apache"
      echo "  -d          sqlite, mysql                   default: sqlite"
      echo "  -p          <Port>                          default: 8888"
      echo "  -d          <Dir> to mount in docker        default: /data-vol"
      echo "  -i          <Number> of server instances    default: 3"
      echo "  -h          This help screen"
      echo
      exit
      ;;
  esac
done

BASE_PATH=$(dirname $0)
cd $BASE_PATH

SERVER_IMAGE_NAME="oc-$SERVER-$OS"
DB_IMAGE_NAME="db-$DB-$OS"
DATA_IMAGE_NAME="data-vol-$OS"
MEMCACHED_IMAGE="memcached-$OS"

SERVER_NAME="oc-server"
DB_NAME="oc-$DB"
DATA_NAME="oc-data"
MEMCACHED_NAME="memcached"

echo "Restart test system"
docker rm -f $DATA_NAME 
docker rm -f $MEMCACHED_NAME
docker rm -f $DB_NAME 
for i in $(seq 1 $SERVER_INSTANCES)
do
  docker rm -f $SERVER_NAME-$i $QUIET
done


echo "Start ownCloud server $SERVER on port $PORT with database $DB"

echo "docker run -dv $VOLUME_DIR:/data-vol --name=$DATA_NAME $DATA_IMAGE_NAME $QUIET"
docker run -dv $VOLUME_DIR:/data-vol --name=$DATA_NAME $DATA_IMAGE_NAME > /dev/null 2>&1

echo "docker run -dp 127.0.0.1:11211:11211 -h $MEMCACHED_NAME --name $MEMCACHED_NAME $MEMCACHED_IMAGE $QUIET"
docker run -dp 127.0.0.1:11211:11211 -h $MEMCACHED_NAME --name $MEMCACHED_NAME $MEMCACHED_IMAGE > /dev/null 2>&1
MEMCACHE_LINK=" --link=$MEMCACHED_NAME:memcached"

if [ $DB == sqlite ]; then
  DB_LINK=""
fi
if [ $DB == mysql ]; then
  echo "docker run -dp 3306:3306 -v $VOLUME_DIR/mysql:/var/lib/mysql -e MYSQL_PASS="rootpass" --name=$DB_NAME -h $DB_NAME $DB_IMAGE_NAME $SSH"
  docker run -dp 3306:3306 -v $VOLUME_DIR/mysql:/var/lib/mysql -e MYSQL_PASS="rootpass" --name=$DB_NAME -h $DB_NAME $DB_IMAGE_NAME $SSH > /dev/null 2>&1
  echo " on IP $(docker inspect -f "{{ .NetworkSettings.IPAddress }}" $DB_NAME)"
  DB_LINK=" --link=$DB_NAME:db"
fi


if [ $SERVER == apache ]; then
  for i in $(seq 1 $SERVER_INSTANCES)
  do
    INSTANCE_PORT=$(($PORT + $i - 1))
    echo "docker run -dp 127.0.0.1:$INSTANCE_PORT:80 -h $SERVER_NAME-$i --name=$SERVER_NAME-$i $DB_LINK $MEMCACHE_LINK --volumes-from $DATA_NAME $SERVER_IMAGE_NAME $SSH"
    docker run -dp 127.0.0.1:$INSTANCE_PORT:80 -h $SERVER_NAME-$i --name=$SERVER_NAME-$i $DB_LINK $MEMCACHE_LINK --volumes-from $DATA_NAME $SERVER_IMAGE_NAME $SSH #> /dev/null 2>&1
    echo " on IP $(docker inspect -f "{{ .NetworkSettings.IPAddress }}" $SERVER_NAME-$i)"
  done
fi

if [ $SERVER == nginx ]; then
  echo "docker run -dp 127.0.0.1:$PORT:8000/tcp -h $SERVER_NAME-1 --name=$SERVER_NAME-1 $DB_LINK $MEMCACHE_LINK --volumes-from $DATA_NAME $SERVER_IMAGE_NAME $SSH"
  docker run -dp 127.0.0.1:$PORT:8000/tcp -h $SERVER_NAME-1 --name=$SERVER_NAME-1 $DB_LINK $MEMCACHE_LINK --volumes-from $DATA_NAME $SERVER_IMAGE_NAME $SSH > /dev/null 2>&1
fi


printf "Wait for bootup "
#Get IP of ownCLoud-Server
IP=$(docker inspect -f "{{ .NetworkSettings.IPAddress }}" $SERVER_NAME-1)
while ! ssh -o'UserKnownHostsFile /dev/null' -oStrictHostKeyChecking=no -i configs/insecure_key root@$IP ls -la $VOLUME_DIR > /dev/null 2>&1
do
  printf "." && sleep 1
done
echo
echo "Install and configure"
# echo "scp -oStrictHostKeyChecking=no -i configs/insecure_key configs/autoconfig_sqlite.php root@$IP:/var/www/owncloud/config/autoconfig.php"
# scp -oStrictHostKeyChecking=no -i configs/insecure_key configs/autoconfig_sqlite.php root@$IP:/var/www/owncloud/config/autoconfig.php
# curl $IP:$PORT 

ssh -o'UserKnownHostsFile /dev/null' -oStrictHostKeyChecking=no -i configs/insecure_key root@$IP ls -la /var/www/owncloud/config

echo
echo "Connect with:"
echo "ssh -o'UserKnownHostsFile /dev/null' -oStrictHostKeyChecking=no -i configs/insecure_key root@$IP"

