## ok8s
纯离线安装K8s单机学习环境。 测试环境为Centos7.6      
Docker: `19.03`   
K8s: `1.16.3`   
Flannel: `0.11.0-amd64`   
Dashboard: `2.0.0-beta8`    
Helm: `3.0`   
Multus: `3.4`     


## 机制

1. K8s所需基本组件都有纯二进制文件(没有任何信赖).
2. 提前下好所有镜像。

>所有文件我都提前打包到wxdlong/ok8s:v1.16.3

## 基本流程

1. 下载离线包
2. 配置docker, kubelet服务。   
3. kubeadm初始化集群。   
4. 安装flannel插件。    
5. 安装dashboard插件。   
6. 安装multus插件。    
7. 安装helm.   

## 下载离线包
离线包包括docker相关二进制文件(ctr, docker-init, containerd, docker, docker-proxy, runccontainerd-shim, dockerd )    
K8s二进制文件(kubeadm, kubelet, kubectl)    
K8s镜像：  
```text   
k8s.gcr.io/kube-apiserver:v1.16.3    
k8s.gcr.io/kube-controller-manager:v1.16.3    
k8s.gcr.io/kube-scheduler:v1.16.3   
k8s.gcr.io/kube-proxy:v1.16.3   
k8s.gcr.io/pause:3.1   
k8s.gcr.io/etcd:3.3.10   
k8s.gcr.io/coredns:1.3.1   
kubernetesui/dashboard:v2.0.0-beta8     
kubernetesui/metrics-scraper:v1.0.1     
quay.io/coreos/flannel:v0.11.0-amd64     
nfvpe/multus:v3.4   
nginx:1.16.0  
```

1. 如果己经有docker. 则用docker自动下载所有离线数据
`docker run --rm -v ${PWD}/download:/data wxdlong/ok8s:v1.16.3`

2. 否则，运行./ok8s.sh -D. (需要运行在linux机器上)

3. Copy所有离线包到目标机器 /opt/ok8s
    ```bash
    [root@wxd ok8s]# ls -lth
    total 1.6G
    -rwxr-xr-x. 1 root root 1.6G Nov 29 22:56 k8sImages.tar.gz
    drwxr-xr-x. 2 root root  262 Nov 29 22:35 bin
    ```

## 配置环境变量
将k8s二进制目录`/opt/ok8s`加入到环境变量中.
```bash
cat <<EOF > /etc/profile.d/ok8s.sh 
#set k8s environment
K8S=/opt/ok8s
PATH=${K8S}/bin:${PATH}
export PATH
EOF

chmod 644 /etc/profile.d/ok8s.sh
source /etc/profile
```


## 配置dockere服务

1. 编写systemd service.
```bash
cat <<EOF > /usr/lib/systemd/system/docker.service
[Unit]
Description=Docker Application Container Engine
Documentation=http://docs.docker.io
[Service]
Environment="PATH=/opt/ok8s/bin:/bin:/sbin:/usr/bin:/usr/sbin"
ExecStart=/opt/ok8s/bin/dockerd
ExecStartPost=/sbin/iptables -I FORWARD -s 0.0.0.0/0 -j ACCEPT
ExecReload=/bin/kill -s HUP \$MAINPID
Restart=on-failure
RestartSec=5
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
Delegate=yes
KillMode=process
[Install]
WantedBy=multi-user.target
EOF
```

2. 启用docker服务. `systemctl enable docker && systemctl start docker`

