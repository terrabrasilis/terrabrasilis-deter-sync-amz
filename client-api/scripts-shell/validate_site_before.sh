#!/bin/sh

succeeded=0
failed=0

url="$GEOSERVER_BASE_URL/$GEOSERVER_BASE_PATH"
status="200"

/usr/local/scripts-shell/http_status_code_test.sh $url --status $status --debug

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
    #/usr/local/scripts-shell/pull_json.sh deter_all_d
    /usr/local/scripts-shell/pull_json.sh deter_public_d
    /usr/local/scripts-shell/pull_json.sh deter_month_d
    /usr/local/scripts-shell/generateSHP.sh

    export PROJECT_NAME=deter-cerrado
    /usr/local/scripts-shell/pull_json.sh deter_cerrado_all_d
    #/usr/local/scripts-shell/pull_json.sh deter_cerrado_public_d
    /usr/local/scripts-shell/pull_json.sh deter_cerrado_month_d
    /usr/local/scripts-shell/generateSHP.sh

fi;