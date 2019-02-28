#!/bin/bash

month=`date -d "0 month ago" +%m`

hadoop dfs -rm -r -f -skipTrash /app-logs/hadoop/logs/*
hadoop dfs -rm -r -f -skipTrash /spark2-history/*
hadoop dfs -rm -r -f -skipTrash /ats/done/*
hadoop dfs -rm -r -f -skipTrash /mr-history/done/2019/${month}/*
hadoop dfs -rm -r -f -skipTrash /user/hive/warehouse/*.db/*/_SCRATCH0.*