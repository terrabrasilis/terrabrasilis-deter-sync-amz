# To build image for this dockerfile use this command:
#   docker build -t terrabrasilis/deter-amz-sync-client:v1.0 -f env-php/Dockerfile --no-cache .
#
# To run without compose and without shell terminal use this command:
#   docker run -d --rm --name terrabrasilis_deter_sync_client terrabrasilis/deter-amz-sync-client:v1.0
#   docker run -d --rm --name terrabrasilis_deter_sync_client -v $PWD:/usr/local/data terrabrasilis/deter-amz-sync-client:v1.0
#
#--------- Generic stuff all our Dockerfiles should start with so we get caching ------------
FROM php:5.6-cli
LABEL "br.inpe.dpi"="INPE/DPI-TerraBrasilis" \
br.inpe.dpi.terrabrasilis="client-api" \
version="v1.0" \
author="Andre Carvalho" \
author.email="andre.carvalho@inpe.br" \
description="API's client to sync database between INPE/CRA and INPE/SJC of the DETERB project of the Amazon."
#-------------Application Specific Stuff ----------------------------------------------------

RUN apt-get update \
    && apt-get install -y \
    libpq-dev \
    cron \
    tzdata \
    ssmtp \
    wget \
    zip \
    && docker-php-ext-install pdo pdo_pgsql pgsql \
    && rm -rf /var/lib/apt/lists/*

# define the timezone to run cron
ENV TZ=America/Sao_Paulo

ENV INSTALL_PATH /usr/local

RUN mkdir -p $INSTALL_PATH/php-client

COPY php-client/ $INSTALL_PATH/php-client

RUN cd $INSTALL_PATH/php-client \
    && wget https://getcomposer.org/download/1.3.2/composer.phar \
    && php composer.phar install

# install and enable cron job scripts
ADD env-php/cron_exec.sh $INSTALL_PATH/
RUN chmod +x $INSTALL_PATH/cron_exec.sh
# install and enable config cron
ADD env-php/daily.cron /etc/cron.d/daily-cron
RUN chmod 0644 /etc/cron.d/daily-cron \
    && crontab /etc/cron.d/daily-cron

# Script to copy secrets from files for env vars
ADD env-php/docker-entrypoint.sh $INSTALL_PATH/bin/docker-entrypoint.sh
RUN chmod +x $INSTALL_PATH/bin/docker-entrypoint.sh \
    && ln -s usr/local/bin/docker-entrypoint.sh / # backwards compat

VOLUME ["/usr/local/php-client/rawData","/usr/local/php-client/log"]

ENTRYPOINT [ "/docker-entrypoint.sh" ]