//disable selinux

```bash
[root@wxd bin]# setenforce 0
[root@wxd bin]# echo "SELINUX=disabled" > /etc/selinux/config
```

```bash
[root@wxd bin]# docker run wxdlong/gocker
docker: Error response from daemon: OCI runtime create failed: container_linux.go:346: starting container process caused "process_linux.go:449: container init caused \"write /proc/self/attr/keycreate: permission denied\"": unknown.
ERRO[0000] error waiting for container: context canceled 
```


//stop firewalld


### pull images

[preflight] You can also perform this action in beforehand using 'kubeadm config images pull'
I1204 10:06:49.107011   14430 checks.go:845] pulling k8s.gcr.io/kube-apiserver:v1.16.2
I1204 10:07:04.231315   14430 checks.go:845] pulling k8s.gcr.io/kube-controller-manager:v1.16.2
I1204 10:07:19.483445   14430 checks.go:845] pulling k8s.gcr.io/kube-scheduler:v1.16.2
I1204 10:07:34.589009   14430 checks.go:845] pulling k8s.gcr.io/kube-proxy:v1.16.2
I1204 10:07:49.681391   14430 checks.go:845] pulling k8s.gcr.io/pause:3.1
I1204 10:08:04.783291   14430 checks.go:845] pulling k8s.gcr.io/etcd:3.3.15-0
I1204 10:08:19.885715   14430 checks.go:845] pulling k8s.gcr.io/coredns:1.6.2
