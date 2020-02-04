#!/bin/bash
# get global env vars from Docker Secrets
export POSTGRES_USER=$(cat "$POSTGRES_USER_FILE")
export POSTGRES_PASS=$(cat "$POSTGRES_PASS_FILE")

# Configs for database connect
HOST=$POSTGRES_HOST
USER=$POSTGRES_USER
PASS=$POSTGRES_PASS

# normalize output columns
OUTPUT_COLUMNS="tb1.gid, tb1.classname, tb1.quadrant, tb1.path_row, tb1.view_date, tb1.sensor, tb1.satellite, tb1.areauckm, tb1.uc, tb1.areamunkm, tb1.municipality, tb1.uf, tb1.geom"


if [ "$PROJECT_NAME" == "deter-cerrado" ];
then
    DB="deter_cerrado"

	FILTER_PUBLIC="0.03"
	FILTER_ALL="0.01"

	QUERY_PUBLIC="SELECT $OUTPUT_COLUMNS FROM (SELECT origin_gid||'_0' as gid, 'aviso' as classname, quadrant, path_row, view_date, created_date, sensor, satellite, areatotalkm, areauckm, uc, areamunkm, county as municipality,  uf, geom FROM deter_cerrado_mun_ucs WHERE created_date <= (SELECT date FROM public.deter_publish_date) UNION SELECT origin_gid||'_1' as gid, 'aviso' as classname, quadrant, path_row, view_date, created_date, sensor, satellite, areatotalkm, areauckm, uc, areamunkm, county as municipality,  uf, geom FROM deter_cerrado_history) as tb1 WHERE tb1.areatotalkm >= "
	QUERY_AUTH="SELECT $OUTPUT_COLUMNS, tb1.areatotalkm FROM (SELECT origin_gid||'_0' as gid, 'aviso' as classname, quadrant, path_row, view_date, created_date, sensor, satellite, areatotalkm, areauckm, uc, areamunkm, county as municipality,  uf, geom FROM deter_cerrado_mun_ucs UNION SELECT origin_gid||'_1' as gid, 'aviso' as classname, quadrant, path_row, view_date, created_date, sensor, satellite, areatotalkm, areauckm, uc, areamunkm, county as municipality,  uf, geom FROM deter_cerrado_history) as tb1 WHERE tb1.areatotalkm >= "
else
	DB="DETER-B"

	FILTER_PUBLIC="0.0625"
	FILTER_ALL="0.01"
    QUERY_PUBLIC="SELECT $OUTPUT_COLUMNS FROM (SELECT gid||'_0' as gid, classname, quadrant, orbitpoint as path_row, date as view_date, lot, sensor, satellite, areatotalkm, areamunkm, areauckm, county as municipality,  uf, uc, geom FROM deter_table WHERE date > '2018-07-31' AND date_audit <= (SELECT date FROM public.deter_publish_date) UNION SELECT gid||'_1', classname, quadrant, orbitpoint as path_row, date as view_date, lot, sensor, satellite, areatotalkm, areamunkm, areauckm, county as municipality,  uf, uc, geom FROM deter_history) as tb1 WHERE tb1.areatotalkm >= "
	QUERY_AUTH="SELECT $OUTPUT_COLUMNS, tb1.areatotalkm FROM (SELECT gid||'_0' as gid, classname, quadrant, orbitpoint as path_row, date as view_date, lot, sensor, satellite, areatotalkm, areamunkm, areauckm, county as municipality,  uf, uc, geom FROM deter_table WHERE date > '2018-07-31' UNION SELECT gid||'_1', classname, quadrant, orbitpoint as path_row, date as view_date, lot, sensor, satellite, areatotalkm, areamunkm, areauckm, county as municipality,  uf, uc, geom FROM deter_history) as tb1 WHERE tb1.areatotalkm >= "
fi;

# target dir for generated files
TARGET_DIR=$SHARED_DIR/$PROJECT_NAME
# work dir
WORKSPACE_DIR=/shapefiles/$PROJECT_NAME

if [ ! -d $WORKSPACE_DIR ];
then
	mkdir -p $WORKSPACE_DIR
fi;

cd $WORKSPACE_DIR/

pgsql2shp -f $WORKSPACE_DIR/deter_all -h $HOST -u $USER -P $PASS $DB "$QUERY_AUTH $FILTER_ALL"
pgsql2shp -f $WORKSPACE_DIR/deter_public -h $HOST -u $USER -P $PASS $DB "$QUERY_PUBLIC $FILTER_PUBLIC"

zip "all.zip" deter_all.shp deter_all.shx deter_all.prj deter_all.dbf
zip "public.zip" deter_public.shp deter_public.shx deter_public.prj deter_public.dbf

# move files to target dir for publish
mv $WORKSPACE_DIR/"all.zip" $TARGET_DIR
mv $WORKSPACE_DIR/"public.zip" $TARGET_DIR