FROM phusion/baseimage:latest
MAINTAINER Erik Wittek "erik@webhippie.de"

ENV HOME /root
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -y update
RUN apt-get -y install apache2 mysql-server mysql-client libapache2-mod-php5 php5-gd php5-json php5-mysql php5-sqlite php5-curl php5-intl php5-mcrypt php5-imagick bzip2 wget
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN /etc/my_init.d/00_regen_ssh_host_keys.sh

RUN curl https://download.owncloud.org/community/owncloud-7.0.1.tar.bz2 | tar jx -C /var/www/
RUN chown -R www-data:www-data /var/www/owncloud

ADD ./001-owncloud.conf /etc/apache2/sites-available/
RUN rm -f /etc/apache2/sites-enabled/000*
RUN ln -s /etc/apache2/sites-available/001-owncloud.conf /etc/apache2/sites-enabled/
RUN a2enmod rewrite

ADD rc.local /etc/rc.local
RUN chown root:root /etc/rc.local

ADD init_volume.sh /etc/my_init.d/init_volume.sh
RUN chmod +x /etc/my_init.d/init_volume.sh

# forward port to the outside world
EXPOSE 80

CMD ["/sbin/my_init"]