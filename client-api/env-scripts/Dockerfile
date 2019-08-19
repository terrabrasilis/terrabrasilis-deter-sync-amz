# To build image for this dockerfile use this command:
#   docker build -t terrabrasilis/deter-scripts:v0.6 -f env-scripts/Dockerfile --no-cache .
#
# To run without compose and without shell terminal use this command:
#   docker run -d --rm --name terrabrasilis_deter_scripts terrabrasilis/deter-scripts:v0.6
#   docker run -d --rm --name terrabrasilis_deter_scripts -v $PWD:/usr/local/data terrabrasilis/deter-scripts:v0.6
#
#--------- Generic stuff all our Dockerfiles should start with so we get caching ------------
FROM ubuntu:18.04
LABEL "br.inpe.obt"="INPE/OBT-TerraBrasilis" \
br.inpe.obt.terrabrasilis="script-tasks" \
version="v0.6" \
author="Andre Carvalho" \
author.email="andre.carvalho@inpe.br" \
description="Scripts to generate JSON files from GeoServer layers and generate \
shapefiles from database for DETER project of the Cerrado and Amazon."
#-------------Application Specific Stuff ----------------------------------------------------

RUN apt-get update \
    && apt-get install -y \
    wget \
    gnupg \
    cron \
    tzdata \
    nginx \
    bash \
    curl \
    zip

RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
    && echo "deb http://apt.postgresql.org/pub/repos/apt/ bionic-pgdg main" > /etc/apt/sources.list.d/pgdg.list

RUN apt-get update \
      && apt-get install -y --no-install-recommends \
           postgresql-10-postgis-2.5 \
           postgis \
      && rm -rf /var/lib/apt/lists/*

# define the timezone to run cron
ENV TZ=America/Sao_Paulo

# define the install path env var
ENV INSTALL_PATH /usr/local
ENV NGINX_ROOT_DIR /var/www/html

## THE ENV VARS ARE NOT READED INSIDE A SHELL SCRIPT THAT RUNS IN CRON TASKS.
## SO, WE WRITE INSIDE THE /etc/environment FILE AND READS BEFORE RUN THE SCRIPT.
RUN echo "export GEOSERVER_BASE_URL=\"http://terrabrasilis.dpi.inpe.br\"" >> /etc/environment \
    && echo "export GEOSERVER_BASE_PATH=\"geoserver/ows\"" >> /etc/environment \
    && echo "export POSTGRES_HOST=\"150.163.2.177\"" >> /etc/environment \
    && echo "export GEOSERVER_USER_FILE=\"/run/secrets/geoserver.user.dashboard\"" >> /etc/environment \
    && echo "export GEOSERVER_PASS_FILE=\"/run/secrets/geoserver.pass.dashboard\"" >> /etc/environment \
    && echo "export POSTGRES_USER_FILE=\"/run/secrets/postgres.user.geoserver\"" >> /etc/environment \
    && echo "export POSTGRES_PASS_FILE=\"/run/secrets/postgres.pass.geoserver\"" >> /etc/environment \
    && echo "export NGINX_ROOT_DIR=\"/var/www/html\"" >> /etc/environment

# INSTALL SCRIPTS
# ------------------------------------------------------
RUN mkdir -p $INSTALL_PATH/scripts-shell/
COPY scripts-shell/ $INSTALL_PATH/scripts-shell/
RUN chmod +x $INSTALL_PATH/scripts-shell/*

# install and enable cron job scripts
ADD env-scripts/cron_exec.sh $INSTALL_PATH/
RUN chmod +x $INSTALL_PATH/cron_exec.sh
# install and enable config cron
ADD env-scripts/daily.cron /etc/cron.d/daily-cron
RUN chmod 0644 /etc/cron.d/daily-cron
RUN crontab /etc/cron.d/daily-cron
RUN mkdir -p /logs && touch /logs/cron.log

# Script to copy secrets from files for env vars
ADD env-scripts/docker-entrypoint.sh $INSTALL_PATH/bin/docker-entrypoint.sh
RUN chmod +x $INSTALL_PATH/bin/*.sh
RUN ln -s usr/local/bin/docker-entrypoint.sh / # backwards compat

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
	&& ln -sf /dev/stderr /var/log/nginx/error.log \
  && rm $NGINX_ROOT_DIR/index.nginx-debian.html

EXPOSE 80

VOLUME ["${NGINX_ROOT_DIR}","/logs"]

ENTRYPOINT [ "/docker-entrypoint.sh" ]