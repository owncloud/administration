#!/bin/bash

useradd jenkins --uid $1
shift
zypper --non-interactive --gpg-auto-import-keys install sudo
 
sudo -u jenkins $(dirname ${BASH_SOURCE[0]})/compile_client.sh $@
