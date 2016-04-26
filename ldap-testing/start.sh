#!/bin/bash

# config
PHPLDAPADMIN_LOCAL_PORT=8443
LDAP_LOCAL_PORT=389

LDAP_DOMAIN=owncloud.com
LDAP_ORGANISATION=ownCloud
LDAP_ROOTPASS=admin

LDAP_BASE_DN=dc=owncloud,dc=com
LDAP_LOGIN_DN=cn=admin,dc=owncloud,dc=com

docker pull nickstenning/slapd > /dev/null

# start containers
docker run -p 127.0.0.1:$LDAP_LOCAL_PORT:389 \
	-e LDAP_DOMAIN=$LDAP_DOMAIN \
	-e LDAP_ORGANISATION="$LDAP_ORGANISATION" \
	-e LDAP_ROOTPASS=$LDAP_ROOTPASS \
	--name docker-slapd \
	-d nickstenning/slapd || exit 1

docker pull osixia/phpldapadmin > /dev/null

#docker inspect docker-slapd | grep IP
SLAPD_CONTAINER_IP=$(docker inspect -f "{{ .NetworkSettings.IPAddress }}" docker-slapd)
docker run -p $PHPLDAPADMIN_LOCAL_PORT:443 \
	--name docker-phpldapadmin \
	-e PHPLDAPADMIN_LDAP_HOSTS=$SLAPD_CONTAINER_IP \
	-e LDAP_BASE_DN=$LDAP_BASE_DN \
	-e LDAP_LOGIN_DN=$LDAP_LOGIN_DN \
	-d osixia/phpldapadmin || exit 2

docker ps
echo
echo "LDAP server now available under 127.0.0.1:$LDAP_LOCAL_PORT (internal IP is $SLAPD_CONTAINER_IP)"
echo "phpldapadmin now available under https://127.0.0.1:$PHPLDAPADMIN_LOCAL_PORT"
echo

