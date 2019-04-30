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

Edit `haproxy.cfg`

Start haproxy
```
sudo systemctl enable --now haproxy.service
```

Open ports on server
```
firewall-cmd --zone=public --add-port=443/tcp --permanent
firewall-cmd --zone=public --add-port=6443/tcp --permanent
firewall-cmd --zone=public --add-port=80/tcp --permanent
firewall-cmd --reload
```
