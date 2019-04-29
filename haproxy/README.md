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