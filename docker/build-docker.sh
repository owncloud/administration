#!/bin/bash

# Build all images in folder images
# Images are named like folder name

BASE_PATH=$(dirname $0)
cd $BASE_PATH

IMAGE_PATH=$PWD/images
OS_VERSIONS=( 'ubuntu' )

for OS in $OS_VERSIONS
do
  for IMAGE in `find $IMAGE_PATH/$OS -mindepth 1 -maxdepth 1 -type d`
  do
    NAME=$(basename $IMAGE)
    echo "Found docker image $NAME-$OS"
    docker build -t $NAME-$OS $IMAGE_PATH/$OS/$NAME
  done
done

