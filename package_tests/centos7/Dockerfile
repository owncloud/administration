FROM centos:centos7

RUN yum clean all

RUN yum -y install wget; yum clean all;
RUN yum -y install wget; yum clean all;

ADD install.sh install.sh
RUN chmod +x install.sh

# 7.0, 8.0, 8.1
ENV VERSION=8.0

CMD /install.sh