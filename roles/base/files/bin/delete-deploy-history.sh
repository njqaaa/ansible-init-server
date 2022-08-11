#!/bin/bash

oldDate=$(date -d "-10 days" "+%Y-%m-%d")
timeStamp=`date -d ${oldDate} +%s`
bak_path="/opt/deploy/bak/"
if [[ ! -d ${bak_path} ]];then
    exit 1
fi
cd ${bak_path}
for folder in $(ls -d */)
do
   [ `date +%s -r ${folder}` -lt $timeStamp ] && rm -rf  $folder
done

code_path="/opt/deploy/code/"
if [[ ! -d ${code_path} ]];then
    exit 1
fi
cd ${code_path}
for file in $(ls ./)
do
   [ `date +%s -r ${file}` -lt $timeStamp ] && rm -rf  $file
done


