#!/bin/bash
# get global env vars from Docker Secrets
export POSTGRES_USER=$(cat "$POSTGRES_USER_FILE")
export POSTGRES_PASS=$(cat "$POSTGRES_PASS_FILE")

# Configs for database connect
HOST=$POSTGRES_HOST
USER=$POSTGRES_USER
PASS=$POSTGRES_PASS

DATE_NOW=$(date '+%Y-%m-%d')
OUTPUT_FILE_NAME="deter_mt_$DATE_NOW"

# normalize output columns
OUTPUT_COLUMNS="tb1.gid, tb1.classname, tb1.quadrant, tb1.path_row, tb1.view_date::varchar, tb1.sensor, tb1.satellite, tb1.areauckm, tb1.uc, tb1.areamunkm, tb1.municipality, tb1.uf, tb1.geom"


if [ "$PROJECT_NAME" == "deter-amz" ];
then
	DB="DETER-B"
	FILTER_ALL="0.01"
	QUERY_AUTH="SELECT $OUTPUT_COLUMNS, tb1.areatotalkm FROM (SELECT gid, classname, quadrant, orbitpoint as path_row, date as view_date, lot, sensor, satellite, areatotalkm, areamunkm, areauckm, county as municipality, uf, uc, geom FROM deter_table WHERE date_audit = '$DATE_NOW') as tb1 WHERE tb1.uf='MT' AND tb1.areatotalkm >= "
fi;

# target dir for generated files
TARGET_DIR=$STATIC_FILES_DIR
# work dir
WORKSPACE_DIR=/shapefiles/$PROJECT_NAME

if [ ! -d $WORKSPACE_DIR ];
then
	mkdir -p $WORKSPACE_DIR
fi;

cd $WORKSPACE_DIR/

pgsql2shp -f $WORKSPACE_DIR/$OUTPUT_FILE_NAME -h $HOST -u $USER -P $PASS $DB "$QUERY_AUTH $FILTER_ALL"

zip "$OUTPUT_FILE_NAME.zip" "$OUTPUT_FILE_NAME.shp" "$OUTPUT_FILE_NAME.shx" "$OUTPUT_FILE_NAME.prj" "$OUTPUT_FILE_NAME.dbf"

# move files to target dir for publish
mv "$WORKSPACE_DIR/$OUTPUT_FILE_NAME.zip" $TARGET_DIR