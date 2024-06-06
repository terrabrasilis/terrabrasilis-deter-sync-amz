#!/bin/bash

# Import functions ===========================================
. ${SCRIPTS_BASE_PATH}/functions.lib.sh
# ============================================================

# Copy data from production database to publish database
#
# get global env vars from Docker Secrets
export POSTGRES_USER=$(cat "$POSTGRES_USER_FILE")
export PGPASSWORD=$(cat "$POSTGRES_PASS_FILE")
# get publish database name 
DB=$(getDBName $PROJECT_NAME)
#
# rule to copy data from NF database
LAZY_LOAD=""
if [ "$PROJECT_NAME" == "deter-nf" ];
then
    REF_DATE=$(date -d '2 day ago' '+%Y%m%d')
    LAZY_LOAD="AND created_date::date < '${REF_DATE}'::date"
fi;

# using SQL View through DBLink to copy new deforestation alerts (only audited data)
COPY="INSERT INTO public.deter_current(uuid, geom, class_name, area_km, view_date, create_date, audit_date, sensor, satellite, path_row, object_id) "
COPY="${COPY} SELECT uuid::uuid, ST_Multi(spatial_data), class_name, (ST_Area(spatial_data::geography)/1000000) as area_km, view_date, "
COPY="${COPY} created_date, audited_date, sensor, satellite, path_row, object_id "
COPY="${COPY} FROM public.deter_prod_def_current "
COPY="${COPY} WHERE audited_date::date>(SELECT COALESCE(MAX(audit_date), (SELECT end_date FROM public.prodes_reference)) FROM public.deter_current) "
COPY="${COPY} ${LAZY_LOAD}"
COPY="${COPY} AND audited_date IS NOT NULL;"
psql -h ${POSTGRES_HOST} -U ${POSTGRES_USER} -p ${POSTGRES_PORT} -d ${DB} -c "${COPY}"

# Remove all degradation alerts from current table
DEL="DELETE FROM public.deter_current WHERE class_name='cicatriz de queimada';"
psql -h ${POSTGRES_HOST} -U ${POSTGRES_USER} -p ${POSTGRES_PORT} -d ${DB} -c "${DEL}"

# using SQL View through DBLink to copy degradation alerts (only audited data)
COPY="INSERT INTO public.deter_current( "
COPY="${COPY} geom, class_name, area_km, view_date, create_date, audit_date, sensor, satellite, path_row, object_id) "
COPY="${COPY} SELECT ST_Multi(spatial_data), class_name, (ST_Area(spatial_data::geography)/1000000) as area_km, view_date, "
COPY="${COPY} created_date, audited_date, sensor, satellite, path_row, object_id "
COPY="${COPY} FROM public.deter_prod_deg_current WHERE view_date >= (SELECT end_date FROM public.prodes_reference) "
COPY="${COPY} ${LAZY_LOAD}"
COPY="${COPY} AND audited_date IS NOT NULL;"
psql -h ${POSTGRES_HOST} -U ${POSTGRES_USER} -p ${POSTGRES_PORT} -d ${DB} -c "${COPY}"

# rename classes to (Supressão com solo exposto, supressão com vegetação, mineração e cicatriz de queimada)
CHANGE_CLASS_NAME="UPDATE public.deter_current SET class_name='supressão com solo exposto' WHERE class_name ilike '%DESMAT_SOLO_EXP%';"
psql -h ${POSTGRES_HOST} -U ${POSTGRES_USER} -p ${POSTGRES_PORT} -d ${DB} -c "${CHANGE_CLASS_NAME}"
CHANGE_CLASS_NAME="UPDATE public.deter_current SET class_name='supressão com vegetação' WHERE class_name ilike '%DESMAT_VEG%';"
psql -h ${POSTGRES_HOST} -U ${POSTGRES_USER} -p ${POSTGRES_PORT} -d ${DB} -c "${CHANGE_CLASS_NAME}"
CHANGE_CLASS_NAME="UPDATE public.deter_current SET class_name='mineração' WHERE class_name ilike '%MINERACAO%';"
psql -h ${POSTGRES_HOST} -U ${POSTGRES_USER} -p ${POSTGRES_PORT} -d ${DB} -c "${CHANGE_CLASS_NAME}"
CHANGE_CLASS_NAME="UPDATE public.deter_current SET class_name='cicatriz de queimada' WHERE class_name ilike '%QUEIMADA%';"
psql -h ${POSTGRES_HOST} -U ${POSTGRES_USER} -p ${POSTGRES_PORT} -d ${DB} -c "${CHANGE_CLASS_NAME}"

# Update statement from Maurano's report code
INTERSECTS_MUN="UPDATE public.deter_current as dt SET municipio=mun.nome, geocodigo=mun.geocodigo, uf=mun.uf"
INTERSECTS_MUN="${INTERSECTS_MUN} FROM public.municipalities_biome as mun WHERE ST_INTERSECTS(dt.geom, mun.geom) AND dt.uf is NULL;"
psql -h ${POSTGRES_HOST} -U ${POSTGRES_USER} -p ${POSTGRES_PORT} -d ${DB} -c "${INTERSECTS_MUN}"