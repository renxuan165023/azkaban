#!/bin/bash

source ./config

function maintenanceON(){
  curl -s -u $USER:$PASS -H 'X-Requested-By: ambari' -X PUT -d \
    '{"RequestInfo": {"context" :"Maintenance ON '"$1"' via REST"}, "Body": {"ServiceInfo": {"maintenance_state":"ON"}}}' \
    http://$HOST/api/v1/clusters/$CLUSTER/services/$1
}

function maintenanceOFF(){
  curl -s -u $USER:$PASS -H 'X-Requested-By: ambari' -X PUT -d \
    '{"RequestInfo": {"context" :"Maintenance OFF '"$1"' via REST"}, "Body": {"ServiceInfo": {"maintenance_state":"OFF"}}}' \
    http://$HOST/api/v1/clusters/$CLUSTER/services/$1
}

function start(){
  curl -s -u $USER:$PASS -H 'X-Requested-By: ambari' -X PUT -d \
    '{"RequestInfo": {"context" :"Start '"$1"' via REST"}, "Body": {"ServiceInfo": {"state": "STARTED","maintenance_state":"OFF"}}}' \
    http://$HOST/api/v1/clusters/$CLUSTER/services/$1
  maintenanceON $1
  wait $1 "STARTED"
  maintenanceOFF $1
}

function stop(){
  curl -s -u $USER:$PASS -H 'X-Requested-By: ambari' -X PUT -d \
    '{"RequestInfo": {"context" :"Stop '"$1"' via REST"}, "Body": {"ServiceInfo": {"state": "INSTALLED"}}}' \
    http://$HOST/api/v1/clusters/$CLUSTER/services/$1
  maintenanceON $1
  wait $1 "INSTALLED"
}

function wait(){
  finished=0
  while [ $finished -ne 1 ]
  do
    maintenanceOFF $1
    str=$(curl -s -u $USER:$PASS http://{$HOST}/api/v1/clusters/$CLUSTER/services/$1)
    alt=$(curl -s -u $USER:$PASS http://{$HOST}/api/v1/clusters/$CLUSTER/services/$1/alerts?format=summary)
    echo $alt
    maintenanceON $1
    critical=`echo $alt | sed -e 's/.*CRITICAL" : { "count" : //' -e 's/,.*//'`
    ### unknown=`echo $str | sed -e 's/.*UNKNOWN" : //' -e 's/,.*//'`
    warning=`echo $alt | sed -e 's/.*WARNING" : { "count" : //' -e 's/,.*//'`
    echo $2
    if [ $2 == "INSTALLED" ]; then
      if [[ $str =~ "$2" ]]||[[ $str =~ "Service not found" ]]; then
        finished=1
      fi
    else
      if [[ $str =~ "$2" && $critical == '0' && $warning == '0' ]]||[[ $str =~ "Service not found" ]]; then
        finished=1
      fi
    fi
    echo $str | sed -e 's/.*state" : "//' -e 's/".*//'
    sleep 3
  done
}

case $1 in
  start) start $2 $3
  ;;
  stop) stop $2 $3
  ;;
  restart) stop $2 $3
           start $2 $3
  ;;
  *) echo "ServiceRestart.sh [start|stop|restart] [serviceName] [componentName]"
esac

