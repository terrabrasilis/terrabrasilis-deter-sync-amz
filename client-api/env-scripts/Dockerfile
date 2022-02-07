# To build image for this dockerfile use this command:
#   docker build -t terrabrasilis/deter-generate-files:vx.y -f env-scripts/Dockerfile --no-cache .
#
# To run without compose and without shell terminal use this command:
#   docker run -d --rm --name terrabrasilis_deter_scripts terrabrasilis/deter-generate-files:vx.y
#   docker run -d --rm --name terrabrasilis_deter_scripts -v $PWD:/logs -v $PWD:/data/files terrabrasilis/deter-generate-files:vx.y
#
#--------- Generic stuff all our Dockerfiles should start with so we get caching ------------
FROM ubuntu:18.04

ARG VERSION=x.y
ENV VERSION=$VERSION

LABEL "br.inpe.dpi"="INPE/DPI-TerraBrasilis" \
br.inpe.dpi.terrabrasilis="script-tasks" \
version=${VERSION} \
author="Andre Carvalho" \
author.email="andre.carvalho@inpe.br" \
description="Scripts to generate JSON files from GeoServer layers and generate \
shapefiles from database for DETER project of the Cerrado and Amazon."
#-------------Application Specific Stuff ----------------------------------------------------

RUN apt-get -o Acquire::ForceIPv4=true update \
    && apt-get install -y \
    wget \
    gnupg \
    cron \
    tzdata \
    bash \
    curl \
    zip \
    ssmtp

RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
    && echo "deb http://apt.postgresql.org/pub/repos/apt/ bionic-pgdg main" > /etc/apt/sources.list.d/pgdg.list

RUN apt-get -o Acquire::ForceIPv4=true update \
      && apt-get install -y --no-install-recommends \
           postgresql-10-postgis-2.5 \
           postgis \
      && rm -rf /var/lib/apt/lists/*

# define the timezone to run cron
ENV TZ=America/Sao_Paulo

# define the install path env var
ENV INSTALL_PATH /usr/local
ENV SHARED_DIR /data/files
ENV STATIC_FILES_DIR /data/terrama/deter-amz

## THE ENV VARS ARE NOT READED INSIDE A SHELL SCRIPT THAT RUNS IN CRON TASKS.
## SO, WE WRITE INSIDE THE /etc/environment FILE AND READS BEFORE RUN THE SCRIPT.
RUN echo "export GEOSERVER_BASE_URL=\"http://terrabrasilis.dpi.inpe.br\"" >> /etc/environment \
    && echo "export GEOSERVER_BASE_PATH=\"geoserver\"" >> /etc/environment \
    && echo "export POSTGRES_HOST=\"150.163.2.177\"" >> /etc/environment \
    && echo "export POSTGRES_PORT=\"5432\"" >> /etc/environment \
    && echo "export POSTGRES_USER_FILE=\"/run/secrets/postgres.user.geoserver\"" >> /etc/environment \
    && echo "export POSTGRES_PASS_FILE=\"/run/secrets/postgres.pass.geoserver\"" >> /etc/environment \
    && echo "export GEOSERVER_USER_FILE=\"/run/secrets/geoserver.user.dashboard\"" >> /etc/environment \
    && echo "export GEOSERVER_PASS_FILE=\"/run/secrets/geoserver.pass.dashboard\"" >> /etc/environment \
    && echo "export FTP_USER_FILE=\"/run/secrets/ftp.user.queimadas\"" >> /etc/environment \
    && echo "export FTP_PASS_FILE=\"/run/secrets/ftp.pass.queimadas\"" >> /etc/environment \
    && echo "export SHARED_DIR=\"/data/files\"" >> /etc/environment \
    && echo "export STATIC_FILES_DIR=\"/data/terrama/deter-amz\"" >> /etc/environment \
    && echo "export SCRIPTS_BASE_PATH=\"${INSTALL_PATH}/scripts-shell\"" >> /etc/environment

# INSTALL SCRIPTS
# ------------------------------------------------------
RUN mkdir -p $INSTALL_PATH/scripts-shell/
COPY scripts-shell/ $INSTALL_PATH/scripts-shell/
RUN chmod +x $INSTALL_PATH/scripts-shell/*.sh

# install and enable cron job scripts
ADD env-scripts/exec_daily.sh $INSTALL_PATH/
ADD env-scripts/exec_weekly.sh $INSTALL_PATH/
RUN chmod +x $INSTALL_PATH/*.sh
# install and enable config cron
# for daily
ADD env-scripts/daily.cron /etc/cron.d/daily-cron
RUN chmod 0644 /etc/cron.d/daily-cron \
    && crontab /etc/cron.d/daily-cron
# for weekly (append into crontab)
ADD env-scripts/weekly.cron /etc/cron.d/weekly-cron
RUN chmod 0644 /etc/cron.d/weekly-cron \
    && crontab -l | { cat; cat /etc/cron.d/weekly-cron; } | crontab -

# logs to output cron exec
RUN mkdir -p /logs && touch /logs/exec_daily.log && touch /logs/exec_weekly.log

# the data directory for put generated files 
RUN mkdir -p ${SHARED_DIR}

# the data directory for put generated files 
RUN mkdir -p ${STATIC_FILES_DIR}

# Script to copy secrets from files for env vars
ADD env-scripts/docker-entrypoint.sh $INSTALL_PATH/bin/docker-entrypoint.sh
RUN chmod +x $INSTALL_PATH/bin/*.sh \
    && ln -s usr/local/bin/docker-entrypoint.sh / # backwards compat

# expose shared dirs
VOLUME ["${STATIC_FILES_DIR}","${SHARED_DIR}","/logs"]

ENTRYPOINT [ "/docker-entrypoint.sh" ]