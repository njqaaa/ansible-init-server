#!/bin/bash
# @Author  : Zhao Jun
# @E-mail  : zhaojun@theduapp.com
# @File    : DeleteHistory.sh
# @Software: Sublime Text
# @Time    : 2019/10/10 15:39
# @Desc    : 删除发布平台的历史包
# 查找10天前创建的目录的时间戳, 删除目录
# 注意不能直接用find 的ctime来查找，因为当前的备份目录中有超过2个月前的未改动文件

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


