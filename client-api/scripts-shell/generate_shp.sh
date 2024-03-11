#!/bin/bash

# to logfile information
echo "Generating shapefiles for ${PROJECT_NAME}"
echo "-----------------------------------------------------------"

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
WORKSPACE_DIR="${SHARED_DIR}/workspace/${PROJECT_NAME}"
if [ ! -d $WORKSPACE_DIR ];
then
	mkdir -p $WORKSPACE_DIR
fi;

# normalize output columns
OUTPUT_COLUMNS="fid, uuid, class_name, area_km, view_date, audit_date, create_date, sensor, satellite, path_row, geom"

DB=$(getDBName $PROJECT_NAME)

FILTER_AUTH="0.00"
FILTER_PUBLIC="0.00"

QUERY_FILTER_AUTH="area_km >= ${FILTER_AUTH}"
QUERY_FILTER_PUBLIC="view_date <= (SELECT date FROM public.deter_publish_date) AND area_km >= ${FILTER_PUBLIC}"

# remove the fire scar class from the output shapefile
TMP_FILTER_CLASS=" AND class_name!='cicatriz de queimada'"

# this inputs is SQLViews on publish database
FROM_AUTH=" public.deter_auth "
FROM_PUBLIC=" public.deter_public "

SELECT_AUTH="SELECT ${OUTPUT_COLUMNS} FROM ${FROM_AUTH} WHERE ${QUERY_FILTER_AUTH} ${TMP_FILTER_CLASS}"
SELECT_PUBLIC="SELECT ${OUTPUT_COLUMNS} FROM ${FROM_PUBLIC} WHERE ${QUERY_FILTER_PUBLIC} ${TMP_FILTER_CLASS}"

cd $WORKSPACE_DIR/

pgsql2shp -f $WORKSPACE_DIR/${PROJECT_NAME}-deter-auth -h $HOST -u $USER -P $PASS $DB "$SELECT_AUTH"
pgsql2shp -f $WORKSPACE_DIR/${PROJECT_NAME}-deter-public -h $HOST -u $USER -P $PASS $DB "$SELECT_PUBLIC"

zip "all.zip" ${PROJECT_NAME}-deter-auth.shp ${PROJECT_NAME}-deter-auth.shx ${PROJECT_NAME}-deter-auth.prj ${PROJECT_NAME}-deter-auth.dbf ${PROJECT_NAME}-deter-auth.cpg
zip "public.zip" ${PROJECT_NAME}-deter-public.shp ${PROJECT_NAME}-deter-public.shx ${PROJECT_NAME}-deter-public.prj ${PROJECT_NAME}-deter-public.dbf ${PROJECT_NAME}-deter-public.cpg
#zip "public.zip" warning_about_data.txt

rm ${PROJECT_NAME}-deter-auth.{shp,shx,prj,dbf,cpg}
rm ${PROJECT_NAME}-deter-public.{shp,shx,prj,dbf,cpg}

# move files to target dir for publish
mv $WORKSPACE_DIR/"all.zip" $TARGET_DIR
mv $WORKSPACE_DIR/"public.zip" $TARGET_DIR