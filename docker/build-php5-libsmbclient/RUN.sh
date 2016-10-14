#!/bin/bash
dockername=centos7-php55-devel

## the rm options do not help. We need to call --no-cache to really cause a rebuild.
# build_opt=--no-cache=true
build_opt=--no-cache=false

docker build $build_opt --force-rm=true --rm=true -t $dockername -f Dockerfile.centos7 .
cat <<EOF
Study:
  https://github.com/owncloud/documentation/issues/2172#issuecomment-188876694
Try:
  docker run -ti -v $(pwd):/docker $dockername
EOF
