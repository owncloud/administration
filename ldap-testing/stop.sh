#!/bin/bash

echo "Stopping and resetting containers"
docker stop docker-slapd docker-phpldapadmin
docker rm docker-slapd docker-phpldapadmin

