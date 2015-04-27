#!/bin/bash

useradd jenkins --uid $1
echo -e "\njenkins    ALL=(ALL:ALL) ALL\n" >> /etc/sudoers
shift

sudo su $(dirname ${BASH_SOURCE[0]})/compile_client $@
