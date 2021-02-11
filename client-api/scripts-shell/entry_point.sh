#!/bin/sh

succeeded=0
failed=0

url="$GEOSERVER_BASE_URL/$GEOSERVER_BASE_PATH/ows"
status="200"

export SCRIPTS_BASE_PATH='/usr/local/scripts-shell'

$SCRIPTS_BASE_PATH/http_status_code_test.sh $url --status $status --debug

case $? in
  0)
     succeeded=`expr $succeeded + 1`
     ;;
  *)
     failed=`expr $failed + 1`
     ;;
esac

if [ "$succeeded" -eq "1" ];
then
   export PROJECT_NAME=deter-amz
   # generate public JSON files
   export IS_PUBLIC_DATA=true
   $SCRIPTS_BASE_PATH/generateJSON.sh all_daily_d
   $SCRIPTS_BASE_PATH/generateJSON.sh daily_d
   $SCRIPTS_BASE_PATH/generateJSON.sh month_d
   $SCRIPTS_BASE_PATH/generateJSON.sh cloud_m_d
   # generate private JSON files
   export IS_PUBLIC_DATA=false
   $SCRIPTS_BASE_PATH/generateJSON.sh all_daily_auth_d
   $SCRIPTS_BASE_PATH/generateJSON.sh daily_auth_d
   $SCRIPTS_BASE_PATH/generateJSON.sh month_auth_d
   # generate shapefiles
   $SCRIPTS_BASE_PATH/generateSHP.sh
   $SCRIPTS_BASE_PATH/copyDegradations.sh

   export PROJECT_NAME=deter-cerrado
   # generate public JSON files
   export IS_PUBLIC_DATA=true
   $SCRIPTS_BASE_PATH/generateJSON.sh daily_d
   $SCRIPTS_BASE_PATH/generateJSON.sh month_d
   # generate private JSON files
   export IS_PUBLIC_DATA=false
   $SCRIPTS_BASE_PATH/generateJSON.sh daily_auth_d
   $SCRIPTS_BASE_PATH/generateJSON.sh month_auth_d
   # generate shapefiles
   $SCRIPTS_BASE_PATH/generateSHP.sh

   export PROJECT_NAME=deter-fm
   # generate private JSON files
   export IS_PUBLIC_DATA=false
   $SCRIPTS_BASE_PATH/generateJSON.sh daily_auth_d
   $SCRIPTS_BASE_PATH/generateJSON.sh month_auth_d
   # generate shapefiles
   $SCRIPTS_BASE_PATH/generateSHP.sh

   export PROJECT_NAME=deter-terrama-mt
   $SCRIPTS_BASE_PATH/generateTerramaSHP.sh
fi;