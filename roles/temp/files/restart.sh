#!/bin/bash
source /etc/profile

function checkConsulClient(){
    if [[ "${app_name}" =~ ^(duapp-openerp-service)$ ]];then
        echo "no need consul"
    else
        sh /opt/consul/start-consul-agent.sh ${app_port}
    fi
}

app_path="/opt/apps"
backup_path="/opt/backup"
app_name=$1
app_port=$2
if [[ -z ${app_name} ]];then
    echo "Usage: restart app_name , app_name list as follows:"
    ls -l ${app_path} | grep ".jar" | awk '{print $NF}' |awk -F '.jar' '{print $1}'
    exit
fi
if [[ -z ${app_port} ]];then
    app_port="8888"
fi
log_path=${app_path}/logs
pid_file=${app_path}/${app_name}.pid

mkdir -p ${backup_path}
mkdir -p ${log_path}
checkConsulClient

if [[ -f ${pid_file} ]];then
    kill -9 $(cat ${pid_file})
    rm -f ${pid_file}
fi

# log_path
logPath="-Dlogging.path=/logs"

# java_opt 此处需发布系统配合做优化
javaopt="-XX:+UseG1GC -Xmx6g -XX:MaxGCPauseMillis=200 -XX:G1HeapRegionSize=16m -DLOG_HOME=/logs -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/opt/apps/errorDump.hprof -Dmanagement.health.defaults.enabled=false"
if [[ "${app_name}" =~ ^(duapp-push-service)$ ]]
then
    javaopt="-XX:+UseG1GC -Xmx12g -XX:MaxGCPauseMillis=200 -XX:G1HeapRegionSize=16m -DLOG_HOME=/logs"
fi

if [[ "${app_name}" =~ ^(duapp-gateway-service)$ ]]
then
    javaopt="-XX:+UseG1GC -Xmx12g -XX:MaxGCPauseMillis=200 -XX:G1HeapRegionSize=16m  -Dcsp.sentinel.app.type=1 "
fi

if [[ "${app_name}" =~ ^(duapp-cloud-gateway-service)$ ]]
then
    javaopt="-XX:+UseG1GC -Xmx12g -XX:MaxGCPauseMillis=200 -XX:G1HeapRegionSize=16m  -Dcsp.sentinel.app.type=1 "
fi

if [[ "${app_name}" =~ ^(duapp-openerp-service)$ ]];then
    echo java -jar ${pinpoint} ${app_path}/${app_name}.jar --spring.profiles.active=${PROFILES_ACTIVE}
    nohup java -jar ${pinpoint} ${app_path}/${app_name}.jar --spring.profiles.active=${PROFILES_ACTIVE} >> ${log_path}/start.log 2>&1 & echo $! > ${pid_file}
else
    echo java -Dserver.port=${app_port} -Dspring.profiles.active=${APOLLO_PROFILES_ACTIVE} -jar -Dapollo.meta=${APOLLO_META} -Dlogging.path=/logs ${javaopt} -Dlog_kafka_ip=${KAFKA_CLUSTER} ${pinpoint} ${app_path}/${app_name}.jar
    nohup java -Dserver.port=${app_port} -Dspring.profiles.active=${APOLLO_PROFILES_ACTIVE} -jar -Dapollo.meta=${APOLLO_META} -Dlogging.path=/logs ${javaopt} -Dlog_kafka_ip=${KAFKA_CLUSTER} ${pinpoint} ${app_path}/${app_name}.jar >> ${log_path}/start.log 2>&1 & echo $! > ${pid_file}
fi

/opt/consul/consul join ${CONSUL_SERVERS}
