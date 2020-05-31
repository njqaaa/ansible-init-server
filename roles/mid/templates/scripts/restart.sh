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
[root@dw-csprd-bidding-bidding_interfaces-002 s-user]# ^C
[root@dw-csprd-bidding-bidding_interfaces-002 s-user]# cat /opt/apps/restart.sh
#!/bin/bash
source /etc/profile

function checkConsulClient(){
    if [[ "${app_name}" =~ ^(duapp-openerp-service)$ ]];then
        echo "no need consul"
    else
        sh /opt/consul/start-consul-agent.sh ${app_port}
    fi
}

function getEnvConfig(){
    if [[ $(hostname) =~ "pub-resource" || ! $(hostname) =~ "dw-" ]];then
        echo "请确保阿里云InstanceName符合规范，并使用root用户执行 /etc/init.d/system-init.sh"
        exit
    fi
    env=$(hostname | awk -F "-" '{print $2}')
    for config_file in ${CONFIG_FILES}
    do
        echo "download "${config_file}" start........"
        temp_file="/tmp/"$(date +%N)
        wget ${CONFIG_URL}/${env}/${config_file} -O ${temp_file}
        if [[ $? -eq 0 ]] ;then
            mv -f ${temp_file} ${CONFIG_PATH}/${config_file}
#            cat ${CONFIG_PATH}/${config_file}
            source ${CONFIG_PATH}/${config_file}
        else
            echo "资源未找到："${CONFIG_URL}/${env}/${config_file}
            echo "请联系运维"
            exit 1
        fi
        echo "download "${config_file}" end........"
        echo
    done
}

if [[ $(whoami) == "root" ]];then
    bash /etc/init.d/system-init.sh
    chown ops:ops -R /opt
    chown ops:ops -R /logs
    chown ops:ops -R /etc/profile.d
fi

basepath=$(cd $(dirname $0); pwd)
app_path="/opt/apps"
backup_path="/opt/backup"
app_name=$1
app_port=$2
if [[ -z ${app_name} ]];then
    echo "请传入应用名参数"
    ls -l ${app_path} | grep ".jar" | awk '{print $NF}' |awk -F '.jar' '{print $1}'
    exit
fi
if [[ -z ${app_port} ]];then
    app_port="8888"
fi

getEnvConfig

if [[ ${EXEC_USER} == "ops" ]];then
    if [[ $(whoami) != "ops" ]];then
        echo "当前用户为 $(whoami) , 请使用 ops 用户执行"
        exit 1
    fi
fi

jar_name=$(find ${app_path} -name ${app_name}.jar)
if [[ -z ${jar_name} ]];then
    echo "没找到jar包"
    exit 1
fi
echo "重启命令："${basepath}/$(basename $0) ${app_name} ${app_port}
echo ${basepath}/$(basename $0) ${app_name} ${app_port} > ${basepath}/restart-${app_name}.sh

log_path="/logs"
pid_file=${app_path}/${app_name}.pid

mkdir -p ${backup_path}
mkdir -p ${log_path}
checkConsulClient

if [[ -f ${pid_file} ]];then
    kill -9 $(cat ${pid_file})
    rm -f ${pid_file}
fi

# log_path
logPath="-Dlogging.path=${log_path}"

if [[ "${app_name}" =~ ^(duapp-openerp-service)$ ]];then
    echo java -jar  ${jar_name} --spring.profiles.active=${PROFILES_ACTIVE}
    nohup java -jar  ${jar_name} --spring.profiles.active=${PROFILES_ACTIVE} > /dev/null 2>&1 & echo $! > ${pid_file}
else
    echo java -Dserver.port=${app_port} -Dspring.profiles.active=${APOLLO_PROFILES_ACTIVE} -jar -Dapollo.meta=${APOLLO_META} -Dlogging.path=${log_path} ${javaopt} -Dlog_kafka_ip=${KAFKA_CLUSTER}  ${jar_name}
    nohup java -Dserver.port=${app_port} -Dspring.profiles.active=${APOLLO_PROFILES_ACTIVE} -jar -Dapollo.meta=${APOLLO_META} -Dlogging.path=${log_path} ${javaopt} -Dlog_kafka_ip=${KAFKA_CLUSTER}  ${jar_name} > /dev/null 2>&1 & echo $! > ${pid_file}
fi

/opt/consul/consul join ${CONSUL_SERVERS}
