#!/bin/bash
# set env vars to use inside script
source /etc/environment
DT=$(date +"%Y-%m-%d_%H_%M_%S")

/usr/local/scripts-shell/entry_point.sh >> /logs/exec_daily_${DT}.log 2>&1
