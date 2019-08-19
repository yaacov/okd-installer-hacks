# okd-installer-hacks
hacks to install okd using installer

## Prepare

see: [detailed-requirements](#detailed-requirements)

## Patchs and build the installer

#### Cleanup last try
```
rm -rf mycluster/
./scripts/maintenance/virsh-cleanup.sh
```

#### Refs:

https://github.com/openshift/installer

https://github.com/openshift/installer/blob/master/docs/dev/libvirt/README.md

https://github.com/cynepco3hahue/installer-in-container

#### Apply patch and compile
```
[ git reset --hard origin/release-4.2 ]
[ curl https://raw.githubusercontent.com/yaacov/okd-installer-hacks/master/patch/master.patch | git apply - ]
```
```
TAGS=libvirt hack/build.sh
```
-------------------------------------------

## Run installer.
```
# export TF_VAR_libvirt_master_memory=16384 [32768 ... ]
# export OPENSHIFT_INSTALL_RELEASE_IMAGE_OVERRIDE="quay.io/openshift-release-dev/ocp-release:4.2"
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

While running, check the new network defined by the installer and update the working-<uid> network:
```
virsh net-update --config --live working-rkx9k add dns-host '<host ip="192.168.126.51"><hostname>oauth-openshift.apps.working.oc4</hostname></host>'
```

#### Set kubeconfig
```
cp mycluster/auth/kubeconfig ~/.kube/config
```

#### special user kubeadmin and password written in file
```
oc login https://api.test1.tt.testing:6443 -u kubeadmin -p $(cat mycluster/auth/kubeadmin-password)
```

## Browse
https://console-openshift-console.apps.test1.tt.testing

## Install kubevirt
```
export RELEASE=v0.18.0

oc adm policy add-scc-to-user privileged -n kubevirt -z kubevirt-operator
 
kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/${RELEASE}/kubevirt-operator.yaml
kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/${RELEASE}/kubevirt-cr.yaml

```

## Detailed requirements
```
dnf install golang-bin gcc-c++ libvirt-devel
go get -u github.com/golang/dep/cmd/dep

# ls -l /dev/kvm 
sudo dnf install libvirt libvirt-devel libvirt-daemon-kvm qemu-kvm
sudo systemctl enable --now libvirtd

sudo vim /etc/libvirt/libvirtd.conf
# Enable:
# listen_tls = 0
# listen_tcp = 1
# auth_tcp="none"
# tcp_port="16509"

sudo vim /etc/sysconfig/libvirtd
# Enable:
# LIBVIRTD_ARGS="--listen"

# virsh --connect qemu:///system net-dumpxml default
sudo iptables -I INPUT -p tcp -s 192.168.126.0/24 -d 192.168.122.1 --dport 16509 -j ACCEPT -m comment --comment "Allow insecure libvirt clients"
   
[ sudo firewall-cmd --get-default-zone ]
sudo firewall-cmd --add-rich-rule "rule service name="libvirt" reject" --permanent
sudo firewall-cmd --zone=<the default zone> --add-service=libvirt --permanent
sudo firewall-cmd --zone=<the default zone> --change-interface=tt0  --permanent
sudo firewall-cmd --zone=<the default zone> --change-interface=virbr0  --permanent

# Edit /etc/NetworkManager/conf.d/openshift.conf
echo -e "[main]\ndns=dnsmasq" | sudo tee /etc/NetworkManager/conf.d/openshift.conf

# Edit /etc/NetworkManager/dnsmasq.d/openshift.conf 
cat /etc/NetworkManager/dnsmasq.d/openshift.conf 
server=/tt.testing/192.168.126.1
address=/.apps.test1.tt.testing/192.168.126.51

sudo systemctl reload NetworkManager

```

# /etc/hosts

```
cat /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

192.168.126.11 api.test1.tt.testing
192.168.126.51 console-openshift-console.apps.test1.tt.testing
192.168.126.51 alertmanager-main-openshift-monitoring.apps.test1.tt.testing
192.168.126.51 grafana-openshift-monitoring.apps.test1.tt.testing
192.168.126.51 prometheus-k8s-openshift-monitoring.apps.test1.tt.testing
192.168.126.51 oauth-openshift.apps.test1.tt.testing
```

## Nested virtualization
Check if nested virtualization is supported `kvm_intel` or `kvm_amd`
```
cat /sys/module/kvm_intel/parameters/nested
Y
```

Enabel `kvm_intel` or `kvm_amd`:
Edit `/etc/modprobe.d/kvm.conf` and set `options kvm_intel nested=1`

Check for nested virt:
```
dnf group install virtualization
[ dnf reinstall fuse -y ]
[ modprobe fuse ]
virt-host-validate
```
