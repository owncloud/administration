FROM phusion/baseimage:latest
MAINTAINER Felix Böhm "felix@owncloud.com"

ENV HOME /root
ENV DEBIAN_FRONTEND noninteractive

VOLUME /data
EXPOSE 80 443 3306

CMD ["/sbin/my_init"]

RUN mkdir /build
ADD . /build
RUN /build/scripts/install.sh
