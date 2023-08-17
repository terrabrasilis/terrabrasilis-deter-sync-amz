#!/bin/bash

# Import functions ===========================================
. ${SCRIPTS_BASE_PATH}/functions.lib.sh
# ============================================================

# get global env vars from Docker Secrets
export POSTGRES_USER=$(cat "$POSTGRES_USER_FILE")
export POSTGRES_PASS=$(cat "$POSTGRES_PASS_FILE")

# Configs for database connect
HOST=$POSTGRES_HOST
USER=$POSTGRES_USER
PASS=$POSTGRES_PASS

# target dir for generated files
TARGET_DIR=$SHARED_DIR/$PROJECT_NAME
# work dir
WORKSPACE_DIR=/shapefiles/$PROJECT_NAME
if [ ! -d $WORKSPACE_DIR ];
then
	mkdir -p $WORKSPACE_DIR
fi;

# normalize output columns
OUTPUT_COLUMNS="fid, uuid, class_name, area_km, view_date, audit_date, create_date, sensor, satellite, path_row, geom"

DB=$(getDBName $PROJECT_NAME)

FILTER_AUTH="0.01"
FILTER_PUBLIC="0.01"

QUERY_FILTER_AUTH="area_km >= "
QUERY_FILTER_PUBLIC="view_date <= (SELECT date FROM public.deter_publish_date) AND ${QUERY_FILTER_AUTH}"

FROM_AUTH=" public.deter_auth "
FROM_PUBLIC=" public.deter_public "

SELECT_AUTH="SELECT ${OUTPUT_COLUMNS} FROM ${FROM_AUTH} WHERE ${QUERY_FILTER_AUTH}"
SELECT_PUBLIC="SELECT ${OUTPUT_COLUMNS} FROM ${FROM_PUBLIC} WHERE ${QUERY_FILTER_PUBLIC}"

cd $WORKSPACE_DIR/

pgsql2shp -f $WORKSPACE_DIR/deter_auth -h $HOST -u $USER -P $PASS $DB "$SELECT_AUTH $FILTER_AUTH"
pgsql2shp -f $WORKSPACE_DIR/deter_public -h $HOST -u $USER -P $PASS $DB "$SELECT_PUBLIC $FILTER_PUBLIC"

zip "${PROJECT_NAME}-auth.zip" deter_auth.shp deter_auth.shx deter_auth.prj deter_auth.dbf
zip "${PROJECT_NAME}-public.zip" deter_public.shp deter_public.shx deter_public.prj deter_public.dbf

# move files to target dir for publish
mv $WORKSPACE_DIR/"${PROJECT_NAME}-auth.zip" $TARGET_DIR
mv $WORKSPACE_DIR/"${PROJECT_NAME}-public.zip" $TARGET_DIR