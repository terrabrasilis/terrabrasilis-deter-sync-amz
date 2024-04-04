#!/bin/bash

# Import functions ===========================================
. ${SCRIPTS_BASE_PATH}/functions.lib.sh
# ============================================================

# Prepare data on production database
#
# get audited cells/tasks/scenes using the task status, cell status and audit phase
WITH="WITH candidates AS ( "
WITH="${WITH}	SELECT scene.id as scene_id, cl.cell_id, task.id as task_id, scene.view_date, split_part(upper(cat.name::text), '_'::text, 2) AS satelite, MAX(tl.final_time) as task_date "
WITH="${WITH}	FROM "
WITH="${WITH}	terraamazon.ta_celllog cl, "
WITH="${WITH}	terraamazon.ta_task task, "
WITH="${WITH}	terraamazon.ta_phase phase, "
WITH="${WITH}	terraamazon.ta_scene scene, "
WITH="${WITH}	terraamazon.ta_tasklog tl, "
WITH="${WITH}	terraamazon.ta_catalog cat, "
WITH="${WITH}	terraamazon.ta_aoi_layer layer "
WITH="${WITH}	WHERE "
WITH="${WITH}	cl.task_id = task.id "
WITH="${WITH}	AND scene.aoi_layer_id = layer.catalog_id "
WITH="${WITH}	AND cat.id = layer.catalog_id "
WITH="${WITH}	AND task.phase_id = phase.id "
WITH="${WITH}	AND task.scene_id = scene.id  "
WITH="${WITH}	AND task.id = tl.task_id "
WITH="${WITH}	AND cl.task_id = tl.task_id "
WITH="${WITH}	AND tl.status = 'CLOSED' "
WITH="${WITH}	AND lower(phase.description) = lower('Auditoria') "
WITH="${WITH}	AND cl.finalized "
WITH="${WITH}	GROUP BY 1,2,3,4,5 "
WITH="${WITH}) "

# get production database name 
DB=$(getProductionDBName $PROJECT_NAME)

# the config parameters, POSTGRES_HOST_PROD and POSTGRES_PORT_PROD, has readed from /etc/environment at start cronjob
# get global env vars from Docker Secrets
export POSTGRES_USER=$(cat "$POSTGRES_PROD_USER_FILE")
export PGPASSWORD=$(cat "$POSTGRES_PROD_PASS_FILE")

PRODUCTION_TABLES=("transitorias" "finais_sob_transitorias" "finais")
for TABLE in ${PRODUCTION_TABLES[@]}
do
    SET_AUDIT_DATE="${WITH}, audited AS ( "
    SET_AUDIT_DATE="${SET_AUDIT_DATE} 	SELECT des.object_id, cd.satelite, cd.task_date::date as audit_date "
    SET_AUDIT_DATE="${SET_AUDIT_DATE} 	FROM public.${TABLE} des, candidates cd "
    SET_AUDIT_DATE="${SET_AUDIT_DATE} 	WHERE des.scene_id=cd.scene_id AND des.cell_oid=cd.cell_id "
    SET_AUDIT_DATE="${SET_AUDIT_DATE} 	AND des.view_date=cd.view_date AND cd.task_date::date >= created_date::date "
    SET_AUDIT_DATE="${SET_AUDIT_DATE} 	AND des.audit_date IS NULL "
    SET_AUDIT_DATE="${SET_AUDIT_DATE} ) "
    SET_AUDIT_DATE="${SET_AUDIT_DATE} UPDATE public.${TABLE} SET audit_date=audited.audit_date, satellite=audited.satelite "
    SET_AUDIT_DATE="${SET_AUDIT_DATE} FROM audited WHERE public.${TABLE}.object_id=audited.object_id;"
    psql -h ${POSTGRES_HOST_PROD} -U ${POSTGRES_USER} -p ${POSTGRES_PORT_PROD} -d ${DB} -c "${SET_AUDIT_DATE}"
done

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
COPY="INSERT INTO public.deter_current( "
COPY="${COPY} geom, class_name, area_km, view_date, create_date, audit_date, satellite, object_id) "
COPY="${COPY} SELECT ST_Multi(spatial_data), class_name, (ST_Area(spatial_data::geography)/1000000) as area_km, view_date, created_date, audit_date, satellite, object_id "
COPY="${COPY} FROM public.deter_prod_def_current "
COPY="${COPY} WHERE created_date::date>(SELECT COALESCE(MAX(create_date), (SELECT end_date FROM public.prodes_reference)) FROM public.deter_current) "
COPY="${COPY} ${LAZY_LOAD}"
# COPY="${COPY} AND audit_date IS NOT NULL;"
psql -h ${POSTGRES_HOST} -U ${POSTGRES_USER} -p ${POSTGRES_PORT} -d ${DB} -c "${COPY}"

# Remove all degradation alerts from current table
DEL="DELETE FROM public.deter_current WHERE class_name='cicatriz de queimada';"
psql -h ${POSTGRES_HOST} -U ${POSTGRES_USER} -p ${POSTGRES_PORT} -d ${DB} -c "${DEL}"

# using SQL View through DBLink to copy degradation alerts (only audited data)
COPY="INSERT INTO public.deter_current( "
COPY="${COPY} geom, class_name, area_km, view_date, create_date, audit_date, satellite, object_id) "
COPY="${COPY} SELECT ST_Multi(spatial_data), class_name, (ST_Area(spatial_data::geography)/1000000) as area_km, view_date, created_date, audit_date, satellite, object_id "
COPY="${COPY} FROM public.deter_prod_deg_current WHERE view_date >= (SELECT end_date FROM public.prodes_reference) "
COPY="${COPY} ${LAZY_LOAD}"

# COPY="${COPY} AND audit_date IS NOT NULL;"
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