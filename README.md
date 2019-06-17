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

#### Get a patch

https://github.com/yaacov/okd-installer-hacks/blob/master/patch/master.patch

Ref:

https://github.com/cynepco3hahue/installer-in-container/blob/master/images/installer

https://github.com/cynepco3hahue/installer-in-container/blob/master/images/installer/hacks/v0.14.0

#### Apply patch and compile
```
[git reset --hard origin/release-4.2]

curl https://raw.githubusercontent.com/yaacov/okd-installer-hacks/master/patch/master.patch | git apply -

TAGS=libvirt hack/build.sh
```
-------------------------------------------

## Run installer.
```
# export TF_VAR_libvirt_master_memory=16384
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

#### Set kubeconfig
```
cp mycluster/auth/kubeconfig ~/.kube/config

oc get pod -A
oc get nodes -A -o wide
oc get svc -A
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
kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/${RELEASE}/kubevirt.yaml
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

# Edit /etc/NetworkManager/conf.d/openshift.conf
echo -e "[main]\ndns=dnsmasq" | sudo tee /etc/NetworkManager/conf.d/openshift.conf

# Edit /etc/NetworkManager/dnsmasq.d/openshift.conf 
cat /etc/NetworkManager/dnsmasq.d/openshift.conf 
server=/tt.testing/192.168.126.1
address=/.apps.test1.tt.testing/192.168.126.51

sudo systemctl reload NetworkManager

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
