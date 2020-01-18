#!/bin/bash
# 初始化k8s集群
base_path=$(cd `dirname $0`; pwd)
source ${base_path}/prepare.sh

function pullImage() {
    docker ps
    if [[ $? -ne 0 ]];then
        echo "本机需要预先安装docker，并启动！！"
        exit
    fi
    echo "正在下载集群所需二进制文件"
    docker run --rm --name k8s-${k8s_version} -d njqaaa/k8s-package:${k8s_version} sleep 10
    docker cp $(docker ps |grep k8s-${k8s_version} |awk '{print $1}'):/tmp/bin/ ${base_path}
    cd ${base_path}/bin/
    find . -type f | xargs chmod +x
    cd -
}

function checkAlive() {
    # check 服务器是否启动
    echo check server status  and waiting...
    until ansible all -u root -m shell -a 'w' 2>&1; do sleep 5; printf "."; done
}

function checkIfOk(){
    if [[ $? -ne 0 ]];then
        echo "error"
        exit 1
    fi
}
function installK8s(){
    # 如内核版本为3.1*，则会升级内核，并重启所有节点
    ansible-playbook 01.prepare.yml
    checkAlive
    ansible-playbook 02.etcd.yml
    checkIfOk
    ansible-playbook 03.docker.yml
    checkIfOk
    ansible-playbook 04.kube-master.yml
    checkIfOk
    ansible-playbook 05.kube-node.yml
    checkIfOk
    ansible-playbook 06.network.yml
    checkIfOk
    ansible-playbook 07.cluster-addon.yml
    checkIfOk
    #ansible-playbook 12.helm.yml
    #checkIfOk
}

pullImage

installK8s
