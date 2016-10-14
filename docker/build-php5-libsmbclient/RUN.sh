#!/bin/bash
dockername=centos7-php55-devel
docker build --force-rm=true --rm=true -t $dockername -f Dockerfile.centos7 .
cat <<EOF
Study:
  https://github.com/owncloud/documentation/issues/2172#issuecomment-188876694
Try:
  docker run -ti -v $(pwd):/docker $dockername
EOF
