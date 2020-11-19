# dev scripts

## References

https://github.com/MoserMichael/metal3-dev-scripts-howto

https://github.com/openshift-metal3/dev-scripts

https://openshift-release.apps.ci.l2s4.p1.openshiftapps.com/

https://cloud.redhat.com/openshift/install/rhv/installer-provisioned

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

# Setup pass throgh virtualization
vim /etc/default/grub
# Add intel_iommu=on systemd.unified_cgroup_hierarchy=0 to GRUB_CMDLINE_LINUX
grub2-mkconfig -o /boot/grub2/grub.cfg

# Setup dev user
adduser dev
usermod -aG wheel dev
echo '%wheel ALL=(ALL)       NOPASSWD: ALL' >> /etc/sudoers

# Install virtualization
dnf install virt-install golang-bin gcc-c++ libvirt-devel libvirt libvirt-devel libvirt-daemon-kvm qemu-kvm git -y

systemctl enable --now libvirtd
systemctl enable --now firewalld

DEFAULT_ZONE=$(sudo firewall-cmd --get-default-zone)
firewall-cmd --add-rich-rule "rule service name="libvirt" reject" --permanent
firewall-cmd --zone=$DEFAULT_ZONE --add-service=libvirt --permanent
firewall-cmd --zone=$DEFAULT_ZONE --change-interface=tt0  --permanent
firewall-cmd --zone=$DEFAULT_ZONE --change-interface=virbr0  --permanent

# Remove beaker temp repo
rm -rf /etc/yum.repos.d/beaker-tasks.repo

# Reboot and check virtualization
reboot
# Set iptables after reboot
iptables -I INPUT -p tcp -s 192.168.126.0/24 -d 192.168.122.1 --dport 16509 -j ACCEPT -m comment --comment "Allow insecure libvirt clients"

virt-host-validate
systemctl status libvirtd
```

## Dev scripts

``` bash
su - dev
ssh-keygen

git config --global user.email xxxx
git config --global user.name xxxx

git clone https://github.com/openshift-metal3/dev-scripts.git
cd dev-scripts

# Edit cluster (dont forget to set CI TOKEN at the top fo the file)
cp config_example.sh config_dev.sh
vim config_dev.sh

# Add the pull secret json
vim pull_secret.json

# Build
make

# Check health
sudo virsh list --all
oc --kubeconfig ~/dev-scripts/ocp/ostest/auth/kubeconfig get co --all-namespaces
oc --kubeconfig ~/dev-scripts/ocp/ostest/auth/kubeconfig get pods --all-namespaces

# Cleanup
make clean
sudo rm -rf /opt/dev-scripts /opt/metal3-dev-env logs/*
sudo rm -rf /var/lib/libvirt/images/worker_*
```

## Add storage to workers

``` bash

# Create disks
qemu-img create -f qcow2 worker_0.qcow2 800G
qemu-img create -f qcow2 worker_1.qcow2 800G
qemu-img create -f qcow2 worker_2.qcow2 800G
qemu-img create -f qcow2 worker_3.qcow2 800G
qemu-img create -f qcow2 worker_4.qcow2 800G
qemu-img create -f qcow2 worker_5.qcow2 800G
chmod ugo+rwx worker_*

# rm /var/lib/libvirt/images/worker_*
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

## Set bridge on workers
```
ssh core@192.168.111.23-28 -i ~dev/.ssh/id_rsa
cd /var/lib/cni/bin
sudo rm cnv-bridge
sudo rm cnv-tuning
sudo ln -s bridge cnv-bridge
sudo ln -s tuning cnv-tuning
```

## Taint master nodes

``` bash
kubectl taint node -l node-role.kubernetes.io/master node-role.kubernetes.io/master=true:NoSchedule

```
