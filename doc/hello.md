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