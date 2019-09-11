#!/bin/bash
# Used to change the publish date for weekly release of the DETER Amazon data.
# To block the release task, change manually the blocked field in public.deter_publish_date.

# get global env vars from Docker Secrets
export PGUSER=$(cat "$POSTGRES_USER_FILE")
export PGPASSWORD=$(cat "$POSTGRES_PASS_FILE")

QUERY="UPDATE public.deter_publish_date SET date=now() WHERE blocked=0;"


PG_CON="-d DETER-B -h $POSTGRES_HOST -p $POSTGRES_PORT"
psql $PG_CON << EOF
$QUERY
EOF

PG_CON="-d deter_cerrado -h $POSTGRES_HOST -p $POSTGRES_PORT"
psql $PG_CON << EOF
$QUERY
EOF