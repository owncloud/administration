FROM phusion/baseimage:latest
MAINTAINER Felix Böhm "felix@owncloud.com"

# Set correct environment variables.
ENV HOME /root

RUN mkdir -p /data-vol

VOLUME ["/data-vol"]

RUN mkdir -p /etc/my_init.d

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]
