#!/bin/bash
source offlines/version
set -e

NodeName=ok8s

function preflight() {
   echo "prefilt"
}

function initK8s() {
    kubeadm init --node-name=${NodeName} --v=7 --pod-network-cidr=10.244.0.0/16 --kubernetes-version=${k8sVersion}

}

function enableServices(){
    #/usr/lib/systemd/system
    
}

function logI(){
    echo -e "[INFO] \033[33m  ${FUNCNAME[1]}\033[0m : $1"
}
function flushIptables() {
    logI "starting"
    iptables -F && iptables -X &&
        iptables -F -t nat && iptables -X -t nat &&
        iptables -F -t raw && iptables -X -t raw &&
        iptables -F -t mangle && iptables -X -t mangle

}

function dockerService() {

}

function kubeletService() {

}


$@
