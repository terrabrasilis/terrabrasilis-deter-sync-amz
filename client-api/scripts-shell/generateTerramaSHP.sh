#!/bin/bash

# Import functions ===========================================
. ${SCRIPTS_BASE_PATH}/functions.lib.sh
# ============================================================

# get global env vars from Docker Secrets
export PGUSER=$(cat "$POSTGRES_USER_FILE")
export PGPASSWORD=$(cat "$POSTGRES_PASS_FILE")
export FTP_USER=$(cat "$FTP_USER_FILE")
export FTP_PASS=$(cat "$FTP_PASS_FILE")

# Configs for database connect
HOST=$POSTGRES_HOST
PORT=$POSTGRES_PORT

DATE_NOW=$(date +%Y-%m-%dT%H%M%S)
OUTPUT_FILE_NAME="deter_mt_$DATE_NOW"

# normalize output columns
OUTPUT_COLUMNS="tb1.gid, tb1.classname, tb1.quadrant, tb1.path_row, tb1.view_date::varchar, tb1.sensor, tb1.satellite, tb1.areauckm, tb1.uc, tb1.areamunkm, tb1.municipality, tb1.uf, tb1.geom"


if [ "$PROJECT_NAME" == "deter-terrama-mt" ];
then
	DB=$(getDBName $PROJECT_NAME)
	FILTER_ALL="0.01"
	QUERY="SELECT $OUTPUT_COLUMNS FROM public.deter_mt as tb1 WHERE tb1.areatotalkm >= "
fi;

# STATIC_FILES_DIR comes from /etc/environments, recorded by Dockerfile during compilation time
# Defines the destination directory of the generated files
TARGET_DIR=$STATIC_FILES_DIR

# work dir
WORKSPACE_DIR="${SHARED_DIR}/workspace/${PROJECT_NAME}"
if [ ! -d $WORKSPACE_DIR ];
then
	mkdir -p $WORKSPACE_DIR
fi;

DATE_LOG=$(date +%Y-%m-%d)
LOGFILE="terrama_ftp_push_$DATE_LOG.log"

cd $WORKSPACE_DIR/

pgsql2shp -f $WORKSPACE_DIR/$OUTPUT_FILE_NAME -h $HOST -u $PGUSER -P $PGPASSWORD -p $PORT $DB "$QUERY $FILTER_ALL"

# move files to target dir for publish
mv $WORKSPACE_DIR/$OUTPUT_FILE_NAME.* $TARGET_DIR

if [[ -f "$TARGET_DIR/$OUTPUT_FILE_NAME.shp" ]];
then
	cd "$TARGET_DIR"

	zip "$OUTPUT_FILE_NAME.zip" "$OUTPUT_FILE_NAME.shp" "$OUTPUT_FILE_NAME.shx" "$OUTPUT_FILE_NAME.prj" "$OUTPUT_FILE_NAME.dbf"

	# upload file to FTP
	curl -v --user "$FTP_USER:$FTP_PASS" --upload-file "$TARGET_DIR/$OUTPUT_FILE_NAME.zip" ftp://ftp.dgi.inpe.br/terrama2q/dtr_mt/ 2>&1 | tee -a "$TARGET_DIR/$LOGFILE"
	#curl -v --user "$FTP_USER:$FTP_PASS" --upload-file "$TARGET_DIR/$OUTPUT_FILE_NAME.{dbf,shp,shx,prj}" ftp://ftp.dgi.inpe.br/terrama2q/dtr_mt/ 2>&1 | tee -a "$TARGET_DIR/$LOGFILE"

# update the date of last data for keep controller 
SEL_DATE="SELECT MAX(date_audit) FROM jobs.deter_amz_online WHERE uf='MT'"
UPDATE="UPDATE public.last_release_mt SET amz_release_date=($SEL_DATE);"

PG_CON="-d $DB -h $HOST -p $PORT"
psql $PG_CON << EOF
$UPDATE
EOF

SEL_DATE="SELECT MAX(created_date) FROM jobs.deter_cerrado_online WHERE uf='MT'"
UPDATE="UPDATE public.last_release_mt SET cerrado_release_date=($SEL_DATE);"

PG_CON="-d $DB -h $HOST -p $PORT"
psql $PG_CON << EOF
$UPDATE
EOF

else
	echo "The file $OUTPUT_FILE_NAME not found." 2>&1 | tee -a "$TARGET_DIR/$LOGFILE"
fi;

# remove files after transfer
rm $TARGET_DIR/$OUTPUT_FILE_NAME.*

cd $SCRIPTS_BASE_PATH
. ./send-mail.sh