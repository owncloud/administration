FROM phusion/baseimage:latest
MAINTAINER Felix Böhm "felix@owncloud.com"

ENV HOME /root
ENV DEBIAN_FRONTEND noninteractive

# Install packages
RUN apt-get update
RUN apt-get -y install mysql-server pwgen
RUN rm -rf /var/lib/apt/lists/*

# Remove pre-installed database
RUN rm -rf /var/lib/mysql/*

# Add MySQL configuration
ADD config/my.cnf /etc/mysql/conf.d/my.cnf
ADD config/mysqld_charset.cnf /etc/mysql/conf.d/mysqld_charset.cnf

# Add MySQL config
ADD config/mysql_config.sh /etc/my_init.d/mysql_config.sh
RUN chmod 755 /etc/my_init.d/mysql_config.sh

# Mysql deamon
RUN mkdir /etc/service/mysql
ADD runit/mysql.sh /etc/service/mysql/run

# Exposed ENV
ENV MYSQL_USER admin
ENV MYSQL_PASS **Random**

# Add VOLUMEs to allow backup of config and databases
VOLUME  ["/etc/mysql", "/var/lib/mysql"]

EXPOSE 3306

CMD ["/sbin/my_init"]
