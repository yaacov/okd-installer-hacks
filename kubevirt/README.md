# Install kubevirt

``` bash
# Kubevirt
export RELEASE=$(curl -s https://github.com/kubevirt/kubevirt/releases/latest | grep -o "v[0-9]\.[0-9]*\.[0-9]*")
echo $RELEASE
oc adm policy add-scc-to-user privileged -n kubevirt -z kubevirt-operator
oc apply -f https://github.com/kubevirt/kubevirt/releases/download/${RELEASE}/kubevirt-operator.yaml
oc apply -f https://github.com/kubevirt/kubevirt/releases/download/${RELEASE}/kubevirt-cr.yaml

# CDI
export VERSION=$(curl -s https://github.com/kubevirt/containerized-data-importer/releases/latest | grep -o "v[0-9]\.[0-9]*\.[0-9]*")
echo $VERSION
oc create -f https://github.com/kubevirt/containerized-data-importer/releases/download/$VERSION/cdi-operator.yaml
oc create -f https://github.com/kubevirt/containerized-data-importer/releases/download/$VERSION/cdi-cr.yaml


# SSD operator
git clone https://github.com/MarSik/kubevirt-ssp-operator.git
cd kubevirt-ssp-operator
export NAMESPACE=kubevirt
hack/install-operator.sh $NAMESPACE


# Common Templates
sudo dnf install intltool ansible

git clone https://github.com/kubevirt/common-templates
cd common-templates
git submodule init
git submodule update

make -C osinfo-db
ansible-playbook generate-templates.yaml

oc project openshift
oc create -f dist/templates
```


``` bash
# CDI
export VERSION=v1.18.2
oc delete -f https://github.com/kubevirt/containerized-data-importer/releases/download/$VERSION/cdi-cr.yaml
oc delete -f https://github.com/kubevirt/containerized-data-importer/releases/download/$VERSION/cdi-operator.yaml

# Kubevirt
export RELEASE=v0.30.3
oc delete -f https://github.com/kubevirt/kubevirt/releases/download/${RELEASE}/kubevirt-cr.yaml
oc delete -f https://github.com/kubevirt/kubevirt/releases/download/${RELEASE}/kubevirt-operator.yaml


```
