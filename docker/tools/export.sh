#!/bin/bash
#
# requires: docker.io


usage()
{
   	echo "" >&2
	echo "	usage: sh export.sh [-h] [-i ImageName] [-o OutputPath]" >&2
	echo "" >&2
	echo "	example: sh export.sh -i testImage -o /tmp" >&2
	echo "" >&2
	echo "	optional arguments:" >&2 
	echo "		-h		show this help message and exit" >&2
	echo "" >&2
	exit 1
}

unset imageName
outputPath=.

while getopts ":hi:o:" opt; do
  case $opt in
    i)
      	echo "ImageName:	$OPTARG" >&2
	imageName=$OPTARG
      	;;
    o)
	echo "OutputPath:	$OPTARG" >&2
	outputPath=$OPTARG
	;;
    h)
	usage
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

if [ -z "$imageName" ] || [ -z "$outputPath" ]
then usage
fi

if [ ! -d "$outputPath" ]
then 
	echo "Directory $outputPath doesn't exist!"
	exit 1
fi

echo "Attempting to save image $imageName to $outputPath/$imageName.tar"
docker save "$imageName" > "$outputPath/$imageName.tar"

if [ -s $outputPath/$imageName.tar ] 
then
	bzip2 $outputPath/$imageName.tar
else 
	echo ""
	echo "Choose one of these below if ID is not existing: "
	echo ""
	docker images
	rm "$outputPath/$imageName.tar"
	exit 1
fi

exit 0
