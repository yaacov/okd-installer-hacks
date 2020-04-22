# Install ceph

``` bash
git clone --single-branch --branch {{ branchName }} https://github.com/rook/rook.git
cd rook/cluster/examples/kubernetes/ceph

oc create -f common.yaml
oc create -f operator-openshift.yaml
oc create -f cluster.yaml
oc create -f pool.yaml
oc create -f storageclass.yaml

```
