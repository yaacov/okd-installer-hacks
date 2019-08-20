# okd-installer-hacks
hacks to install okd using installer

## Prepare

see: [detailed-requirements](#detailed-requirements)

## Build the installer

#### Refs:

https://github.com/openshift/installer

https://github.com/openshift/installer/blob/master/docs/dev/libvirt/README.md

https://github.com/cynepco3hahue/installer-in-container

#### Cleanup last try
```
rm -rf mycluster/
./scripts/maintenance/virsh-cleanup.sh
```
#### git clone openshift installer
```
mkdir -p /root/go/src/github.com/openshift/ && cd $_
git clone https://github.com/openshift/installer.git && cd installer
```
#### Compile
```
[ git reset --hard origin/release-4.2 ]
```
##### To enable libvirt based install use the `TAGS` env var
```
TAGS=libvirt hack/build.sh
```
-------------------------------------------

## Run installer.
```
# The following 2 lines should only be used if you want to override default values, otherwise skip.
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
	
( In this example we patch the `test1-4crq4` network, replace with the network created by the installer )
```
virsh net-update --config --live test1-4crq4 add dns-host '<host ip="192.168.126.51"><hostname>oauth-openshift.apps.test1.tt.testing</hostname></host>'
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

### Verify that you have both private and publicy keys under ~/.ssh/ , otherwise generate via
```
ssh-keygen
```
### Install needed packages
```
dnf install golang-bin gcc-c++ libvirt-devel libvirt libvirt-devel libvirt-daemon-kvm qemu-kvm git vim origin-clients
go get -u github.com/golang/dep/cmd/dep
```
### Check and setup virtualization 
#### Check nested virtualization
```
ls -l /dev/kvm
```
#### Libvirt configuration
```
sudo systemctl enable --now libvirtd

echo listen_tls = 0 >> /etc/libvirt/libvirtd.conf
echo listen_tcp = 1 >> /etc/libvirt/libvirtd.conf
echo auth_tcp="none" >> /etc/libvirt/libvirtd.conf
echo tcp_port="16509" >> /etc/libvirt/libvirtd.conf

echo LIBVIRTD_ARGS="--listen" >> /etc/sysconfig/libvirtd
```

### Configure iptables and firewall
```
virsh --connect qemu:///system net-dumpxml default
sudo iptables -I INPUT -p tcp -s 192.168.126.0/24 -d 192.168.122.1 --dport 16509 -j ACCEPT -m comment --comment "Allow insecure libvirt clients"
   
DEFAULT_ZONE=$(sudo firewall-cmd --get-default-zone)
sudo firewall-cmd --add-rich-rule "rule service name="libvirt" reject" --permanent
sudo firewall-cmd --zone=$DEFAULT_ZONE --add-service=libvirt --permanent
sudo firewall-cmd --zone=$DEFAULT_ZONE --change-interface=tt0  --permanent
sudo firewall-cmd --zone=$DEFAULT_ZONE --change-interface=virbr0  --permanent
```

### Edit /etc/NetworkManager/conf.d/openshift.conf
`echo -e "[main]\ndns=dnsmasq" | sudo tee /etc/NetworkManager/conf.d/openshift.conf`

### Edit /etc/NetworkManager/dnsmasq.d/openshift.conf 
```
echo -e "server=/tt.testing/192.168.126.1\naddress=/.apps.test1.tt.testing/192.168.126.51" | sudo tee /etc/NetworkManager/dnsmasq.d/openshift.conf
sudo systemctl reload NetworkManager
```

### Edit /etc/hosts
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
