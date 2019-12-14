#!/bin/bash
set -e
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source ${DIR}/version

DOCKER_URL=https://download.docker.com/linux/static/stable/x86_64/docker-${dockerVersion}.tgz
KUBECTL_URL=https://storage.googleapis.com/kubernetes-release/release/${k8sVersion}/bin/linux/amd64/kubectl
KUBEADM_URL=https://storage.googleapis.com/kubernetes-release/release/${k8sVersion}/bin/linux/amd64/kubeadm
KUBELET_URL=https://storage.googleapis.com/kubernetes-release/release/${k8sVersion}/bin/linux/amd64/kubelet
CNI_URL=https://github.com/containernetworking/plugins/releases/download/${cniVersion}/cni-plugins-linux-amd64-${cniVersion}.tgz
HELM_URL=https://get.helm.sh/helm-${helmVersion}-linux-amd64.tar.gz
TEMP_FILES=/tmp/k8s_offline.$$

function init() {
    echo "Download path: ${DIR}"
    rm -rf ${TEMP_FILES} | echo "Areadly clean temp download files!"
    mkdir -p ${DIR}/download/{bin,cni}
    mkdir -p ${TEMP_FILES}/{bin,cni}
}

function downDocker() {
    echo "Download Docker from ${DOCKER_URL}"
    curl -L ${DOCKER_URL} | tar -zx -C ${TEMP_FILES}/bin
}

function downK8sBins() {
    downDocker

    cd ${TEMP_FILES}/bin
    echo "Download Helm from ${HELM_URL}"
    curl -L ${HELM_URL} | tar -zx -C ${TEMP_FILES}

    echo "Download CNI from ${CNI_URL}"
    curl -L ${CNI_URL} | tar -zx -C ${TEMP_FILES}/cni

    echo "Download Kubectl from ${KUBECTL_URL}"
    curl -LO ${KUBECTL_URL}

    echo "Download Kubeadm from ${KUBEADM_URL}"
    curl -LO ${KUBEADM_URL}

    echo "Download Kubelet from ${KUBELET_URL}"
    curl -LO ${KUBELET_URL}

    echo "Download socat"
    curl -LO https://raw.githubusercontent.com/andrew-d/static-binaries/master/binaries/linux/x86_64/socat

    ls -lth  ${TEMP_FILES}
    find ${TEMP_FILES}/bin -type f | xargs -I {} mv {} ${DIR}/download/bin
    find ${TEMP_FILES}/cni -type f | xargs -I {} mv {} ${DIR}/download/cni

}

function downK8sImages() {
    echo "Download k8s:${k8sVersion} iamges"
    images=""
    for image in $(cat ${DIR}/images); do
        echo "docker pull ${image}"
        docker pull ${image}
        images="${image} ${images}"
    done

    echo "docker save -o k8sImages.tar.gz ${images}"
    docker save -o ${DIR}/download/k8sImages.tar.gz ${images}
}

function down2Docker() {
    echo -e "[INFO] \033[33mdown2Docker\033[0m : starting"
    init
    downDocker
    downK8sBins
    downK8sImages
    
    tar -czvf ${DIR}/ok8s.tar.gz -C ${DIR}/download .
    ls -lth ${DIR}/ok8s.tar.gz
}

function usage(){
    cat <<EOF
./download.sh -D
EOF
}

function main() {
    # check if use bash shell
    readlink /proc/$$/exe | grep -q "dash" && {
        echo "[ERROR] you should use bash shell, not sh"
        exit 1
    }

    ACTION=""
    while getopts "CD" OPTION; do
        case "$OPTION" in
        C)
            ACTION="clean_container"
            ;;
        D)
            ACTION="down2Docker"
            ;;
        ?)
            usage
            exit 1
            ;;
        esac
    done

    [[ "$ACTION" == "" ]] && {
        echo "[ERROR] illegal option"
        usage
        exit 1
    }

    echo -e "[INFO] \033[33mAction begin\033[0m : $ACTION"
    ${ACTION}
    echo -e "[INFO] \033[32mAction successed\033[0m : $ACTION"
}

main "$@"
