# dev scripts

``` bash
# Install dev packages
dnf update -y
dnf install golang-bin gcc-c++ libvirt-devel libvirt libvirt-devel libvirt-daemon-kvm qemu-kvm git vim origin-clients -y
dnf groupinstall "Development Tools" -y
go get -u github.com/golang/dep/cmd/dep

# Install virtualization packages
dnf groupinstall virtualization -y
dnf install fuse -y
echo "fuse" >> /etc/modules-load.d/modules.conf

# Add virtualization to grub
vim /etc/default/grub 
grub2-mkconfig -o /boot/grub2/grub.cfg

# Enable libvirt
systemctl enable --now libvirtd-tcp.socket
systemctl enable --now libvirtd
echo listen_tls = 0 >> /etc/libvirt/libvirtd.conf
echo listen_tcp = 1 >> /etc/libvirt/libvirtd.conf
echo auth_tcp=\"none\" >> /etc/libvirt/libvirtd.conf
echo tcp_port=\"16509\" >> /etc/libvirt/libvirtd.conf
echo "dns-forward-max=1500" > /etc/dnsmasq.d/increase-forward-max
echo LIBVIRTD_ARGS="--listen" >> /etc/sysconfig/libvirtd
echo -e "[main]\ndns=dnsmasq" | sudo tee /etc/NetworkManager/conf.d/openshift.conf

# Enable firewall
systemctl enable --now firewalld
DEFAULT_ZONE=$(sudo firewall-cmd --get-default-zone)
firewall-cmd --add-rich-rule "rule service name="libvirt" reject" --permanent
firewall-cmd --zone=$DEFAULT_ZONE --add-service=libvirt --permanent
firewall-cmd --zone=$DEFAULT_ZONE --change-interface=tt0  --permanent
firewall-cmd --zone=$DEFAULT_ZONE --change-interface=virbr0  --permanent

# Add iptable rule at startup
vim startup.sh
vim startup.service
cp startup.service /etc/systemd/system/startup.service
cp startup.sh /usr/local/bin/
chmod ugo+rwx /usr/local/bin/startup.sh

systemctl enable --now startup.service

# Add dev user
echo '%wheel ALL=(ALL)       NOPASSWD: ALL' >> /etc/sudoers

useradd dev
passwd dev
usermod -aG wheel dev

# Create ssh key (for root and dev)
ssh-keygen
```