3. 查看docker运行状态
```bash
[root@wxd system]# docker version
Client: Docker Engine - Community
 Version:           19.03.5
 API version:       1.40
 Go version:        go1.12.12
 Git commit:        633a0ea838
 Built:             Wed Nov 13 07:22:05 2019
 OS/Arch:           linux/amd64
 Experimental:      false

Server: Docker Engine - Community
 Engine:
  Version:          19.03.5
  API version:      1.40 (minimum version 1.12)
  Go version:       go1.12.12
  Git commit:       633a0ea838
  Built:            Wed Nov 13 07:28:45 2019
  OS/Arch:          linux/amd64
  Experimental:     false
 containerd:
  Version:          v1.2.10
  GitCommit:        b34a5c8af56e510852c35414db4c1f4fa6172339
 runc:
  Version:          1.0.0-rc8+dev
  GitCommit:        3e425f80a8c931f88e6d94a8c831b9d5aa481657
 docker-init:
  Version:          0.18.0
  GitCommit:        fec3683
```
5. 加载k8s离线镜像 `docker load -i k8sImages.tar.gz`
```bash
[root@wxd ok8s]# docker load -i k8sImages.tar.gz 
fe9a8b4f1dcc: Loading layer [==================================================>]  43.87MB/43.87MB
15c9248be8a9: Loading layer [==================================================>]  3.403MB/3.403MB
32109c7fe502: Loading layer [==================================================>]  40.65MB/40.65MB
Loaded image: k8s.gcr.io/kube-proxy:v1.16.3
1978d856a73d: Loading layer [==================================================>]  44.96MB/44.96MB
Loaded image: k8s.gcr.io/kube-scheduler:v1.16.3
```
>具体k8s需要用到哪些镜像。用这个命令查看
```bash
[root@wxd ~]# kubeadm config images list
W1214 03:04:38.392674   15188 version.go:101] could not fetch a Kubernetes version from the internet: unable to get URL "https://dl.k8s.io/release/stable-1.txt": Get https://dl.k8s.io/release/stable-1.txt: net/http: request canceled while waiting for connection (Client.Timeout exceeded while awaiting headers)
W1214 03:04:38.393093   15188 version.go:102] falling back to the local client version: v1.16.3
k8s.gcr.io/kube-apiserver:v1.16.3
k8s.gcr.io/kube-controller-manager:v1.16.3
k8s.gcr.io/kube-scheduler:v1.16.3
k8s.gcr.io/kube-proxy:v1.16.3
k8s.gcr.io/pause:3.1
k8s.gcr.io/etcd:3.3.15-0
k8s.gcr.io/coredns:1.6.2
```

## 安装kubelet服务
```bash
cat <<EOF >  /usr/lib/systemd/system/kubelet.service
[Unit]
Description=Kubernetes Kubelet
Documentation=https://github.com/GoogleCloudPlatform/kubernetes

[Service]
WorkingDirectory=/var/lib/kubelet
ExecStart=/opt/ok8s/bin/kubelet \
  --config=/var/lib/kubelet/config.yaml \
  --cni-bin-dir=/opt/ok8s/bin \
  --cni-conf-dir=/etc/cni/net.d \
  --kubeconfig=/etc/kubernetes/kubelet.conf \
  --network-plugin=cni \
  --pod-infra-container-image=k8s.gcr.io/pause:3.1 \
  --root-dir=/var/lib/kubelet
  --v=5
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

```

2. 启用kubelet服务. `systemctl enable kubelet`, 在执行kubeadm初始化cluster之前kubelet服务是起不来的。

## Kubeadm初始化集群

`kubeadm init --v=7 --pod-network-cidr=10.244.0.0/16 --kubernetes-version=v1.16.3`  
--v=7 超详细日志。看到kubeadm执行的整个流程。   
--pod-network-cidr=10.244.0.0/16  flannel网络插件的参数   
--kubernetes-version=v1.16.3 指定k8s镜像版本。 
>接下来例出可能出现的错误。一个一个解决 

1. CPU数量必须大于1. 配置虚拟机CPU数量后重启！
    ```
    [preflight] Some fatal errors occurred:
        [ERROR NumCPU]: the number of available CPUs 1 is less than the required 2
    ```
2. 不支持swap， 禁用。  `swapoff -a && sysctl -w vm.swappiness=0`
    ```
    [preflight] Some fatal errors occurred:
        [ERROR Swap]: running with swap on is not supported. Please disable swap
    ```
    顺便写入到文件。注释`/etc/fstab`的swap开机加载
    ```bash
    [root@wxd ~]# cat /etc/fstab 
    #
    # /etc/fstab
    # Created by anaconda on Fri Nov 29 22:05:35 2019
    #
    # Accessible filesystems, by reference, are maintained under '/dev/disk'
    # See man pages fstab(5), findfs(8), mount(8) and/or blkid(8) for more info
    #
    /dev/mapper/centos-root /                       xfs     defaults        0 0
    UUID=d5aaeea4-2629-4b48-b7d8-5853598db629 /boot                   xfs     defaults        0 0
    /dev/mapper/centos-home /home                   xfs     defaults        0 0
    ##/dev/mapper/centos-swap swap                    swap    defaults        0 0
    ```
3. 

cat <<EOF > /etc/sysctl.d/98-ok8s.conf
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-arptables = 1
EOF

sysctl -p /etc/sysctl.d/98-ok8s.conf
    ```bash
    [preflight] Some fatal errors occurred:
        [ERROR FileContent--proc-sys-net-bridge-bridge-nf-call-iptables]: /proc/sys/net/bridge/bridge-nf-call-iptables contents are not set to 1
    ```



## 参考
[Bootstrapping clusters with kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/)     
