# okd-installer-hacks
hacks to install okd using installer

## Prepare
```
$ sudo iptables -I INPUT -p tcp -s 192.168.126.0/24 -d 192.168.122.1 --dport 16509 -j ACCEPT -m comment --comment "Allow insecure libvirt clients"
```

```
$ # add to /etc/hosts
192.168.126.11 api.test1.tt.testing

192.168.126.51 kubevirt-web-ui.apps.test1.tt.testing
192.168.126.51 oauth-openshift.apps.test1.tt.testing 
192.168.126.51 console-openshift-console.apps.test1.tt.testing
192.168.126.51 downloads-openshift-console.apps.test1.tt.testing
192.168.126.51 alertmanager-main-openshift-monitoring.apps.test1.tt.testing
192.168.126.51 grafana-openshift-monitoring.apps.test1.tt.testing
192.168.126.51 prometheus-k8s-openshift-monitoring.apps.test1.tt.testing  
```

## Patchs and build the installer

#### Cleanup last try
```
rm -rf mycluster/
./scripts/maintenance/virsh-cleanup.sh
```

#### Get a patch

https://github.com/yaacov/okd-installer-hacks/blob/master/patch/master.patch

Ref:

https://github.com/cynepco3hahue/installer-in-container/blob/master/images/installer

https://github.com/cynepco3hahue/installer-in-container/blob/master/images/installer/hacks/v0.14.0

#### Apply patch and compile
```
curl https://raw.githubusercontent.com/yaacov/okd-installer-hacks/master/patch/master.patch | git apply -

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

#### Set kubeconfig
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

## Browse
https://console-openshift-console.apps.test1.tt.testing

## Install kubevirt
```
export RELEASE=v0.17.0
kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/${RELEASE}/kubevirt.yaml
kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/${RELEASE}/kubevirt-operator.yaml
kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/${RELEASE}/kubevirt-cr.yaml

```

## Set KVM to work with nested virtualization 
edit `/etc/modprobe.d/kvm.conf` and add `options kvm_intel nested=1`

reboot, and use `virt-host-validate` to check virtuslization status.

## Detailed requirements
```
dnf install golang-bin gcc-c++ libvirt-devel
go get -u github.com/golang/dep/cmd/dep

# ls -l /dev/kvm 
sudo dnf install libvirt libvirt-devel libvirt-daemon-kvm qemu-kvm
sudo systemctl enable --now libvirtd

sudo vim /etc/libvirt/libvirtd.conf
sudo vim /etc/sysconfig/libvirtd

# virsh --connect qemu:///system net-dumpxml default
sudo iptables -I INPUT -p tcp -s 192.168.126.0/24 -d 192.168.122.1 --dport 16509 -j ACCEPT -m comment --comment "Allow insecure libvirt clients"
   
sudo firewall-cmd --add-rich-rule "rule service name="libvirt" reject" --permanent
sudo firewall-cmd --zone=dmz --add-service=libvirt --permanent
sudo firewall-cmd --zone=dmz --change-interface=tt0  --permanent
sudo firewall-cmd --zone=dmz --change-interface=virbr0  --permanent

virsh --connect qemu:///system pool-list
sudo virsh pool-define /dev/stdin <<EOF
<pool type='dir'>
  <name>default</name>
  <target>
    <path>/var/lib/libvirt/images</path>
  </target>
</pool>
EOF

sudo virsh pool-start default
sudo virsh pool-autostart default
```
