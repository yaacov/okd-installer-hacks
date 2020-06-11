# Install and run HAProxy

HAProxy exposes openshift running on a libvirt network to the outside world.

Install haproxy:
```
sudo dnf install haproxy
```

Let haproxy connect to any port:
```
sudo setsebool -P haproxy_connect_any=1
```

Edit `/etc/haproxy/haproxy.cfg`
( [example](/haproxy/haproxy.cfg) )

Start haproxy
```
sudo systemctl enable --now haproxy.service
```

Open ports on server
```
DEFAULT_ZONE=$(sudo firewall-cmd --get-default-zone)
firewall-cmd --zone=$DEFAULT_ZONE --add-port=443/tcp --permanent
firewall-cmd --zone=$DEFAULT_ZONE --add-port=6443/tcp --permanent
firewall-cmd --zone=$DEFAULT_ZONE --add-port=80/tcp --permanent
firewall-cmd --zone=$DEFAULT_ZONE --add-port=9000/tcp --permanent

firewall-cmd --reload
```

### If apache is taking port 80 (on RHEL from PXE):
```
# find the apache pids
ps -e | grep httpd
# kill the first one, e.g.
kill <pid number>
```

### dnsmasq on fedora

```
# /etc/NetworkManager/conf.d/00-use-dnsmasq.conf
#
# This enabled the dnsmasq plugin.
[main]
dns=dnsmasq
```
```
# /etc/NetworkManager/dnsmasq.d/metalkube.conf
#
# This enable apps dns whildcard.
address=/.apps.ostest.test.metalkube.org/10.46.26.15
```
```
sudo systemctl restart dnsmasq NetworkManager
```
```
# check nameserver is set to 127.0.0.1
cat /etc/resolv.conf
```
