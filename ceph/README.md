# Install ceph

``` bash
export RELEASE=$(curl -sL https://github.com/rook/rook/releases/latest  | grep -o "v[0-9]\.[0-9]*\.[0-9]*" | head -n 1 - )
echo $RELEASE

git clone --single-branch --branch $RELEASE https://github.com/rook/rook.git

cd rook/deploy/examples
kubectl create -f crds.yaml -f common.yaml -f operator-openshift.yaml
kubectl create -f cluster.yaml
oc create -f pool.yaml

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
