FROM debian:jessie
RUN apt-get update && apt-get install -y --force-yes perl gettext liblocale-po-perl liblocale-gettext-perl
RUN apt-get install -y --force-yes python-pip
RUN apt-get install -y --force-yes git
RUN pip install --upgrade transifex-client
RUN mkdir /workspace
RUN adduser --disabled-password --uid 1000 --gecos '' jenkins
VOLUME ["/workspace"]
COPY l10n.pl /home/jenkins/

COPY docker-entrypoint.sh /usr/local/bin/
RUN ln -s /usr/local/bin/docker-entrypoint.sh /entrypoint.sh # backwards compat

USER jenkins
ENTRYPOINT ["docker-entrypoint.sh"]
