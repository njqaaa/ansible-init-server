#!/bin/bash
local_ip=$(/sbin/ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|head -n 1)
echo $local_ip
url="http://prd-ops.dewus.cn:7000/getInstanceName/${local_ip}"
ali_hostname=$(curl -s ${url})
echo $ali_hostname
hostnamectl set-hostname ${ali_hostname}
