#!/bin/bash
set -x
function CheckFlow() {
    # 循环60次，每次探测本机应用端口流量值是否为空，为空后 count +1 ，3次之后break
    loop=0   # 循环计数
    count=0  # 流量为0后的计数

    while [ $loop -lt 30 ]
    do
       date=`date +%Y%m%d%H%M%S`
       echo "a $loop $date"  >> ${leave_log}
       hostname=`hostname -i`
       received=`sudo timeout 2 ngrep HTTP -dany -n 10 dst host $hostname and dst port ${app_port} | awk 'END {print}' | awk '{print $1}'`
       echo "received: $received" >> ${leave_log}
    #   if [ "${received}s" == "s" ] || [[ "${received}" =~ ^# ]];then
       if [ "${received}s" == "s" ] || [[ "${received}" =~ ^# ]];then
          if [ ${loop} -gt 10 ];then
            echo ' no received '
            count=`expr $count + 1`
            echo "count: $count" >> ${leave_log}
            if [ "$count" == 2 ];then
              echo " count is 3"
              break
            fi
         fi
       fi
       sleep 2
       loop=`expr $loop + 1`
    done
}

app_port=$1
if [[ -z ${app_port} ]];then
    app_port="8888"
fi
local_host="`hostname --fqdn`"
local_ip=$(/usr/sbin/ip a | grep inet | awk '{print $2}' | grep /24 |awk -F '/' '{print $1}' | grep "^10."| head -n1)
consul_path=/opt/consul
consul_data=${consul_path}/data
consul_log_path=${consul_path}/logs
leave_log=${consul_log_path}/leave.log
agent_log=${consul_log_path}/agent.log
mkdir -p ${consul_log_path}

echo "consul.sh --- 01 consul leave start" > ${leave_log}
echo `date +%Y%m%d%H%M%S` >> ${leave_log}
${consul_path}/consul leave

nmap 127.0.0.1 -p ${app_port} | grep open
if [[ $? -eq 0 ]];then
    if [[ ${IS_CHECKFLOW} == "yes" ]];then
        CheckFlow
    fi
fi

nohup ${consul_path}/consul agent -data-dir=${consul_data} -node=${local_host} -datacenter=${DATACENTER} -bind=$local_ip -client=0.0.0.0 -ui > ${agent_log} 2>&1 &
sleep 1
