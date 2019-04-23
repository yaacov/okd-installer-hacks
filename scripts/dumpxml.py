from __future__ import print_function
import sys
import libvirt
from xml.dom import minidom

# dumpxml
def dumpxml(filename, xml):
    with open(filename, 'w') as the_file:
        the_file.write(xml.toprettyxml(indent='', newl=''))

# ---------------------

conn = libvirt.open('qemu:///system')
if conn == None:
    print('Failed to open connection to qemu:///system', file=sys.stderr)
    exit(1)

# ---------------------

# discover default pool
pools = conn.listAllStoragePools(0)
pool = [i for i in pools if 'default' in i.name()][0]

# discover base volume name
stgvols = pool.listVolumes()
base = [i for i in stgvols if 'base' in i][0]

# discover test network
networks = conn.listNetworks()
net = [conn.networkLookupByName(i) for i in networks if 'test' in i][0]

# discover vms
domainIDs = conn.listDomainsID()
master =  [conn.lookupByID(i) for i in domainIDs if 'master' in conn.lookupByID(i).name()][0]
worker =  [conn.lookupByID(i) for i in domainIDs if 'worker' in conn.lookupByID(i).name()][0]

# ---------------------

# edit master
raw_xml = master.XMLDesc(0)
master_xml = minidom.parseString(raw_xml)
domainTypes = master_xml.getElementsByTagName('type')
domainTypes[0].setAttribute('machine', 'pc')

# edit worker
raw_xml = worker.XMLDesc(0)
worker_xml = minidom.parseString(raw_xml)
domainTypes = worker_xml.getElementsByTagName('type')
domainTypes[0].setAttribute('machine', 'pc')

# ---------------------

# write names
with open('pool', 'w') as the_file:
    the_file.write(pool.name())
with open('base', 'w') as the_file:
    the_file.write(base)
with open('net', 'w') as the_file:
    the_file.write(net.name())
with open('master', 'w') as the_file:
    the_file.write(master.name())
with open('worker', 'w') as the_file:
    the_file.write(worker.name())

# dumpxml
raw_xml = pool.XMLDesc(0)
pool_xml = minidom.parseString(raw_xml)
dumpxml('pool.xml', pool_xml)

raw_xml = net.XMLDesc(0)
net_xml = minidom.parseString(raw_xml)
dumpxml('net.xml', net_xml)

dumpxml('master.xml', master_xml)
dumpxml('worker.xml', worker_xml)

# ---------------------

conn.close()
exit(0)

