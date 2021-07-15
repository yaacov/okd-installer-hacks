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
lvremove $(ls /dev/mapper/*_dell--r* -l | grep -- -home | awk '{print $9;}') -y
lvextend -l +100%FREE -r $(ls /dev/mapper/*_dell--r* -l | grep -- -root | awk '{print $9;}')
sed -i '/[/]home/ s/./#&/' /etc/fstab

# Setup pass throgh virtualization
sed -i '/^GRUB_CMDLINE_LINUX/ s/console=ttyS1,115200/& intel_iommu=on/' /etc/default/grub
# Add intel_iommu=on to GRUB_CMDLINE_LINUX
grub2-mkconfig -o /boot/grub2/grub.cfg

# Anable nested option for kvm
echo "options kvm_intel nested=1" >> /etc/modprobe.d/kvm.conf

# Remove beaker tasks repo
rm -f /etc/yum.repos.d/beaker-tasks.repo

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

# Check health
sudo virsh list --all
oc --kubeconfig ~dev/dev-scripts/ocp/ostest/auth/kubeconfig get co --all-namespaces
oc --kubeconfig ~dev/dev-scripts/ocp/ostest/auth/kubeconfig get pods --all-namespaces

# Get cluster password
cat ~dev/dev-scripts/ocp/ostest/auth/kubeadmin-password ; echo;
# Get cluster api server
cat ~dev/dev-scripts/ocp/ostest/auth/kubeconfig | grep :6443
```

```
# Cleanup (none-reversable, remove and delete the cluster and free up disk space)
make clean
sudo rm -rf /opt/dev-scripts /opt/metal3-dev-env logs/*
sudo rm -rf /var/lib/libvirt/images/worker_*
```

