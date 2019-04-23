# Copy installed OKD4 from one machine to another

## Install a working okd4 on a machine

Compile and run the installer:
```
TAGS=libvirt hack/build.sh
./bin/openshift-install create cluster --dir=mycluster --log-level debug
```
Wait for installer to finish, and check all is ok:
```
oc get pods --all-namespaces 
NAMESPACE                                               NAME
kube-system                                             etcd-
...
```

## Dump libvirt xml files:

Install python libvirt:
```
pip install -r requirements.txt`
```

Run dumpxml:
```
python dumpxml.py
```

Check the created files:
```
ls -l
total 52
-rw-r--r--. 1 root root   16 Apr 23 11:10 base
-rw-rw-r--. 1 root root 2098 Apr 23 10:38 dumpxml.py
-rw-r--r--. 1 root root   20 Apr 23 11:10 master
-rw-r--r--. 1 root root 4045 Apr 23 11:10 master.xml
-rwxrwxr-x. 1 root root 4987 Apr 23 10:38 myshift.sh
-rw-r--r--. 1 root root   11 Apr 23 11:10 net
-rw-r--r--. 1 root root 1205 Apr 23 11:10 net.xml
-rw-r--r--. 1 root root    7 Apr 23 11:10 pool
-rw-r--r--. 1 root root  520 Apr 23 11:10 pool.xml
-rw-r--r--. 1 root root    0 Apr 23 11:04 README.md
-rw-r--r--. 1 root root   15 Apr 23 11:00 requirements.txt
-rw-r--r--. 1 root root   26 Apr 23 11:10 worker
-rw-r--r--. 1 root root 3881 Apr 23 11:10 worker.xml
```

## Copy storage images, and run the myshift script

Copy all storage images to new machine's `/var/lib/libvirt/images`
```
scp /var/lib/libvirt/images/* root@[new machine ip]:/var/lib/libvirt/images/
```

Make a copy of the images in this directory:
```
cp /var/lib/libvirt/images/* ./
```
```
ls -l
total 11424072
...
-rw-r--r--. 1 root root 2165178368 Apr 23 11:13 test1-dmdng-base
-rw-r--r--. 1 root root 5357436928 Apr 23 11:13 test1-dmdng-master-0
-rw-r--r--. 1 root root       1817 Apr 23 11:13 test1-dmdng-master.ign
-rw-r--r--. 1 root root 4175560704 Apr 23 11:13 test1-dmdng-worker-0-mx4lr
-rw-r--r--. 1 root root       1817 Apr 23 11:13 test1-dmdng-worker-0-mx4lr.ignition
...
```

Run the `myshift script`
```
./myshift.sh create
```
and
```
./myshift.sh start
```

Use ~/.kube/config and user password from your original install.
