
export IP_STACK=v4
export VIRSH_DEFAULT_CONNECT_URI=qemu:///system

export NUM_WORKERS=3
export WORKER_MEMORY=65536
export WORKER_DISK=85
export WORKER_VCPU=4

export NUM_MASTERS=3
export MASTER_MEMORY=65536
export MASTER_DISK=85
export MASTER_VCPU=4

export IP_STACK=v4
# min 3 workers for ceph
export NUM_WORKERS=3
# min 2Gi for virtualization
export WORKER_MEMORY=65536
export WORKER_DISK=85
# default is to use CI nightly
# export OPENSHIFT_RELEASE_IMAGE='quay.io/openshift-release-dev/ocp-release:4.4.0-rc.10-x86_64'
