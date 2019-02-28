#!/bin/bash

source ./config

crumb=$(curl -s -u $JUSER:$JPASS http://$JENKINSURL/crumbIssuer/api/json)
JKEY=`echo $crumb | sed -e 's/.*crumb":"//' -e 's/".*//'`

function start(){
  nextbuildnumber $1
  checknum=$?
  curl -s -u $JUSER:$JPASS -X POST \
    http://$JENKINSURL/job/Spark-XX/job/$1/buildWithParameters?Jenkins-Crumb=$JKEY&ACTION=RESTART
  wait $1 "SUCCESS" $checknum
}

function stop(){
  nextbuildnumber $1
  checknum=$?
  curl -s -u $JUSER:$JPASS  -X POST \
    http://$JENKINSURL/job/Spark-XX/job/$1/buildWithParameters?Jenkins-Crumb=$JKEY&ACTION=STOP
  wait $1 "SUCCESS" $checknum
}

function nextbuildnumber(){
  nextbuildnumberurl=$(curl -s -u $JUSER:$JPASS http://{$JENKINSURL}/job/Spark-XX/job/$1/api/json)
  buildnumber=`echo $nextbuildnumberurl | sed -e 's/.*nextBuildNumber"://' -e 's/,.*//'`
  
  return $buildnumber
}

function wait(){
  finished=0
  while [ $finished -ne 2 ]
  do
    str=$(curl -s -u $JUSER:$JPASS http://jenkins.wsmfin.com:8080/job/Spark-XX/job/$1/$3/api/json)
    if [[ $str == *"$2"* ]]
    then
      finished=2
    fi
    echo $str | sed -e 's/.*result"://' -e 's/,.*//'
    sleep 3
  done
}

case $1 in
  start) start $2
  ;;
  stop) stop $2
  ;;
  *) echo "start [JobName] or stop [JobName]"
esac
