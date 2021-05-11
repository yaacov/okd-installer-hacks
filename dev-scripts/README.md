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

# Make sure all disk is usable for root fs
umount /home
lvremove $(ls /dev/mapper/rhel_dell--r* -l | grep -- -home | awk '{print $9;}') -y
lvextend -l +100%FREE -r $(ls /dev/mapper/rhel_dell--r* -l | grep -- -root | awk '{print $9;}')
sed -i '/[/]home/ s/./#&/' /etc/fstab

# Setup pass throgh virtualization
sed -i '/^GRUB_CMDLINE_LINUX/ s/console=ttyS1,115200/& intel_iommu=on/' /etc/default/grub
# Add intel_iommu=on to GRUB_CMDLINE_LINUX
grub2-mkconfig -o /boot/grub2/grub.cfg

# Install git
dnf update -y
dnf install -y git make wget jq
```

``` bash
# Setup dev user
adduser dev
usermod -aG wheel dev
echo '%wheel ALL=(ALL)       NOPASSWD: ALL' >> /etc/sudoers
```

```
# Reboot and check virtualization
reboot
```

## Dev scripts

``` bash
su - dev
ssh-keygen -P "" -f ~/.ssh/id_rsa

git clone https://github.com/openshift-metal3/dev-scripts.git
cd dev-scripts

# Edit cluster (dont forget to set CI TOKEN at the top fo the file)
# https://console-openshift-console.apps.ci.l2s4.p1.openshiftapps.com/
# https://openshift-release.apps.ci.l2s4.p1.openshiftapps.com/
cp config_example.sh config_dev.sh
vim config_dev.sh

# Add the pull secret json
# https://cloud.redhat.com/openshift/install/rhv/installer-provisioned
vim pull_secret.json

# Build
make

# Cleanup
make clean
sudo rm -rf /opt/dev-scripts /opt/metal3-dev-env logs/*
sudo rm -rf /var/lib/libvirt/images/worker_*

# Check health
sudo virsh list --all
oc --kubeconfig ~dev/dev-scripts/ocp/ostest/auth/kubeconfig get co --all-namespaces
oc --kubeconfig ~dev/dev-scripts/ocp/ostest/auth/kubeconfig get pods --all-namespaces

# Get cluster password
cat ~dev/dev-scripts/ocp/ostest/auth/kubeadmin-password ; echo;
```


## Add storage to workers

``` bash

# Create disks
qemu-img create -f qcow2 worker_0.qcow2 500G
qemu-img create -f qcow2 worker_1.qcow2 500G
qemu-img create -f qcow2 worker_2.qcow2 500G
chmod ugo+rwx worker_*

# rm /var/lib/libvirt/images/worker_*
mv worker_* /var/lib/libvirt/images/

# Attach disks
ls /var/lib/libvirt/images/
virsh attach-disk ostest_worker_0 /var/lib/libvirt/images/worker_0.qcow2 vda --persistent --live --subdriver qcow2
virsh attach-disk ostest_worker_1 /var/lib/libvirt/images/worker_1.qcow2 vda --persistent --live --subdriver qcow2
virsh attach-disk ostest_worker_2 /var/lib/libvirt/images/worker_2.qcow2 vda --persistent --live --subdriver qcow2

# Check is /dev/vda is available as a worker disk
ssh core@192.168.111.23 -i ~dev/.ssh/id_rsa
sudo fdisk -l
```

```
# If live attach-disk fails
virsh destroy ostest_worker_0
virsh attach-disk ostest_worker_0 /var/lib/libvirt/images/worker_0.qcow2 vda --persistent --config --subdriver qcow2
virsh start ostest_worker_0

# Wait for the node to be ready
oc --kubeconfig ~dev/dev-scripts/ocp/ostest/auth/kubeconfig get nodes

virsh destroy ostest_worker_1
virsh attach-disk ostest_worker_1 /var/lib/libvirt/images/worker_1.qcow2 vda --persistent --config --subdriver qcow2
virsh start ostest_worker_1

virsh destroy ostest_worker_2
virsh attach-disk ostest_worker_2 /var/lib/libvirt/images/worker_2.qcow2 vda --persistent --config --subdriver qcow2
virsh start ostest_worker_2
```

## To Do

(cron job for libvirt)
haproxy
ceph
kubevirt
oauth-test
dev-template
