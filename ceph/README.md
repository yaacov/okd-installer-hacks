# Install ceph

``` bash
export RELEASE=$(curl -s https://github.com/rook/rook/releases/latest  | grep -o "v[0-9]\.[0-9]*\.[0-9]*")
echo $RELEASE

git clone https://github.com/rook/rook.git
cd rook/cluster/examples/kubernetes/ceph

curl https://raw.githubusercontent.com/yaacov/okd-installer-hacks/master/ceph/kubevirt-storage-class-defaults.yaml > kubevirt-storage-class-defaults.yaml
curl https://raw.githubusercontent.com/yaacov/okd-installer-hacks/master/ceph/storageclass.yaml > storageclass.yaml
 
oc create namespace openshift-cnv
oc create -f common.yaml
oc create -f operator-openshift.yaml
oc create -f cluster.yaml
oc create -f pool.yaml
oc create -f storageclass.yaml

```

## Make rook-ceph default SC
``` bash
oc patch storageclass rook-ceph -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

## Adding kubevirt storage class defaults

``` bash
oc create -f kubevirt-storage-class-defaults.yaml
```

## Debug

``` bash
oc create -f toolbox.yaml
```

in the tools pod console:

``` bash
ceph status
```
