# 10GbE networking

My 10GbE network is used for Ceph and Proxmox replication.

Enable jumbo frames. Ensure MTU is set to 9000


# CRS309-1G-8S+IN

My CRS309-1G-8S+IN runs SwOs, so it functions as a layer 2 switch.

**Does it support Jumbo Frames when in SwOs?**

> CRS312 device booted in SwOS by default supports jumbo frames up to 10218 bytes and you cannot change it to other values. It is the same for all CRS3xx devices booted in SwOS. -- [source](https://forum.mikrotik.com/viewtopic.php?t=154481#p763675)


So, yes.
