# 10GbE networking

My 10GbE network is used for Ceph and Proxmox replication.

## Lenovo Thinkcentre M720q

* **OS**: [VyOS Rolling](./VyOS.md)
* **Card:** Mellanox ConnectX-3 Pro CX322A SFP+

### Power Draw Energy Usage

[![power-draw-graph](m720q-power-draw.png)](m720q-power-draw.png)


## CRS309-1G-8S+IN

My CRS309-1G-8S+IN runs SwOs, so it functions as a layer 2 switch.

**Does the CRS309-1G-8S+IN support Jumbo Frames when in SwOs?**

> CRS312 device booted in SwOS by default supports jumbo frames up to 10218 bytes and you cannot change it to other values. It is the same for all CRS3xx devices booted in SwOS. -- [source](https://forum.mikrotik.com/viewtopic.php?t=154481#p763675)


So, yes. This is backed up my real-world experience too.


## Config Notes

* Enable jumbo frames, mtu=9000
  * Don't forget that every device on that vlan should have the same mtu.
