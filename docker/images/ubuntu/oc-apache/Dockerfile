FROM phusion/baseimage:latest
MAINTAINER Felix Böhm "felix@owncloud.com"

ENV HOME /root
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -y update
RUN apt-get -y install apache2 mysql-client libapache2-mod-php5 php5-gd php5-json php5-mysql php5-sqlite php5-curl php5-intl php5-mcrypt php5-imagick php5-memcache bzip2 wget
# php5-apcu
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN /etc/my_init.d/00_regen_ssh_host_keys.sh

RUN curl https://download.owncloud.org/community/owncloud-7.0.3.tar.bz2 | tar jx -C /var/www/
RUN chown -R www-data:www-data /var/www/owncloud

ADD config/001-owncloud.conf /etc/apache2/sites-available/
RUN rm -f /etc/apache2/sites-enabled/000*
RUN ln -s /etc/apache2/sites-available/001-owncloud.conf /etc/apache2/sites-enabled/
RUN a2enmod rewrite


# Apache deamon
RUN mkdir /etc/service/apache
ADD runit/apache.sh /etc/service/apache/run

RUN mv /var/www/owncloud/config /var/www/owncloud/config_old

# ADD config/owncloud_config.sh /etc/my_init.d/owncloud_config.sh
# RUN chmod +x /etc/my_init.d/owncloud_config.sh

ADD config/use_memcached.sh /etc/my_init.d/use_memcached.sh
RUN chmod +x /etc/my_init.d/use_memcached.sh

ADD config/init_volume.sh /etc/my_init.d/init_volume.sh
RUN chmod +x /etc/my_init.d/init_volume.sh

# forward port to the outside world
EXPOSE 80

CMD ["/sbin/my_init"]
