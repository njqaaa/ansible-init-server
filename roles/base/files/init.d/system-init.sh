#!/bin/bash
region=$(curl -s http://100.100.100.200/latest/meta-data/region-id)
while true
do
    local_ip=$(/sbin/ip a | grep inet | awk '{print $2}' | grep /24 |awk -F '/' '{print $1}' | grep "^10."| head -n1)
    if [[ ${local_ip} =~ "." ]];then
         echo ip ${local_ip}
         break
    fi
    sleep 1
done
echo $local_ip
url="http://prd-ops.dewus.cn:7999/getInstanceName/${region}/${local_ip}"
ali_hostname=$(curl -s ${url} )
if [[ $? -eq 0 ]];then
    echo $ali_hostname
    cat /etc/*release | grep 'CENTOS_MANTISBT_PROJECT_VERSION="7"'
    if [[ $? -eq 0 ]];then
        hostnamectl set-hostname ${ali_hostname}
    else
        hostname ${ali_hostname}
    fi
fi
