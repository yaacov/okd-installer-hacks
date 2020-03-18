``` bash
cp startup.service /etc/systemd/system/startup.service
cp startup.sh /usr/local/bin

systemctl enable --now startup.service
```

```
systemctl status libvirtd-tcp.socket 
  305  systemctl status libvirtd
  306  virsh -c qemu+tcp://192.168.122.1/system version
  307  virt-host-validate
  308  iptables -L | grep dpt:16509
  
  xfs_info / | grep ftype # ftype shoud be =1
```

```
systemctl start libvirtd-tcp.socket 
  147  systemctl status libvirtd-tcp.socket 
  148  systemctl start libvirtd
  149  systemctl status libvirtd
  150  systemctl status libvirtd-tcp.socket 
  151  virsh -c qemu+tcp://192.168.122.1/system version
```

```
    2  df -h
    4  lvresize --resizefs -l +100%FREE /dev/mapper/fedora_dell--r730--00300-root
    
    8  dnf upgrade --refresh
    9   dnf install dnf-plugin-system-upgrade
   10   dnf system-upgrade download --releasever=31
   11  dnf system-upgrade reboot
   
   14  dnf update -y
   15  dnf install golang-bin gcc-c++ libvirt-devel libvirt libvirt-devel libvirt-daemon-kvm qemu-kvm git vim origin-clients
   
   16  ssh-keygen
   17  cat .ssh/id_rsa
   
   18  dnf group install virtualization
      23  virt-host-validate
      
   24  dnf reinstall fuse -y
   
   27  echo "fuse" >> /etc/modules-load.d/modules.conf
   
   29  vim /etc/default/grub 
      0  grub2-mkconfig -o /boot/grub2/grub.cfg
      
   31  systemctl enable --now libvirtd
   32  echo listen_tls = 0 >> /etc/libvirt/libvirtd.conf
   33  echo listen_tcp = 1 >> /etc/libvirt/libvirtd.conf
   34  echo auth_tcp=\"none\" >> /etc/libvirt/libvirtd.conf
   35  echo tcp_port=\"16509\" >> /etc/libvirt/libvirtd.conf
   36  echo "dns-forward-max=1500" > /etc/dnsmasq.d/increase-forward-max
   37  echo LIBVIRTD_ARGS="--listen" >> /etc/sysconfig/libvirtd
   
   47  systemctl enable --now firewalld
   48  DEFAULT_ZONE=$(sudo firewall-cmd --get-default-zone)
   49  sudo firewall-cmd --add-rich-rule "rule service name="libvirt" reject" --permanent
   50  sudo firewall-cmd --zone=$DEFAULT_ZONE --add-service=libvirt --permanent
   51  sudo firewall-cmd --zone=$DEFAULT_ZONE --change-interface=tt0  --permanent
   52  sudo firewall-cmd --zone=$DEFAULT_ZONE --change-interface=virbr0  --permanent
   53  echo -e "[main]\ndns=dnsmasq" | sudo tee /etc/NetworkManager/conf.d/openshift.conf
   
   54  virsh --connect qemu:///system net-dumpxml default
   55  sudo iptables -I INPUT -p tcp -s 192.168.126.0/24 -d 192.168.122.1 --dport 16509 -j ACCEPT -m comment --comment "Allow insecure libvirt clients"
   
   56  go get -u github.com/golang/dep/cmd/dep
   
   70  vim startup.sh
   71  vim startup.service
   72  chmod ugo+rwx startup.sh
   
   91  cp startup.service /etc/systemd/system/startup.service
   cp startup.sh /usr/local/bin

```
