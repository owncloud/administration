FROM phusion/baseimage:latest
MAINTAINER Felix Böhm "felix@owncloud.com"

ENV HOME /root
ENV DEBIAN_FRONTEND noninteractive

# Update apt sources
# RUN echo "deb http://archive.ubuntu.com/ubuntu precise main universe" > /etc/apt/sources.list

RUN apt-get -y update
# RUN apt-get -y upgrade

# Configure timezone and locale
RUN apt-get install locales
RUN echo "Europe/Berlin" > /etc/timezone; dpkg-reconfigure -f noninteractive tzdata
RUN export LANGUAGE=en_US.UTF-8; export LANG=en_US.UTF-8; export LC_ALL=en_US.UTF-8; locale-gen en_US.UTF-8; dpkg-reconfigure locales

# Install memcached
RUN apt-get -y install wget curl memcached
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Memcached deamon
RUN mkdir /etc/service/memcached
ADD config/memcached.conf /etc/memcached.conf
ADD runit/memcached.sh /etc/service/memcached/run

EXPOSE 11211

CMD ["/sbin/my_init"]