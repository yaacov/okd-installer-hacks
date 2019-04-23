#!/bin/sh

set +x

net=$(cat net)
base=$(cat base)
master=$(cat master)
worker=$(cat worker)

echo ${net} ${master} ${worker}

prerequisites()
{
    # Check if virtualization is supported
    ls /dev/kvm 2> /dev/null
    if [ $? -ne 0 ]
    then
        echo "Your system doesn't support virtualization"
        exit 1
    fi

    # Install required dependecies
    sudo yum install -y libvirt libvirt-devel libvirt-daemon-kvm qemu-kvm

    # Enable IP forwarding
    sudo sysctl net.ipv4.ip_forward=1

    # Configure libvirt to accept TCP connections
    sudo sed -i.bak -e 's/^[#]*\s*listen_tls.*/listen_tls = 0/' -e 's/^[#]*\s*listen_tcp.*/listen_tcp = 1/' -e 's/^[#]*\s*auth_tcp.*/auth_tcp = "none"/' -e 's/^[#]*\s*tcp_port.*/tcp_port = "16509"/' /etc/libvirt/libvirtd.conf

    # Configure the service runner to pass --listen to libvirtd
    sudo sed -i.bak -e 's/^[#]*\s*LIBVIRTD_ARGS.*/LIBVIRTD_ARGS="--listen"/' /etc/sysconfig/libvirtd

    # Restart the libvirtd service
    sudo systemctl restart libvirtd

    # Get active Firewall zone option
    systemctl is-active firewalld
    if [ $? -ne 0 ]
    then
        echo "Your system doesn't have firewalld service running"
        exit 1
    fi

    activeZone=$(firewall-cmd --get-active-zones | head -n 1)
    sudo firewall-cmd --zone=$activeZone --add-source=192.168.126.0/24
    sudo firewall-cmd --zone=$activeZone --add-port=16509/tcp

    # Configure default libvirt storage pool
    sudo virsh --connect qemu:///system pool-list | grep -q 'default'
    if [ $? -ne 0 ]
    then
        sudo virsh pool-define /dev/stdin <<EOF
<pool type='dir'>
  <name>default</name>
  <target>
    <path>/var/lib/libvirt/images</path>
  </target>
</pool>
EOF
    sudo virsh pool-start default
    sudo virsh pool-autostart default
    fi

    # Set up NetworkManager DNS overlay
    dnsconf=/etc/NetworkManager/conf.d/crc-libvirt-dnsmasq.conf
    local dnschanged=""
    if ! [ -f "${dnsconf}" ]; then
        echo -e "[main]\ndns=dnsmasq" | sudo tee "${dnsconf}"
        dnschanged=1
    fi
    dnsmasqconf=/etc/NetworkManager/dnsmasq.d/openshift.conf
    if ! [ -f "${dnsmasqconf}" ]; then
        echo server=/tt.testing/192.168.126.1 | sudo tee "${dnsmasqconf}"
        dnschanged=1
    fi
    if [ -n "$dnschanged" ]; then
        sudo systemctl restart NetworkManager
    fi

    # Create an entry in the /etc/host
    grep -q 'libvirt.default' /etc/hosts
    if [ $? -ne 0 ]
    then
        echo '192.168.126.1   libvirt.default' | sudo tee --append /etc/hosts
    fi
}

cluster_create()
{
    sudo virsh net-define ./net.xml
    sudo virsh net-start ${net}

    size=$(stat -Lc%s ${base})
    sudo virsh vol-create-as default ${base} $size --format qcow2
    sudo virsh vol-upload --pool default ${base} ${base}

    size=$(stat -Lc%s ${master})
    sudo virsh vol-create-as default ${master} $size --format qcow2
    sudo virsh vol-upload --pool default ${master} ${master}

    size=$(stat -Lc%s ${worker})
    sudo virsh vol-create-as default ${worker} $size --format qcow2
    sudo virsh vol-upload --pool default ${worker} ${worker}

    sudo virsh define ./master.xml

    sudo virsh define ./worker.xml
    echo "Cluster created successfully use '$0 start' to start it"
}


cluster_start()
{
    sudo virsh start ${master}
    sudo virsh start ${worker}
    echo "You need to wait around 4-5 mins till cluster is in healthy state"
    echo "Use provided kubeconfig to check pods status before using this cluster"
}


cluster_stop()
{
    sudo virsh shutdown ${master}
    sudo virsh shutdown ${worker}
    echo "Cluster stopped"
}


cluster_delete()
{
    sudo virsh destroy ${master}
    sudo virsh destroy ${worker}

    sudo virsh undefine ${master}
    sudo virsh undefine ${worker}
    
    sudo virsh vol-delete --pool default ${master}
    sudo virsh vol-delete --pool default ${worker}
    sudo virsh vol-delete --pool default ${base}

    sudo virsh net-destroy ${net}
    sudo virsh net-undefine ${net}
}


usage()
{
    usage="$(basename "$0") [[create | start | stop | delete] | [-h]]

where:
    create - Create the cluster resources
    start  - Start the cluster
    stop   - Stop the cluster
    delete - Delete the cluster
    -h     - Usage message
    "

    echo "$usage"

}

main()
{
    if [ "$#" -ne 1 ]; then
        usage
        exit 0
    fi

    while [ "$1" != "" ]; do
        case $1 in
            create )           prerequisites
                               cluster_create
                               ;;
            start )            cluster_start
                               ;;
            stop )             cluster_stop
                               ;;
            delete )           cluster_delete
                               ;;
            -h | --help )      usage
                               exit
                               ;;
            * )                usage
                               exit 1
        esac
        shift
    done
}

main "$@"; exit
