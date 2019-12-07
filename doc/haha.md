cni.go:237] Unable to update cni config: no networks found in /etc/cni/net.d

hostname-override

 Attempting to register node wxd.long
 Unable to register node "wxd.long" with API server: nodes "wxd.long" is forbidden: node "wxdlong" is not allowed to modify node "wxd.long"


Dec 06 23:01:45 wxd.long kubelet[4111]: I1206 23:01:45.756689    4111 kubelet_node_status.go:75] Successfully registered node wxdlong



Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 10.0.2.15:6443 --token 1gmwsw.5hiv6wlel59wyi54 \
    --discovery-token-ca-cert-hash sha256:2fe8ba0ac9a16c35440fd9d8f60ef047915dba106419d4ab55c53449b8c9d51e 




[root@wxd .kube]# kubectl cluster-info
Kubernetes master is running at https://10.0.2.15:6443
KubeDNS is running at https://10.0.2.15:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
[root@wxd .kube]# kubectl get pods --all-namespaces
NAMESPACE     NAME                              READY   STATUS    RESTARTS   AGE
kube-system   coredns-5644d7b6d9-7bgj2          0/1     Pending   0          6m31s
kube-system   coredns-5644d7b6d9-ztnl5          0/1     Pending   0          6m31s
kube-system   etcd-wxdlong                      1/1     Running   0          5m37s
kube-system   kube-apiserver-wxdlong            1/1     Running   0          5m47s
kube-system   kube-controller-manager-wxdlong   1/1     Running   0          5m39s
kube-system   kube-proxy-5lnmn                  1/1     Running   0          6m31s
kube-system   kube-scheduler-wxdlong            1/1     Running   0          5m31s

     1 node(s) had taints that the pod didn't tolerate.


kubectl taint nodes --all node-role.kubernetes.io/master-

https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#control-plane-node-isolation




Ready            False   Sat, 07 Dec 2019 03:45:34 -0500   Sat, 07 Dec 2019 03:35:29 -0500   KubeletNotReady              runtime network not ready: NetworkReady=false reason:NetworkPluginNotReady message:docker: network plugin is not ready: cni config uninitialized

