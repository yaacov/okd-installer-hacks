# dev scripts

## References

https://github.com/MoserMichael/metal3-dev-scripts-howto

https://github.com/openshift-metal3/dev-scripts

## Install and init RHEL 8

``` bash
# Subscribe RHEL
subscription-manager register --serverurl subscription.rhsm.stage.redhat.com --username xxxx --password xxxx --auto-attach
dnf update -y

# Make sure all disk is usable for root fs
umount /home
lvremove /dev/mapper/rhel_dell--r640--005-home
lvextend -l +100%FREE -r /dev/mapper/rhel_dell--r640--005-root
vim /etc/fstab # remove home

# Setup dev user
adduser dev
passwd dev
usermod -aG wheel dev
echo '%wheel ALL=(ALL)       NOPASSWD: ALL' >> /etc/sudoers

# Install virtualization
dnf install virt-install golang-bin gcc-c++ libvirt-devel libvirt libvirt-devel libvirt-daemon-kvm qemu-kvm git vim -y
dnf groupinstall "Development Tools" -y
go get -u github.com/golang/dep/cmd/dep

systemctl enable --now libvirtd

echo listen_tls = 0 >> /etc/libvirt/libvirtd.conf
echo listen_tcp = 1 >> /etc/libvirt/libvirtd.conf
echo auth_tcp=\"none\" >> /etc/libvirt/libvirtd.conf
echo tcp_port=\"16509\" >> /etc/libvirt/libvirtd.conf
echo "dns-forward-max=1500" > /etc/dnsmasq.d/increase-forward-max
echo LIBVIRTD_ARGS="--listen" >> /etc/sysconfig/libvirtd

systemctl enable --now firewalld
DEFAULT_ZONE=$(sudo firewall-cmd --get-default-zone)
firewall-cmd --add-rich-rule "rule service name="libvirt" reject" --permanent
firewall-cmd --zone=$DEFAULT_ZONE --add-service=libvirt --permanent
firewall-cmd --zone=$DEFAULT_ZONE --change-interface=tt0  --permanent
firewall-cmd --zone=$DEFAULT_ZONE --change-interface=virbr0  --permanent

echo -e "[main]\ndns=dnsmasq" | sudo tee /etc/NetworkManager/conf.d/openshift.conf

# Reboot and check virtualization
reboot

virt-host-validate
systemctl status libvirtd
virsh -c qemu+tcp://192.168.122.1/system version
iptables -I INPUT -p tcp -s 192.168.126.0/24 -d 192.168.122.1 --dport 16509 -j ACCEPT -m comment --comment "Allow insecure libvirt clients"
```

## Dev scripts

``` bash
su - dev
ssh-keygen

git config --global user.email xxxx
git config --global user.name xxxx

git clone https://github.com/openshift-metal3/dev-scripts.git
cd dev-scripts

# Edit cluster
cp config_example.sh config_dev.sh
vim config_dev.sh

# Build
make

# Check health
sudo virsh list --all
oc --kubeconfig ~/dev-scripts/ocp/ostest/auth/kubeconfig get co --all-namespaces
oc --kubeconfig ~/dev-scripts/ocp/ostest/auth/kubeconfig get pods --all-namespaces

# Cleanup
sudo rm -rf /opt/dev-scripts /opt/metal3-dev-env logs/*
make clean
```

## Add storage to workers

``` bash

# Create disks
qemu-img create -f qcow2 worker_1.qcow2 400G
qemu-img create -f qcow2 worker_2.qcow2 400G
qemu-img create -f qcow2 worker_3.qcow2 400G
qemu-img create -f qcow2 worker_4.qcow2 400G
qemu-img create -f qcow2 worker_5.qcow2 400G
chmod ugo+rwx worker_*
mv worker_* /var/lib/libvirt/images/

# Attach disks
ls /var/lib/libvirt/images/
virsh attach-disk ostest_worker_0 /var/lib/libvirt/images/worker_0.qcow2 vda --persistent --live --subdriver qcow2
virsh attach-disk ostest_worker_1 /var/lib/libvirt/images/worker_1.qcow2 vda --persistent --live --subdriver qcow2
virsh attach-disk ostest_worker_2 /var/lib/libvirt/images/worker_2.qcow2 vda --persistent --live --subdriver qcow2
virsh attach-disk ostest_worker_3 /var/lib/libvirt/images/worker_3.qcow2 vda --persistent --live --subdriver qcow2
virsh attach-disk ostest_worker_4 /var/lib/libvirt/images/worker_4.qcow2 vda --persistent --live --subdriver qcow2
virsh attach-disk ostest_worker_5 /var/lib/libvirt/images/worker_5.qcow2 vda --persistent --live --subdriver qcow2

# Check is /dev/vda is available as a worker disk
ssh core@192.168.111.23 -i ~dev/.ssh/id_rsa
sudo fdisk -l
```
