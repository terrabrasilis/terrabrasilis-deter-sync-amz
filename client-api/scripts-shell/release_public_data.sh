#!/bin/bash
# Used to change the publish date for weekly release of the DETER Amazon data.
# To block the release task, change manually the blocked field in public.deter_publish_date.

# uncoment this to use in production
#export PGUSER=`cat /run/secrets/postgres.user.deter.amz`
#export PGPASSWORD=`cat /run/secrets/postgres.pass.deter.amz`
#host="$POSTGRES_HOST"

export PGUSER="postgres"
export PGPASSWORD="postgres"
host="150.163.17.103"

database="deterb"
port=5432
PG_CON="-d $database -h $host -p $port"

QUERY="UPDATE public.deter_publish_date SET date=now() WHERE blocked=0;"

psql $PG_CON << EOF
$QUERY
EOF