#!/bin/bash
function createEtchosts() {
    echo 127.0.0.1 localhost localhost.localdomain > ${hosts_file}
    ansible_host=$(cat ${base_path}/hosts | grep ansible_host | grep -v '^#' | awk '{print $2,$1}' | awk -F '=' '{print $2}')
    etc_hosts=$(echo "${ansible_host}" | sort -uk2)
    echo "${etc_hosts}" >> ${hosts_file}
    echo "k8s集群hosts文件内容如下："
    cat ${hosts_file}
}

function pushSsh() {
    ssh_key_file=$(ls ~/.ssh/ | grep pub | head -n1)
    if [[ ! ${ssh_key_file} ]];then
        ssh-keygen
    fi
    ssh_key_file=$(ls ~/.ssh/ | grep pub | head -n1)
    remote_ips=$(cat ${hosts_file} | awk '{print $1}' | grep -v localhost )
    echo "准备为远程服务器加ssh权限"
    for remote_ip in ${remote_ips}
    do
        ssh-copy-id -i ~/.ssh/${ssh_key_file} root@${remote_ip}
    done
}

function checkSsh() {
    which ansible
    if [[ $? -ne 0 ]];then
        echo "本机需要预先安装ansible"
        exit
    fi
    echo "验证ssh状态"
    ansible all -i ${base_path}/hosts -m shell -a 'whoami'
    if [[ $? -ne 0 ]];then
        echo "部分服务器ssh失败，请验证！"
        exit
    fi
}

base_path=$(cd `dirname $0`; pwd)
hosts_file=${base_path}/etchosts
k8s_version=$(cat hosts |grep K8S_VER |awk -F '"' '{print $2}')

if [[ ${base_path} != "/etc/ansible" ]];then
    echo "请mv本仓库至/etc/，并重命名为ansible"
    exit
fi

createEtchosts
pushSsh
checkSsh
