# Install ceph

``` bash
export RELEASE=$(curl -s https://github.com/rook/rook/releases/latest  | grep -o "v[0-9]\.[0-9]*\.[0-9]*")
echo $RELEASE

git clone --single-branch --branch $RELEASE https://github.com/rook/rook.git
cd rook/cluster/examples/kubernetes/ceph

curl https://raw.githubusercontent.com/yaacov/okd-installer-hacks/master/ceph/storageclass.yaml > storageclass.yaml
 
oc create -f crds.yaml
oc create -f common.yaml
oc create -f operator-openshift.yaml
oc create -f cluster.yaml
oc create -f pool.yaml
oc create -f storageclass.yaml

cd csi/rbd
oc create -f storageclass.yaml 
oc create -f snapshotclass.yaml 
```

## Debug

``` bash
oc create -f toolbox.yaml
```

in the tools pod console:

``` bash
ceph status
```
