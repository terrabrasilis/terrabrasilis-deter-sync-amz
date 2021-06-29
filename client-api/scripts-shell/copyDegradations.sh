#!/bin/bash
# get global env vars from Docker Secrets
export POSTGRES_USER=$(cat "$POSTGRES_USER_FILE")
export POSTGRES_PASS=$(cat "$POSTGRES_PASS_FILE")

# Configs for database connect
HOST=$POSTGRES_HOST
USER=$POSTGRES_USER
PASS=$POSTGRES_PASS

DB="DETER-B"

LIST_COLUMNS="origin_gid, uuid, classname, quadrant, orbitpoint, date, date_audit, lot, sensor, satellite, areatotalkm, areamunkm, areauckm, county, uf, uc, geom, publish_month"

INSERT="INSERT INTO terrabrasilis.degradations($LIST_COLUMNS) SELECT $LIST_COLUMNS FROM terrabrasilis.deter_table WHERE classname in ('DEGRADACAO','CS_DESORDENADO','CS_GEOMETRICO','CICATRIZ_DE_QUEIMADA') AND date_audit > (SELECT MAX(date_audit) FROM terrabrasilis.degradations)"
export PGPASSWORD=$PASS
psql -h $HOST -U $USER -d $DB -c "$INSERT"