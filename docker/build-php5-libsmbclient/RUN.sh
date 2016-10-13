#!/bin/bash
name=centos7-php55-devel
docker build -t $name -f Dockerfile.centos7 .
cat <<EOF
Study:
  https://github.com/owncloud/documentation/issues/2172#issuecomment-188876694
Try:
  docker run -ti $name
EOF
