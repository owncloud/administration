#!/bin/bash
#
# requires: docker.io

usage()
{
	echo "" >&2
	echo "	usage: sh dockerfile.sh [-h] [-i] [-c|-e <ownCloudVersion>] [-d <distribution>]" >&2
	echo "" >&2
	echo "	example: bash dockerfile.sh -e 7.0 -d xUbuntu_12.04" >&2
	echo "				  	(like obs-docker-install)" >&2
	echo "	optional arguments:" >&2 
	echo "		-i		internal for 8.0" >&2
	echo "		-h		show this help message and exit" >&2
	echo "" >&2
	exit 1
}

internal=0 
unset obspath
unset path
unset oCVersion
unset distribution
unset eeocom
while getopts ":c:e:d:hi" opt; do
  case $opt in
    c)
      	echo "Community Version $OPTARG" >&2
	oCVersion=$OPTARG
	obspath="isv:ownCloud:community:"
	path="isv-ownCloud-community-"
	eeocom="owncloud"
      	;;
    e) 
	echo "Enterprise Version $OPTARG" >&2
	oCVersion=$OPTARG
	obspath="ee:"
	path="ee-"
	eeocom="owncloud-enterprise"
	;;
    d)
	echo "Distribution: $OPTARG" >&2
	distribution=$OPTARG
	;;
    i)
	echo "Using Internal" >&2
	internal=1
	;;
    h)
	usage
	;;
    p)  
	echo "Port: $OPTARG" >&2
	port=$OPTARG
	;;
    \?)
	echo "" >&2
      	echo "	invalid option: -$OPTARG" >&2
	echo "" >&2
	echo "		-h for help.">&2
	echo "" >&2
      	exit 1
      	;;
    :)
	echo "" >&2
      	echo "	option -$OPTARG requires an argument." >&2
	echo "" >&2
	echo "	-h for help.">&2
	echo "" >&2
      	exit 1
      	;;
  esac
done



if [ -z "$oCVersion" ] || [ -z "$distribution" ]
then usage
fi

mkdir Dockerfiles/$path$oCVersion
mkdir Dockerfiles/$path$oCVersion/$distribution
touch Dockerfiles/$path$oCVersion/$distribution/Dockerfile


if [ "$internal" = "1" ]
	then 
	obs-docker-install $obspath$oCVersion $eeocom $distribution -d internal -D > ./Dockerfiles/$path$oCVersion/$distribution/Dockerfile
	else 
	obs-docker-install $obspath$oCVersion $eeocom $distribution -D > ./Dockerfiles/$path$oCVersion/$distribution/Dockerfile
fi


cat Dockerfiles/$path$oCVersion/$distribution/Dockerfile

formatdis="${distribution,,}"
formatdis="${formatdis//@}"
echo ""
echo "docker build -t $eeocom-${oCVersion,,}-$formatdis Dockerfiles/$path$oCVersion/$distribution/"
echo ""




