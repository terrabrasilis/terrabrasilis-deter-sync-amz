# To build image for this dockerfile use this command:
#   docker build -t terrabrasilis/deter-generate-files:vx.y -f env-scripts/Dockerfile --no-cache .
#
# To run without compose and without shell terminal use this command:
#   docker run -d --rm --name terrabrasilis_deter_scripts terrabrasilis/deter-generate-files:vx.y
#   docker run -d --rm --name terrabrasilis_deter_scripts -v $PWD:/logs -v $PWD:/data/files terrabrasilis/deter-generate-files:vx.y
#
#--------- Generic stuff all our Dockerfiles should start with so we get caching ------------
FROM ubuntu:18.04

LABEL "br.inpe.dpi"="INPE/DPI-TerraBrasilis" \
br.inpe.dpi.terrabrasilis="script-tasks" \
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


# INSTALL SCRIPTS
# ------------------------------------------------------
RUN mkdir -p $INSTALL_PATH/scripts-shell/
COPY scripts-shell/ $INSTALL_PATH/scripts-shell/
RUN chmod +x $INSTALL_PATH/scripts-shell/*.sh

# install and enable cron job scripts
ADD env-scripts/exec_daily.sh $INSTALL_PATH/
ADD env-scripts/exec_weekly.sh $INSTALL_PATH/
ADD env-scripts/daily_copy.sh $INSTALL_PATH/
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