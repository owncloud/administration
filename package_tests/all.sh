#!/usr/bin/env bash

rm -f log/install*

for OS in centos7 debian
do
  (./install.sh ${OS} &> log/install_${OS}.log) &
done