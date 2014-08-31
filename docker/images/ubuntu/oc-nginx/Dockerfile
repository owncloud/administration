FROM phusion/baseimage:latest
MAINTAINER Erik Wittek <erik@webhippie.de>
ENV DEBIAN_FRONTEND noninteractive

# Set correct environment variables
ENV HOME /root

# Fix a Debianism of the nobody's uid being 65534
RUN usermod -u 99 nobody
RUN usermod -g 100 nobody

RUN add-apt-repository "deb http://us.archive.ubuntu.com/ubuntu/ trusty universe multiverse"
RUN add-apt-repository "deb http://us.archive.ubuntu.com/ubuntu/ trusty-updates universe multiverse"
RUN apt-get update -q

# Install Dependencies
RUN apt-get install -qy  wget nginx php5-common php5-cli php5-fpm openssl

# Use baseimage-docker's init system
CMD ["/sbin/my_init"]

# Add the ownCloud repository
RUN echo "deb http://download.opensuse.org/repositories/isv:/ownCloud:/community/xUbuntu_14.04/ /" >> /etc/apt/sources.list.d/owncloud.list
RUN wget -qO - http://download.opensuse.org/repositories/isv:ownCloud:community/xUbuntu_14.04/Release.key | apt-key add -

# Install ownCloud
RUN apt-get update -qq && apt-get install -qy owncloud

# Expose ownCloud's data dir
VOLUME ["/var/www/owncloud/data"]

# Expose port. Cannot be modified!
EXPOSE 8000

# Add the site configuration
ADD owncloud.site /etc/nginx/sites-enabled/owncloud

# Add custom PHP-FPM / Ningx configuration
ADD www.conf /etc/php5/fpm/pool.d/
ADD php.ini /etc/php5/fpm/
ADD nginx.conf /etc/nginx/

RUN rm -f /etc/nginx/sites-enabled/default

# Fix SabreDAV error running with self signed certificate
#RUN sed -i "/.*CURLOPT_MAXREDIRS.*/a\            CURLOPT_SSL_VERIFYPEER => 0,\n \
#           CURLOPT_SSL_VERIFYHOST => 0,\n"  /var/www/owncloud/3rdparty/Sabre/DAV/Client.php


# Add config.sh to execute during container startup
RUN mkdir -p /etc/my_init.d
ADD config.sh /etc/my_init.d/config.sh
RUN chmod +x /etc/my_init.d/config.sh

# Add init_volume.sh to execute during container startup
ADD init_volume.sh /etc/my_init.d/init_volume.sh
RUN chmod +x /etc/my_init.d/init_volume.sh

# Add Nginx to runit
RUN mkdir /etc/service/nginx
ADD nginx.sh /etc/service/nginx/run
RUN chmod +x /etc/service/nginx/run

# Add PHP-FPM to runit
RUN mkdir /etc/service/php-fpm
ADD php-fpm.sh /etc/service/php-fpm/run
RUN chmod +x /etc/service/php-fpm/run