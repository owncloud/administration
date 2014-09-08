#!/bin/bash

# start containers
docker run -p 127.0.0.1:389:389 \
	-e LDAP_DOMAIN=owncloud.com \
	-e LDAP_ORGANISATION="ownCloud" \
	-e LDAP_ROOTPASS=admin \
	--name docker-slapd \
	-d nickstenning/slapd || exit 1

#docker inspect docker-slapd | grep IP
SLAPD_CONTAINER_IP=$(docker inspect docker-slapd | grep IPAddress | sed -e 's/.*:\s"\([0-9.]*\)".*/\1/g')
echo "LDAP server now available under 127.0.0.1:389 (internal IP is $SLAPD_CONTAINER_IP)"
docker run -p 443:443 \
	--name docker-phpldapadmin \
	-e LDAP_HOST=$SLAPD_CONTAINER_IP \
	-e LDAP_BASE_DN=dc=owncloud,dc=com \
	-e LDAP_LOGIN_DN=cn=admin,dc=owncloud,dc=com \
	-d osixia/phpldapadmin || exit 2

echo "phpldapadmin now available under https://127.0.0.1"

docker ps

