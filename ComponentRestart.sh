#!/bin/bash

source ./config

function checkActiveHostname(){
  hostlist=`curl -s -u $USER:$PASS -H 'X-Requested-By: ambari' http://$HOST/api/v1/clusters/$CLUSTER/services/$1/components/$2 2> /dev/null | grep '"host_name"' | awk '{print $3}'`

  for hostname in $hostlist
  do
    response=`curl -s -u $USER:$PASS -H 'X-Requested-By: ambari' http://$HOST/api/v1/clusters/$CLUSTER/hosts/${hostname//\"/}/host_components/$2 2>/dev/null | grep HAState`
    if [[ $response =~ 'active' ]]
    then
      activehost=${hostname//\"/}
    fi
  done
}

function maintenanceON(){
  curl -s -u $USER:$PASS -H 'X-Requested-By: ambari' -X PUT -d \
    '{"RequestInfo": {"context" :"Maintenance ON '"$1"' via REST"}, "Body": {"HostRoles": {"maintenance_state":"ON"}}}' \
    http://$HOST/api/v1/clusters/$CLUSTER/hosts/$1/host_components/$2
}

function maintenanceOFF(){
  curl -s -u $USER:$PASS -H 'X-Requested-By: ambari' -X PUT -d \
    '{"RequestInfo": {"context" :"Maintenance OFF '"$1"' via REST"}, "Body": {"HostRoles": {"maintenance_state":"OFF"}}}' \
    http://$HOST/api/v1/clusters/$CLUSTER/hosts/$1/host_components/$2
}

function start(){
  curl -s -u $USER:$PASS -H 'X-Requested-By: ambari' -X PUT -d \
    '{"RequestInfo": {"context" :"Start '"$2"' via REST"}, "Body": {"HostRoles": {"state": "STARTED","maintenance_state":"OFF"}}}' \
    http://$HOST/api/v1/clusters/$CLUSTER/hosts/$activehost/host_components/$2
  maintenanceON $activehost $2
  wait $activehost $2 "STARTED"
  maintenanceOFF $activehost $2
}

function stop(){
  checkActiveHostname $1 $2
  curl -s -u $USER:$PASS -H 'X-Requested-By: ambari' -X PUT -d \
    '{"RequestInfo": {"context" :"Stop '"$2"' via REST"}, "Body": {"HostRoles": {"state": "INSTALLED"}}}' \
    http://$HOST/api/v1/clusters/$CLUSTER/hosts/$activehost/host_components/$2
  maintenanceON $activehost $2
  wait $activehost $2 "INSTALLED"
}

function wait(){
  finished=0
  while [ $finished -ne 1 ]
  do
    maintenanceOFF $1 $2
    str=$(curl -s -u $USER:$PASS http://{$HOST}/api/v1/clusters/$CLUSTER/hosts/$1/host_components/$2)
    alt=$(curl -s -u $USER:$PASS http://{$HOST}/api/v1/clusters/$CLUSTER/services/$1/alerts?format=summary)

    maintenanceON $1 $2
    critical=`echo $alt | sed -e 's/.*CRITICAL" : { "count" : //' -e 's/,.*//'`
    ### unknown=`echo $str | sed -e 's/.*UNKNOWN" : //' -e 's/,.*//'`
    ###warning=`echo $alt | sed -e 's/.*WARNING" : { "count" : //' -e 's/,.*//'`

    if [ $2 == "INSTALLED" ]; then
      if [[ $str =~ "$3" ]]||[[ $str =~ "Service not found" ]]; then
        finished=1
      fi
    else
      ###if [[ $str =~ "$3" && $critical == '0' && $warning == '0' ]]||[[ $str =~ "Service not found" ]]; then
      if [[ $str =~ "$3" && $critical == '0' ]]||[[ $str =~ "Service not found" ]]; then
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