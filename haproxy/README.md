# Install and run HAProxy

HAProxy exposes openshift running on a libvirt network to the outside world.

```
# Kill httpd server if running
kill $(ps -e | grep httpd | head -n 1 | awk '{print $1;}')

# Install haproxy:
dnf install haproxy -y

# Let haproxy connect to any port:
setsebool -P haproxy_connect_any=1

# Start haproxy
sudo curl https://raw.githubusercontent.com/yaacov/okd-installer-hacks/master/haproxy/haproxy.cfg > /etc/haproxy/haproxy.cfg
systemctl enable --now haproxy.service

# Open ports on server
DEFAULT_ZONE=$(sudo firewall-cmd --get-default-zone)
firewall-cmd --zone=$DEFAULT_ZONE --add-port=443/tcp --permanent
firewall-cmd --zone=$DEFAULT_ZONE --add-port=6443/tcp --permanent
firewall-cmd --zone=$DEFAULT_ZONE --add-port=80/tcp --permanent
firewall-cmd --zone=$DEFAULT_ZONE --add-port=9000/tcp --permanent
firewall-cmd --zone=$DEFAULT_ZONE --add-port=20000-50000/tcp --permanent

firewall-cmd --reload
```

```
# Get IP addresses of the nodes
# Edit haproxy config file, to bind to this adresses
virsh net-list
virsh net-dhcp-leases ostestbm
```

```
# Remove the old line from ssh/known_hosts
sed -i '/modi07.eng.lab.tlv.redhat.com/d' /home/yzamir/.ssh/known_hosts
```
