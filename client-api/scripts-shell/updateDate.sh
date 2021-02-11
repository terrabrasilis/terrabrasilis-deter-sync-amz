#!/bin/bash

# Here, we read and test the mandatory argument.
TARGET_FILE=""
if [ "$1" == "" ];
then
	# The parameter TARGET_FILE is empty. skipping
	exit
else
	TARGET_FILE=$1
fi;

if $IS_PUBLIC_DATA ;
then
  LAYER_NAME="updated_date"
else
  LAYER_NAME="last_date"
fi;

JSON_RESPONSE=$(curl -s "$GEOSERVER_BASE_URL/$GEOSERVER_BASE_PATH/$PROJECT_NAME/wfs?SERVICE=WFS&REQUEST=GetFeature&VERSION=2.0.0&TYPENAME=$LAYER_NAME&OUTPUTFORMAT=application%2Fjson")
UPDATED_DATE=$(echo $JSON_RESPONSE |grep -oP '(?<="updated_date":")[^"]*')

if [[ $UPDATED_DATE =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] && date -d "$UPDATED_DATE" >/dev/null 2>&1 ;
then
  # remove last char from file
  truncate -s-1 $TARGET_FILE
  # put the updated_date attribute and reference value
  echo ",\"updated_date\":\"$UPDATED_DATE\"}" >> $TARGET_FILE
fi;