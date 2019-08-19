# Docker Client API - HTTP client

Defines the environment to run the php client API described in [php-client README](https://gitlab.dpi.inpe.br/terrabrasilis/terrabrasilis/tree/latest/deterb-sync/client-api/php-client)

## Scripts workflow

Are two entry points:
- index.php, connects to the remote API and download all data to a SQL insert script file, access the local database and restore the data, running the downloaded script.
- checkStatus.php, verify the state of the last execute and send mail to accounts defined by MAIL_TO in client-api-stack.yaml.

## Base configuration

The allow configuration is:
- the hour for the cron job (use the daily.cron file)*;
- the URL location for API service (use the SYNC_SERVICE_HOST: http://200.18.85.22/ in client-api-stack.yaml);
- the user and password for API service (use Docker Secrets as below);
  - SYNC_SERVICE_USER_FILE: /run/secrets/api.sync.deterb.amz.user
  - SYNC_SERVICE_PASS_FILE: /run/secrets/api.sync.deterb.amz.pass
- the host name for postgres server (use the POSTGRES_HOST: "the_ip_or_name_for_host" in client-api-stack.yaml);
- the user and password for SMTP service (use Docker Secrets as below);
  - SMTP_GOOGLE_MAIL_USER_FILE: /run/secrets/google.mail.user
  - SMTP_GOOGLE_MAIL_PASS_FILE: /run/secrets/google.mail.pass
- Email accounts to receive status emails (use MAIL_TO: andre.carvalho@inpe.br in client-api-stack.yaml);
- the user and password for access the SGDB postgres (use Docker Secrets as below);
  - POSTGRES_USER_FILE: /run/secrets/postgres.user.geoserver
  - POSTGRES_PASS_FILE: /run/secrets/postgres.pass.geoserver

```yaml
echo "email" |docker secret create google.mail.user -
echo "email_pass" |docker secret create google.mail.pass -
echo "API_user" |docker secret create api.sync.deterb.amz.user -
echo "API_pass" |docker secret create api.sync.deterb.amz.pass -
echo "pg_user" |docker secret create postgres.user.geoserver -
echo "pg_pass" |docker secret create postgres.pass.geoserver -
```

*Needs rebuild Docker Image

This software needs the pre-defined names for database and table. So, if you want or need to change the default database or table for DETER-B AMZ, you need to changes this code as well.

## Build the docker

To build image for this dockerfile use this command:

```bash
docker build -t terrabrasilis/deter-amz-sync-client:v0.3 -f env-php/Dockerfile --no-cache .
```

## Run on docker (dev)

To run locally in dev environment, change the Dockerfile including the RUN command to create secret files for simulate the docker secrets outside Swarm.

Example for simulate Docker Secrets.
```yaml
RUN echo "API_user" > /run/secrets/api.sync.deterb.amz.user \
    && echo "secret_for_API" > /run/secrets/api.sync.deterb.amz.pass \
    && echo "postgres" > /run/secrets/postgres.user.geoserver \
    && echo "secret_for_postgres" > /run/secrets/postgres.pass.geoserver
```

```bash
docker run -d --rm --name terrabrasilis_deter_client_api terrabrasilis/deter-amz-sync-client:v0.3
```

### To login inside container

```bash
docker container exec -it <container_id_or_name> sh
```

## Run on stack

For run this service on Swarm use the client-api-stack.yaml.

Preconditions:
- Create the directory into the file system of the docker manager node for persist the downloaded SQL Script file;
- Edit the client-api-stack.yaml to point the working directory created above;
- Create the secrets into docker manager node to store the user names and passwords for API service, postgres and SMTP account used by the code in client mode;
- Edit the client-api-stack.yaml to inform the name of the docker secret for API service, postgres and SMTP account if is needed*;

*The dockerfile expect the Docker Secrets as follows:
- geoserver.user.dashboard
- geoserver.pass.dashboard
- google.mail.user
- google.mail.pass
- api.sync.deterb.amz.user
- api.sync.deterb.amz.pass
- postgres.user.geoserver
- postgres.pass.geoserver
