#!/bin/bash
# get global env vars from Docker Secrets
export POSTGRES_USER=$(cat "$POSTGRES_USER_FILE")
export POSTGRES_PASS=$(cat "$POSTGRES_PASS_FILE")

# Configs for database connect
HOST=$POSTGRES_HOST
USER=$POSTGRES_USER
PASS=$POSTGRES_PASS

if [ "$PROJECT_NAME" == "deter-cerrado" ];
then
    DB="deter_cerrado"

	FILTER_PUBLIC="0.03"
	FILTER_ALL="0.01"
	QUERY_PUBLIC="SELECT tb1.gid, tb1.classname, tb1.quadrant, tb1.path_row, tb1.view_date, tb1.created_date, tb1.sensor, tb1.satellite, tb1.areauckm, tb1.uc, tb1.areamunkm, tb1.county, tb1.uf, tb1.geom FROM (SELECT origin_gid||'_curr' as gid, classname, quadrant, path_row, view_date, created_date, sensor, satellite, areatotalkm, areauckm, uc, areamunkm, county, uf, geom FROM deter_cerrado_mun_ucs UNION SELECT origin_gid||'_hist' as gid, classname, quadrant, path_row, view_date, created_date, sensor, satellite, areatotalkm, areauckm, uc, areamunkm, county, uf, geom FROM deter_cerrado_history) as tb1 WHERE tb1.areatotalkm >= "
	QUERY_ALL="SELECT tb1.gid, tb1.classname, tb1.quadrant, tb1.path_row, tb1.view_date, tb1.created_date, tb1.sensor, tb1.satellite, tb1.areauckm, tb1.uc, tb1.areamunkm, tb1.county, tb1.uf, tb1.geom FROM (SELECT origin_gid||'_curr' as gid, classname, quadrant, path_row, view_date, created_date, sensor, satellite, areatotalkm, areauckm, uc, areamunkm, county, uf, geom FROM deter_cerrado_mun_ucs UNION SELECT origin_gid||'_hist' as gid, classname, quadrant, path_row, view_date, created_date, sensor, satellite, areatotalkm, areauckm, uc, areamunkm, county, uf, geom FROM deter_cerrado_history) as tb1 WHERE tb1.areatotalkm >= "
else
	DB="DETER-B"

	FILTER_PUBLIC="0.0625"
	FILTER_ALL="0.01"
    QUERY_PUBLIC="SELECT * FROM (SELECT gid||'_curr' as gid, classname, quadrant, orbitpoint, date, lot, sensor, satellite, areatotalkm, areamunkm, areauckm, county, uf, uc, geom FROM deter_table WHERE date > '2018-07-31' AND date <= (SELECT date FROM public.deter_publish_date) UNION SELECT gid||'_hist', classname, quadrant, orbitpoint, date, lot, sensor, satellite, areatotalkm, areamunkm, areauckm, county, uf, uc, geom FROM deter_history) as tb1 WHERE tb1.areatotalkm >= "
	QUERY_ALL="SELECT * FROM (SELECT gid||'_curr' as gid, classname, quadrant, orbitpoint, date, lot, sensor, satellite, areatotalkm, areamunkm, areauckm, county, uf, uc, geom FROM deter_table WHERE date > '2018-07-31' UNION SELECT gid||'_hist', classname, quadrant, orbitpoint, date, lot, sensor, satellite, areatotalkm, areamunkm, areauckm, county, uf, uc, geom FROM deter_history) as tb1 WHERE tb1.areatotalkm >= "
	# Update publish_month column to working with time dimension on GeoServer.
	UPDATE="UPDATE terrabrasilis.deter_table SET publish_month=overlay(date::varchar placing '01' from 9 for 2)::date"
	export PGPASSWORD=$PASS
	psql -h $HOST -U $USER -d $DB -c "$UPDATE"
fi;

# target dir for generated files
TARGET_DIR=$NGINX_ROOT_DIR/$PROJECT_NAME
# work dir
WORKSPACE_DIR=/shapefiles/$PROJECT_NAME

if [ ! -d $WORKSPACE_DIR ];
then
	mkdir -p $WORKSPACE_DIR
fi;

cd $WORKSPACE_DIR/

pgsql2shp -f $WORKSPACE_DIR/deter_all -h $HOST -u $USER -P $PASS $DB "$QUERY_ALL $FILTER_ALL"
pgsql2shp -f $WORKSPACE_DIR/deter_public -h $HOST -u $USER -P $PASS $DB "$QUERY_PUBLIC $FILTER_PUBLIC"

zip $PROJECT_NAME"_all.zip" deter_all.shp deter_all.shx deter_all.prj deter_all.dbf
zip $PROJECT_NAME"_public.zip" deter_public.shp deter_public.shx deter_public.prj deter_public.dbf

# move files to target dir for publish
mv $WORKSPACE_DIR/$PROJECT_NAME"_all.zip" $TARGET_DIR
mv $WORKSPACE_DIR/$PROJECT_NAME"_public.zip" $TARGET_DIR