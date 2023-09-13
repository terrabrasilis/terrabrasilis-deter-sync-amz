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
# used if project is DETER-AMZ to include a warning file inside generated ZIP
WARNING_FILE=""

# normalize output columns
OUTPUT_COLUMNS="tb1.gid, tb1.classname, tb1.quadrant, tb1.path_row, tb1.view_date, tb1.sensor, tb1.satellite, tb1.areauckm, tb1.uc, tb1.areamunkm, tb1.municipality, tb1.geocodibge, tb1.uf, tb1.geom"


if [ "$PROJECT_NAME" == "deter-cerrado-nb" ];
then
  DB=$(getDBName $PROJECT_NAME)

	FILTER_PUBLIC="0.03"
	FILTER_AUTH="0.01"
	QUERY_FILTER_PUBLIC="view_date <= (SELECT date FROM public.deter_publish_date) AND tb1.areatotalkm >= "
	QUERY_FILTER_AUTH="view_date <= now()::date AND tb1.areatotalkm >= "

	QUERY="(SELECT gid||'_curr' as gid, 'DESMATAMENTO_CR' as classname, "
	QUERY="${QUERY}quadrant, path_row, view_date, created_date, sensor, satellite, areatotalkm, areauckm, uc, areamunkm, "
	QUERY="${QUERY}county as municipality, geocod as geocodibge, uf, ST_Multi(geom)::geometry(MultiPolygon,4674) as geom FROM deter_cerrado_mun_ucs "
	QUERY="${QUERY}UNION "
	QUERY="${QUERY}SELECT gid||'_hist' as gid, 'DESMATAMENTO_CR' as classname, "
	QUERY="${QUERY}quadrant, path_row, view_date, created_date, sensor, satellite, areatotalkm, areauckm, uc, areamunkm, "
	QUERY="${QUERY}county as municipality, geocod as geocodibge, uf, ST_Multi(geom)::geometry(MultiPolygon,4674) as geom FROM deter_cerrado_history) as tb1 "
	QUERY="${QUERY}WHERE "

	SELECT_PUBLIC="SELECT $OUTPUT_COLUMNS FROM "
	QUERY_PUBLIC="${SELECT_PUBLIC} ${QUERY} ${QUERY_FILTER_PUBLIC}"

	SELECT_AUTH="SELECT $OUTPUT_COLUMNS, tb1.areatotalkm as areatotkm FROM "
	QUERY_AUTH="${SELECT_AUTH} ${QUERY} ${QUERY_FILTER_AUTH}"

else
	# The warning file is found on the external volume where the generated files are being placed.
	WARNING_FILE="warning_about_area.txt"
	if [ ! -f $WORKSPACE_DIR/$WARNING_FILE ] ;
	then
		cp -a "$SCRIPTS_BASE_PATH/$WARNING_FILE" "$WORKSPACE_DIR/$WARNING_FILE"
	fi;

	DB=$(getDBName $PROJECT_NAME)

	FILTER_PUBLIC="0.0625"
	FILTER_AUTH="0.01"
	QUERY_FILTER_AUTH="uf != ('MS') AND tb1.areatotalkm >= "
	QUERY_FILTER_PUBLIC="view_date <= (SELECT date FROM public.deter_publish_date) AND ${QUERY_FILTER_AUTH}"

	QUERY="(SELECT id||'_curr' as gid, classname, "
	QUERY="${QUERY}quadrant, orbitpoint as path_row, date as view_date, lot, sensor, satellite, areatotalkm, areamunkm, "
	QUERY="${QUERY}areauckm, county as municipality, geocod as geocodibge, uf, uc, geom FROM deter_table "
	QUERY="${QUERY}WHERE date > (SELECT end_date FROM public.prodes_reference) "
	QUERY="${QUERY}UNION "
	QUERY="${QUERY}SELECT gid||'_hist', classname, "
	QUERY="${QUERY}quadrant, orbitpoint as path_row, date as view_date, lot, sensor, satellite, areatotalkm, areamunkm, "
	QUERY="${QUERY}areauckm, county as municipality, geocod as geocodibge, uf, uc, geom FROM deter_history) as tb1 "
	QUERY="${QUERY}WHERE "

	SELECT_PUBLIC="SELECT $OUTPUT_COLUMNS FROM "
	QUERY_PUBLIC="${SELECT_PUBLIC} ${QUERY} ${QUERY_FILTER_PUBLIC}"

	SELECT_AUTH="SELECT $OUTPUT_COLUMNS, tb1.areatotalkm as areatotkm FROM "
	QUERY_AUTH="${SELECT_AUTH} ${QUERY} ${QUERY_FILTER_AUTH}"
fi;

cd $WORKSPACE_DIR/

pgsql2shp -f $WORKSPACE_DIR/${PROJECT_NAME}-deter-auth -h $HOST -u $USER -P $PASS $DB "$QUERY_AUTH $FILTER_AUTH"
pgsql2shp -f $WORKSPACE_DIR/${PROJECT_NAME}-deter-public -h $HOST -u $USER -P $PASS $DB "$QUERY_PUBLIC $FILTER_PUBLIC"

zip "all.zip" ${PROJECT_NAME}-deter-auth.shp ${PROJECT_NAME}-deter-auth.shx ${PROJECT_NAME}-deter-auth.prj ${PROJECT_NAME}-deter-auth.dbf $WARNING_FILE
zip "public.zip" ${PROJECT_NAME}-deter-public.shp ${PROJECT_NAME}-deter-public.shx ${PROJECT_NAME}-deter-public.prj ${PROJECT_NAME}-deter-public.dbf

rm ${PROJECT_NAME}-deter-auth.{shp,shx,prj,dbf}
rm ${PROJECT_NAME}-deter-public.{shp,shx,prj,dbf}

# move files to target dir for publish
mv $WORKSPACE_DIR/"all.zip" $TARGET_DIR
mv $WORKSPACE_DIR/"public.zip" $TARGET_DIR