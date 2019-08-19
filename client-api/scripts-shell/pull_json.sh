#!/bin/bash
# get global env vars from Docker Secrets
export GEOSERVER_USER=$(cat "$GEOSERVER_USER_FILE")
export GEOSERVER_PASS=$(cat "$GEOSERVER_PASS_FILE")

# Log config
DATE=$(date +"%Y-%m-%d_%H:%M:%S")
LOG_DIR=/logs

# create log dir if no exists
if [ ! -d $LOG_DIR ];
then
	mkdir -p $LOG_DIR
fi;
# define log file for project
LOG=$LOG_DIR/$PROJECT_NAME.log

# target dir for generated files
TARGET_DIR=$NGINX_ROOT_DIR/$PROJECT_NAME

# create target dir if no exists
if [ ! -d $TARGET_DIR ];
then
	mkdir -p $TARGET_DIR
fi;

# Here, we read and test the arguments.
LAYER_NAME=""
if [ "$1" == "" ];
then
	exit
else
	LAYER_NAME=$1
fi;

AUTH="-u $GEOSERVER_USER:$GEOSERVER_PASS"

# Then we move the JSON file to a backup file using the "old" suffix.
if [ -f $TARGET_DIR/$LAYER_NAME.json ];
then
	mv $TARGET_DIR/$LAYER_NAME.json $TARGET_DIR/$LAYER_NAME-old.json
fi;

# After that, we request the new data in JSON format and putting it in a new file.
curl $AUTH $GEOSERVER_BASE_URL'/'$GEOSERVER_BASE_PATH'?SERVICE=WFS&REQUEST=GetFeature&VERSION=2.0.0&TYPENAME='$PROJECT_NAME'%3A'$LAYER_NAME'&OUTPUTFORMAT=application%2Fjson' \
-H 'Accept-Encoding: gzip, deflate, sdch' -H 'Accept-Language: pt-BR,pt;q=0.8,en-US;q=0.6,en;q=0.4' \
-H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/46.0.2490.86 Safari/537.36' \
-H 'Accept: */*' -H 'Referer: '$GEOSERVER_BASE_URL'/' -H 'X-Requested-With: XMLHttpRequest' \
--compressed >> $TARGET_DIR/$LAYER_NAME-new.json

# Finally, we test the result and remove the old file or, if the test has failed, we restore the old file as the current file.
if [ -f $TARGET_DIR/$LAYER_NAME-new.json ] ;
then
	if grep -q $LAYER_NAME $TARGET_DIR/$LAYER_NAME-new.json;
	then
		rm $TARGET_DIR/$LAYER_NAME-old.json
		mv $TARGET_DIR/$LAYER_NAME-new.json $TARGET_DIR/$LAYER_NAME.json
		echo $DATE" - The file "$LAYER_NAME-old.json" was removed and the new file "$LAYER_NAME" was created." >> $LOG
	else
		rm $TARGET_DIR/$LAYER_NAME-new.json
		mv $TARGET_DIR/$LAYER_NAME-old.json $TARGET_DIR/$LAYER_NAME.json
		echo $DATE" - The file "$LAYER_NAME-new.json" was removed and the old file "$LAYER_NAME" was retrieved." >> $LOG
	fi;
else
	mv $TARGET_DIR/$LAYER_NAME-old.json $TARGET_DIR/$LAYER_NAME.json
	echo $DATE" - The file "$LAYER_NAME-old.json" was retrieved." >> $LOG
fi;