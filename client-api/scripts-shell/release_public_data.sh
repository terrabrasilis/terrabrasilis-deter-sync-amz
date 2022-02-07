#!/bin/bash
# Used to change the publish date for weekly release of the DETER data.
# To block the release task, change manually the blocked field in public.deter_publish_date.

# Import functions ===========================================
. ./functions.lib.sh
# ============================================================

# get global env vars from Docker Secrets
export PGUSER=$(cat "$POSTGRES_USER_FILE")
export PGPASSWORD=$(cat "$POSTGRES_PASS_FILE")

PROJECTS=("deter-amz" "deter-cerrado-nb")
# query to release data every week. The week day is defined in cronjob
QUERY="UPDATE public.deter_publish_date SET date=(now() - interval '1 week') WHERE blocked=0;"

for PROJECT_NAME in ${PROJECTS[@]}
do

DB=$(getDBName ${PROJECT_NAME})
PG_CON="-d ${DB} -h $POSTGRES_HOST -p $POSTGRES_PORT"
psql $PG_CON << EOF
$QUERY
EOF

done