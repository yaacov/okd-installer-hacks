# Install and run HAProxy

HAProxy exposes openshift running on a libvirt network to the outside world.

### If apache is taking port 80 (on RHEL from PXE):
```
# find the apache pids
ps -e | grep httpd

# kill the first one, e.g.
kill $(ps -e | grep httpd | head -n 1 | awk '{print $1;}')
```

Install haproxy:
```
dnf install haproxy -y
```

Let haproxy connect to any port:
```
setsebool -P haproxy_connect_any=1
```

Edit `/etc/haproxy/haproxy.cfg`
( [example](/haproxy/haproxy.cfg) )

Start haproxy
```
sudo curl https://raw.githubusercontent.com/yaacov/okd-installer-hacks/master/haproxy/haproxy.cfg > /etc/haproxy/haproxy.cfg
systemctl enable --now haproxy.service
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

