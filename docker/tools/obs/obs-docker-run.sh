#!/bin/bash
#
# requires: docker.io

ubuntuStart()
{
service apache2 start 
service mysql start
sleep 1
/usr/bin/mysqladmin -u root password root
}

debianStart()
{
service apache2 start 
service mysql start
sleep 1
/usr/bin/mysqladmin -u root password root
}

fedoraStart()
{
service httpd start
mysql_install_db
chown -R mysql:mysql /var/lib/mysql
chown -R mysql:mysql /var/log/mariadb/
service mariadb start 
sleep 1
/usr/bin/mysqladmin -u root password root
}

opensuseStart()
{
start_apache2
mysql_install_db
chown -R mysql:mysql /var/lib/mysql
mysqld_safe &
sleep 1
/usr/bin/mysqladmin -u root password root
}

centosStart6()
{
service httpd start #using sqllite
}

centosStart7()
{
service httpd start
mysql_install_db
chown -R mysql:mysql /var/lib/mysql
service mariadb start
sleep 1
/usr/bin/mysqladmin -u root password root
}

StartOwnCloudServer()
{
#/bin/bash
#Finding distribution 
name=$(cat /etc/*-release | grep ^NAME=)
version=$(cat /etc/*-release | grep ^VERSION=)
if [ -z "$name" ] || [ -z "$version" ]
then
	distribution=$(cat /etc/*-release | head -n1) 
else
	#Giving nice format
	name=${name#*=}
	name="${name%\"}"
	name="${name#\"}"
	version=${version#*=}
	version="${version%\"}"
	version="${version#\"}"
	distribution="$name $version"
fi


case "$distribution" in 
"Ubuntu"*" 12.04"* )
	ubuntuStart
	;;
"Ubuntu"*" 14.04"* )
	ubuntuStart
	;;
"Ubuntu"*" 14.10"* )
	ubuntuStart
	;;
"Debian"*" 7"*)
	debianStart #mayuse ubuntuStart
	;;
"Fedora"*" 20"*)
	fedoraStart
	;;
"Fedora"*" 21"*)
	fedoraStart
	;;
"openSUSE"*" 13.1"*)
	opensuseStart
	;;
"openSUSE"*" 13.2"*)
	opensuseStart
	;;
"CentOS"*" 6"* )
	centosStart6
	;;
"CentOS"*" 7"* )
	centosStart7
	;;
esac
}


usage()
{
	echo "" >&2
	echo "	usage: sh obs-docker-run.sh [-h] [-p <port> ] [-i <ImageName:Version>]" >&2
	echo "" >&2
	echo "	example: sh obs-docker-run.sh -i ubuntuafterinstall:14.04" >&2
	echo "" >&2
	echo "	optional arguments:" >&2 
	echo "		-p <port>	specifies port, default is 8888" >&2
	echo "		-h		show this help message and exit" >&2
	echo "" >&2
	echo "	Supports these images: Ubuntu 12.04, Ubuntu 14.04, Ubuntu 14.10, Debian 7, Fedora 20, Fedora 21, openSUSE 13.1, openSUSE 13.2, CentOS 6, Centos 7" >&2
	echo "" >&2
	exit 1
}


unset imageName
port=8888
while getopts ":hei:p:" opt; do
  case $opt in
    i)
      	echo "ImageName: $OPTARG" >&2
	imageName=$OPTARG
      	;;
    e) 
	StartOwnCloudServer
	/bin/bash
	exit 0
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

if [ -z "$imageName" ]
then usage
fi


echo "Running Server will soon be at \"localhost:$port\""
echo "Database user: \"root\", Database password: \"root\""
#-d
docker run -p $port:80 -v $PWD:/docker -ti $imageName /bin/bash /docker/obs-docker-run.sh -e
exit


