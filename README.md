# okd-installer-hacks
hacks to install okd using installer

## Prepare
```
$ sudo iptables -I INPUT -p tcp -s 192.168.126.0/24 -d 192.168.122.1 --dport 16509 -j ACCEPT -m comment --comment "Allow insecure libvirt clients"
```

```
$ # add to /etc/hosts
192.168.126.11 test1-api.tt.testing
192.168.126.51 console-openshift-console.apps.test1.tt.testing
192.168.126.51 grafana-openshift-monitoring.apps.test1.tt.testing
192.168.126.51 prometheus-k8s-openshift-monitoring.apps.test1.tt.testing
192.168.126.51 openshift-authentication-openshift-authentication.apps.test1.tt.testing
```

# Route all via localhost [ If you want to ... ]
```
$ # let oc have supercow powers: open lower then 1024 net sockets
$ sudo setcap CAP_NET_BIND_SERVICE=+eip $(which oc)
$ oc -n openshift-ingress port-forward svc/router-default 443
```

# Patchs for installer
https://github.com/yaacov/okd-installer-hacks/blob/master/patch/master.patch

https://github.com/cynepco3hahue/installer-in-container/blob/master/images/installer
https://github.com/cynepco3hahue/installer-in-container/blob/master/images/installer/hacks/v0.14.0

## Apply patch and compile
```
git apply [currect patch to].patch
TAGS=libvirt hack/build.sh
```
-------------------------------------------

## Cleanup
```
rm -rf mycluster/
./scripts/maintenance/virsh-cleanup.sh
```

# Run installer.
```
# env TF_VAR_libvirt_master_memory=16384 ./bin/openshift-install create cluster --dir=mycluster --log-level debug
./bin/openshift-install create cluster --dir=mycluster --log-level debug

	? SSH Public Key /home/yzamir/.ssh/id_rsa.pub
	DEBUG       Fetching "Base Domain"...              
	DEBUG         Fetching "Platform"...               
	DEBUG         Generating "Platform"...             
	? Platform libvirt
	? Libvirt Connection URI qemu+tcp://192.168.122.1/system
	DEBUG       Generating "Base Domain"...            
	? Base Domain tt.testing
	DEBUG       Fetching "Cluster Name"...             
	DEBUG         Fetching "Base Domain"...            
	DEBUG         Reusing previously-fetched "Base Domain" 
	DEBUG       Generating "Cluster Name"...           
	? Cluster Name test1
	DEBUG       Fetching "Pull Secret"...              
	DEBUG       Generating "Pull Secret"...            
	? The container registry pull secret for this cluster, as a single line of JSON (e.g. {"auths": {...}}).

	You can get this secret from https://cloud.openshift.com/clusters/install#pull-secret
```


## Use config.
```
cp mycluster/auth/kubeconfig ~/.kube/config

oc get pod -A
oc get nodes -A -o wide
oc get svc -A
```

# Re new certificate
```
kubectl get csr | xargs kubectl certificate approve
```

# Browse
https://console-openshift-console.apps.test1.tt.testing

## special user kubeadmin and password written in file
```
oc login -u kubeadmin -p $(cat mycluster/auth/kubeadmin-password) --insecure-skip-tls-verify=true --certificate-authority=/home/yzamir/.ssh/id_rsa.pub
```

# install kubevirt
```
$ export VERSION=v0.14.0
$ kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/$VERSION/kubevirt-operator.yaml
$ kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/$VERSION/kubevirt-cr.yaml
```

