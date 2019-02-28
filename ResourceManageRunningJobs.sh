#!/bin/bash

i=1

while [[ $i != 0 ]]
do
  sleep 5
  now=`date +%H%M`

  if [[ $now -ge '0845' ]]
  then
    echo "==== 超出可执行时间! ===="
    exit 1
  fi

  response=`curl http://pa-ops-nn01:8088/ws/v1/cluster/metrics`

  if [[ $response =~ 'standby' ]]
  then
    response=`curl http://pa-ops-nn02:8088/ws/v1/cluster/metrics`
  fi

  i=`echo $response | sed -e 's/.*appsRunning"://' -e 's/,.*//'`

  echo $response
done
