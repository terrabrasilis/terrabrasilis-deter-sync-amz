#!/bin/bash

# to logfile information
echo "Generating CSV files for ${PROJECT_NAME}"
echo "-----------------------------------------------------------"

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
TARGET_DIR=$SHARED_DIR/$PROJECT_NAME

# create target dir if no exists
if [ ! -d $TARGET_DIR ];
then
	mkdir -p $TARGET_DIR
fi;

# Here, we read and test the mandatory argument.
LAYER_NAME=""
if [ "$1" == "" ];
then
	echo $DATE" - The parameter LAYER_NAME is empty!!" >> $LOG
	exit
else
	LAYER_NAME=$1
fi;

AUTH="-u $GEOSERVER_USER:$GEOSERVER_PASS"

# Then we move the CSV file to a backup file using the "old" suffix.
if [ -f $TARGET_DIR/$LAYER_NAME.csv ];
then
	mv $TARGET_DIR/$LAYER_NAME.csv $TARGET_DIR/$LAYER_NAME-old.csv
fi;

# After that, we request the new data in CSV format and putting it in a new file.
curl $AUTH $GEOSERVER_BASE_URL'/'$GEOSERVER_BASE_PATH'/'$PROJECT_NAME'/wfs?SERVICE=WFS&REQUEST=GetFeature&VERSION=2.0.0&TYPENAME='$LAYER_NAME'&OUTPUTFORMAT=csv' \
-H 'Accept-Encoding: gzip, deflate, sdch' -H 'Accept-Language: pt-BR,pt;q=0.8,en-US;q=0.6,en;q=0.4' \
-H 'User-Agent: ShellScript(generateCSV)' \
-H 'Accept: */*' -H 'Referer: '$GEOSERVER_BASE_URL'/' -H 'X-Requested-With: curl' \
--compressed >> $TARGET_DIR/$LAYER_NAME-new.csv

# Finally, we test the result and remove the old file or, if the test has failed, we restore the old file as the current file.
if [ -f $TARGET_DIR/$LAYER_NAME-new.csv ] ;
then
	if grep -q $LAYER_NAME $TARGET_DIR/$LAYER_NAME-new.csv;
	then
		rm $TARGET_DIR/$LAYER_NAME-old.csv
		mv $TARGET_DIR/$LAYER_NAME-new.csv $TARGET_DIR/$LAYER_NAME.csv
		echo $DATE" - The file "$LAYER_NAME-old.csv" was removed and the new file "$LAYER_NAME" was created." >> $LOG
	else
		rm $TARGET_DIR/$LAYER_NAME-new.csv
		mv $TARGET_DIR/$LAYER_NAME-old.csv $TARGET_DIR/$LAYER_NAME.csv
		echo $DATE" - The file "$LAYER_NAME-new.csv" was removed and the old file "$LAYER_NAME" was retrieved." >> $LOG
	fi;
else
	mv $TARGET_DIR/$LAYER_NAME-old.csv $TARGET_DIR/$LAYER_NAME.csv
	echo $DATE" - The file "$LAYER_NAME-old.csv" was retrieved." >> $LOG
fi;