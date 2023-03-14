# Ceph

## Crush Rules

```
# replicated_nvme
ceph osd crush rule create-replicated replicated_nvme default osd nvme

# replicated_ssd
ceph osd crush rule create-replicated replicated_ssd default osd ssd

# replicated_all
ceph osd crush rule create-replicated replicated_all default osd
```


## Pools


### `nvme-ec`

NVME backed storage 2 storage + 1 parity. One drive can be lost.

```
pveceph pool create nvme-ec --crush_rule replicated_all --application rbd --erasure-coding k=2,m=1,device-class=nvme,failure-domain=osd
```

## Enable Ceph Dashboard on Proxmox

```
apt install ceph-mgr-dashboard

ceph mgr module enable dashboard

systemctl restart ceph-mgr@mill.service

# you might need to do this
systemctl reset-failed ceph-mgr@mill.service
systemctl restart ceph-mgr@mill.service

# create admin user for dashboard
# edit ./pw place your password in there
ceph dashboard ac-user-create  admin administrator -i ./pw
rm ./pw

# use cert from proxmox itself
ceph dashboard set-ssl-certificate mill -i /etc/pve/nodes/mill/pveproxy-ssl.pem
ceph dashboard set-ssl-certificate-key mill -i /etc/pve/nodes/mill/pveproxy-ssl.key

# remove services we don't use from the dashboard
ceph dashboard feature disable cephfs iscsi mirroring

systemctl restart ceph-mgr@mill.service

```

