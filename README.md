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
  --cni-bin-dir=/opt/ok8s/cni \
  --cni-conf-dir=/etc/cni/net.d \
  --hostname-override=ok8s \
  --kubeconfig=/etc/kubernetes/kubelet.kubeconfig \
  --network-plugin=cni \
  --pod-infra-container-image=k8s.gcr.io/pause:3.1 \
  --root-dir=/var/lib/kubelet
  --v=2
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
3. iptables设置。
    ```bash
    cat <<EOF > /etc/sysctl.d/98-ok8s.conf
    net.ipv4.ip_forward = 1
    net.bridge.bridge-nf-call-iptables = 1
    net.bridge.bridge-nf-call-ip6tables = 1
    net.bridge.bridge-nf-call-arptables = 1
    EOF

    sysctl -p /etc/sysctl.d/98-ok8s.conf
    ```
    ```bash
    [preflight] Some fatal errors occurred:
        [ERROR FileContent--proc-sys-net-bridge-bridge-nf-call-iptables]: /proc/sys/net/bridge/bridge-nf-call-iptables contents are not set to 1
    ```
4. `write /proc/self/attr/keycreate: permission denied`,   
这个时候需要禁用selinux了。   
`setenforce 0  && echo "SELINUX=disabled" > /etc/selinux/config`
```bash
CreatePodSandbox for pod "etcd-wxd.long_kube-system(e35cacb5899446e3bff45112961b61a1)" failed: rpc error: code = Unknown desc = failed to start sandbox container for pod "etcd-wxd.long": Error response from daemon: OCI runtime create failed: container_linux.go:346: starting container process caused "process_linux.go:449: container init caused \"write /proc/self/attr/keycreate: permission denied\"": unknown

``` 
5. 好，总算继续了。静待佳音。你可以持续关注日志/var/log/message和监控kubelet状态。kubeadm会查检安装环境，创建一系列配置文件，启动kubelet.

6. 当你看到下面的输出，那么就恭喜安装成功。按照提示copy Kube配置文件到home目录下就可以用kubeclt命令了。
```bash
Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 10.0.2.15:6443 --token 9uisa2.aaj0833t08vvbpwe \
    --discovery-token-ca-cert-hash sha256:3f6743345c9bbd953500cfc32622aab388ffb255e0e9c7d41ac7e5948148adc0 

```

7. 检查Cluster状态`kubectl cluster-info`， 发现还有DNS pod没有启动。用`kubectl describe` 命令查看内部状态, 发现没有node可以运行当前pod.
默认Master Node不允许任何pod运行。并且Dns Pod 有这个Tolerations： node-role.kubernetes.io/master:NoSchedule。      
解决： `kubectl taint nodes --all node-role.kubernetes.io/master-` 这样子移除Master Node的这个标签，则允许运行其它Pod.   
官方解释： https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#control-plane-node-isolation 
    ```bash
    [root@wxd kubernetes]# mkdir -p $HOME/.kube
    [root@wxd kubernetes]# cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    [root@wxd kubernetes]# chown $(id -u):$(id -g) $HOME/.kube/config
    [root@wxd kubernetes]# kubectl cluster-info
    Kubernetes master is running at https://10.0.2.15:6443
    KubeDNS is running at https://10.0.2.15:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

    To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
    [root@wxd kubernetes]# kubectl get pods -A
    NAMESPACE     NAME                               READY   STATUS    RESTARTS   AGE
    kube-system   coredns-5644d7b6d9-6qj97           0/1     Pending   0          3m45s
    kube-system   coredns-5644d7b6d9-wpktx           0/1     Pending   0          3m45s
    kube-system   etcd-wxd.long                      1/1     Running   0          2m49s
    kube-system   kube-apiserver-wxd.long            1/1     Running   0          2m56s
    kube-system   kube-controller-manager-wxd.long   1/1     Running   0          2m48s
    kube-system   kube-proxy-shmzl                   1/1     Running   0          3m45s
    kube-system   kube-scheduler-wxd.long            1/1     Running   0          3m5s
    ```
    ```bash
    Events:
    Type     Reason            Age                  From               Message
    ----     ------            ----                 ----               -------
    Warning  FailedScheduling  61s (x5 over 5m12s)  default-scheduler  0/1 nodes are available: 1 node(s) had taints that the pod didn't tolerate.
    ```

8. CoreDNS还是pending状态，可能是因为`Node NotReady`, 因为标签`node.kubernetes.io/not-ready:NoExecute for 300s`不会让CoreDns在没有ready的node上运行。    
这次`kubect describe node` 查看原因flannel网络插件没安装。 `network plugin is not ready: cni config uninitialized`    
解决办法: 必须下载CNI对应的plugin存到相应目录即可. https://github.com/containernetworking/plugins/releases
```bash
[root@wxd kubernetes]# kubectl get node
NAME       STATUS     ROLES    AGE   VERSION
wxd.long   NotReady   master   15m   v1.16.3

[root@wxd bin]# tail -f /var/log/messages 
Dec 14 08:57:54 wxd kubelet: E1214 08:57:54.186592   20895 kubelet.go:2187] Container runtime network not ready: NetworkReady=false reason:NetworkPluginNotReady message:docker: network plugin is not ready: cni config uninitialized
Dec 14 08:16:26 wxd kubelet: W1214 08:16:26.221431    7367 cni.go:237] [failed to find plugin "flannel" in path [/opt/cni/bin] failed to find plugin "portmap" in path [/opt/cni/bin]]

```

9. 

## 参考
[Bootstrapping clusters with kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/)     
