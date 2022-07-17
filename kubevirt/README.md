# Install kubevirt

``` bash
export HOC_IMAGE_VER=1.8.0-unstable
export HOC_GIT_TAG=release-4.12
export HCO_SUBSCRIPTION_CHANNEL="1.8.0"

cat <<EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: hco-unstable-catalog-source
  namespace: openshift-marketplace
spec:
  sourceType: grpc
  image: quay.io/kubevirt/hyperconverged-cluster-index:${HOC_IMAGE_VER}
  displayName: Kubevirt Hyperconverged Cluster Operator
  publisher: Kubevirt Project
EOF

cat <<EOF | oc apply -f -
apiVersion: v1
kind: Namespace
metadata:
    name: kubevirt-hyperconverged
---
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
    name: kubevirt-hyperconverged-group
    namespace: kubevirt-hyperconverged
---
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
    name: hco-operatorhub
    namespace: kubevirt-hyperconverged
spec:
    source: hco-unstable-catalog-source
    sourceNamespace: openshift-marketplace
    name: community-kubevirt-hyperconverged
    channel: ${HCO_SUBSCRIPTION_CHANNEL}
EOF

# Wait for HCO cr to be created
oc create -f https://raw.githubusercontent.com/kubevirt/hyperconverged-cluster-operator/${HOC_GIT_TAG}/deploy/hco.cr.yaml -n kubevirt-hyperconverged
```

