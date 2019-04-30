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
192.168.126.51 integrated-oauth-server-openshift-authentication.apps.test1.tt.testing
```

## Route all via localhost [ If you want to ... ]
```
$ # let oc have supercow powers: open lower then 1024 net sockets
$ sudo setcap CAP_NET_BIND_SERVICE=+eip $(which oc)
$ oc -n openshift-ingress port-forward svc/router-default 443
```

## Patchs and build the installer

#### Cleanup last try
```
rm -rf mycluster/
./scripts/maintenance/virsh-cleanup.sh
```

#### Get a patch

https://github.com/yaacov/okd-installer-hacks/blob/master/patch/master.patch

https://github.com/cynepco3hahue/installer-in-container/blob/master/images/installer
https://github.com/cynepco3hahue/installer-in-container/blob/master/images/installer/hacks/v0.14.0

#### Apply patch and compile
```
git apply [currect patch to].patch
TAGS=libvirt hack/build.sh
```
-------------------------------------------

## Run installer.
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

#### Set DHCP and static IP's for master and worker

```
# get mac address of test nodes
virsh list --name | grep master | xargs virsh dumpxml | grep "mac address" | cut -d"'" -f 2
virsh list --name | grep worker | xargs virsh dumpxml | grep "mac address" | cut -d"'" -f 2

# edit network dhcp
virsh net-list --name | grep test | xargs virsh net-edit
```

And add static ip's:

```
 <ip family='ipv4' address='192.168.126.1' prefix='24'>
    <dhcp>
      <range start='192.168.126.100' end='192.168.126.254'/>
      <host mac='66:4f:16:3f:5f:0f' name='master' ip='192.168.126.11'/>
      <host mac='6a:bd:3a:d7:aa:bb' name='worker' ip='192.168.126.51'/>
    </dhcp>
  </ip>
```

#### Use config.
```
cp mycluster/auth/kubeconfig ~/.kube/config

oc get pod -A
oc get nodes -A -o wide
oc get svc -A
```

#### special user kubeadmin and password written in file
```
oc login -u kubeadmin -p $(cat mycluster/auth/kubeadmin-password) --insecure-skip-tls-verify=true
```

## Re-new certificate [ If they get lost ... ]
```
kubectl get csr | xargs kubectl certificate approve
```

/etc/systemd/system/dirty-auto-approver.service
```
[Unit]
Description=Approves pending csrs. Prints into /tmp/dirty-approves file

[Service]
Type=oneshot
ExecStart=/bin/sh -c '/bin/kubectl certificate approve $(/bin/kubectl get csr -o name) 2>&1 >> /tmp/dirty-approves'
```

/etc/systemd/system/dirty-auto-approver.timer
```
[Unit]
Description=Run dirty-auto-approver every hour
Unit=dirty-auto-approver.service

[Timer]
OnCalendar=*:0/5:0

[Install]
WantedBy=multi-user.target
```
```
systemctl enable --now dirty-auto-approver.timer
```

## Browse
https://console-openshift-console.apps.test1.tt.testing

## Install kubevirt
```
$ export VERSION=v0.15.0
$ kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/$VERSION/kubevirt-operator.yaml
$ kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/$VERSION/kubevirt-cr.yaml
```

