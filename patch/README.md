``` bash
cp startup.service /etc/systemd/system/startup.service
cp startup.sh /usr/local/bin

systemctl enable --now startup.service
```

```
systemctl status libvirtd-tcp.socket 
systemctl status libvirtd
virsh -c qemu+tcp://192.168.122.1/system version
virt-host-validate
iptables -L | grep dpt:16509
  
xfs_info / | grep ftype # ftype shoud be =1
```

```
systemctl start libvirtd-tcp.socket 
systemctl status libvirtd-tcp.socket 
systemctl start libvirtd
systemctl status libvirtd
systemctl status libvirtd-tcp.socket 
virsh -c qemu+tcp://192.168.122.1/system version
```

```
df -h
lvresize --resizefs -l +100%FREE /dev/mapper/fedora_dell--r730--00300-root
    
dnf upgrade --refresh
dnf install dnf-plugin-system-upgrade
dnf system-upgrade download --releasever=31
dnf system-upgrade reboot
   
dnf update -y
dnf install golang-bin gcc-c++ libvirt-devel libvirt libvirt-devel libvirt-daemon-kvm qemu-kvm git vim origin-clients
   
# for dev scripts
sudo dnf groupinstall "Development Tools"

# for virtaulization
dnf group install virtualization
dnf install fuse -y
   
ssh-keygen
cat .ssh/id_rsa
   
virt-host-validate
      
dnf reinstall fuse -y
   
echo "fuse" >> /etc/modules-load.d/modules.conf
   
vim /etc/default/grub 
grub2-mkconfig -o /boot/grub2/grub.cfg
      
systemctl enable --now libvirtd
echo listen_tls = 0 >> /etc/libvirt/libvirtd.conf
echo listen_tcp = 1 >> /etc/libvirt/libvirtd.conf
echo auth_tcp=\"none\" >> /etc/libvirt/libvirtd.conf
echo tcp_port=\"16509\" >> /etc/libvirt/libvirtd.conf
echo "dns-forward-max=1500" > /etc/dnsmasq.d/increase-forward-max
echo LIBVIRTD_ARGS="--listen" >> /etc/sysconfig/libvirtd
   
systemctl enable --now firewalld
DEFAULT_ZONE=$(sudo firewall-cmd --get-default-zone)
sudo firewall-cmd --add-rich-rule "rule service name="libvirt" reject" --permanent
sudo firewall-cmd --zone=$DEFAULT_ZONE --add-service=libvirt --permanent
sudo firewall-cmd --zone=$DEFAULT_ZONE --change-interface=tt0  --permanent
sudo firewall-cmd --zone=$DEFAULT_ZONE --change-interface=virbr0  --permanent
echo -e "[main]\ndns=dnsmasq" | sudo tee /etc/NetworkManager/conf.d/openshift.conf
   
virsh --connect qemu:///system net-dumpxml default
sudo iptables -I INPUT -p tcp -s 192.168.126.0/24 -d 192.168.122.1 --dport 16509 -j ACCEPT -m comment --comment "Allow insecure libvirt clients"
   
go get -u github.com/golang/dep/cmd/dep
   
vim startup.sh
vim startup.service
chmod ugo+rwx startup.sh
   
cp startup.service /etc/systemd/system/startup.service
startup.sh /usr/local/bin

```
