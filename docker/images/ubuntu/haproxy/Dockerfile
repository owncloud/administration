FROM phusion/baseimage:latest
MAINTAINER Felix Böhm "felix@owncloud.com"

ENV HOME /root
ENV DEBIAN_FRONTEND noninteractive

# Install packages
RUN apt-get update
RUN apt-get -y install haproxy
RUN rm -rf /var/lib/apt/lists/*

# Add haproxy configuration
# ADD config/haproxy.cfg.sh /etc/my_init.d/haproxy.cfg.sh
# RUN chmod +x /etc/my_init.d/haproxy.cfg.sh

ADD config/haproxy.cfg /etc/haproxy/haproxy.cfg

# haproxy deamon
RUN mkdir /etc/service/haproxy
ADD runit/haproxy.sh /etc/service/haproxy/run

EXPOSE 80
EXPOSE 1936

CMD ["/sbin/my_init"]
