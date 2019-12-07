## kubeadm init
```
The "init" command executes the following phases:
```
preflight                  Run pre-flight checks
kubelet-start              Write kubelet settings and (re)start the kubelet
certs                      Certificate generation
  /ca                        Generate the self-signed Kubernetes CA to provision identities for other Kubernetes components
  /apiserver                 Generate the certificate for serving the Kubernetes API
  /apiserver-kubelet-client  Generate the certificate for the API server to connect to kubelet
  /front-proxy-ca            Generate the self-signed CA to provision identities for front proxy
  /front-proxy-client        Generate the certificate for the front proxy client
  /etcd-ca                   Generate the self-signed CA to provision identities for etcd
  /etcd-server               Generate the certificate for serving etcd
  /etcd-peer                 Generate the certificate for etcd nodes to communicate with each other
  /etcd-healthcheck-client   Generate the certificate for liveness probes to healthcheck etcd
  /apiserver-etcd-client     Generate the certificate the apiserver uses to access etcd
  /sa                        Generate a private key for signing service account tokens along with its public key
kubeconfig                 Generate all kubeconfig files necessary to establish the control plane and the admin kubeconfig file
  /admin                     Generate a kubeconfig file for the admin to use and for kubeadm itself
  /kubelet                   Generate a kubeconfig file for the kubelet to use *only* for cluster bootstrapping purposes
  /controller-manager        Generate a kubeconfig file for the controller manager to use
  /scheduler                 Generate a kubeconfig file for the scheduler to use
control-plane              Generate all static Pod manifest files necessary to establish the control plane
  /apiserver                 Generates the kube-apiserver static Pod manifest
  /controller-manager        Generates the kube-controller-manager static Pod manifest
  /scheduler                 Generates the kube-scheduler static Pod manifest
etcd                       Generate static Pod manifest file for local etcd
  /local                     Generate the static Pod manifest file for a local, single-node local etcd instance
upload-config              Upload the kubeadm and kubelet configuration to a ConfigMap
  /kubeadm                   Upload the kubeadm ClusterConfiguration to a ConfigMap
  /kubelet                   Upload the kubelet component config to a ConfigMap
upload-certs               Upload certificates to kubeadm-certs
mark-control-plane         Mark a node as a control-plane
bootstrap-token            Generates bootstrap tokens used to join a node to a cluster
addon                      Install required addons for passing Conformance tests
  /coredns                   Install the CoreDNS addon to a Kubernetes cluster
  /kube-proxy                Install the kube-proxy addon to a Kubernetes cluster
```

```




[WARNING Service-Kubelet]: kubelet service is not enabled, please run 'systemctl enable kubelet.service'


kubectl logs -f coredns-78d4cf999f-2mjbj -n kube-system“

Q: flector.go:94: Failed to list *v1.Service: Get https://10.96.0.1:443/api/v1/services?limit=500&resourceVersion=0: dial tcp 10.96.0.1:443: connect: no route to host

A: iptables --flush