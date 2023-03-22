<h1 align="center">
    Home Ops
  <br />
  <br />
  <img src="https://i.imgur.com/IOkvNr4.png" width="200" height="200">
</h1>
<br />
<div align="center">

</div>

---

# :book:&nbsp; Overview

Welcome to my home operations documentation.

My [home-ops repo][0] contains the configuration for my bare-metal servers,
virtual machines, proxmox cluster, k8s cluster, dns, and more.

## :wrench:&nbsp; Tools

My primary tools for managing my infra:

| Tool      | Purpose                                     |
|-----------|---------------------------------------------|
| ansible   | configure the  servers                      |
| sops      | encrypt secrets on disk                     |
| terraform | Configuring a few cloud resources I rely on |
| flux      | For gitopsing my k8s cluster                |

## :computer:&nbsp; Hardware

### Compute and Storage

| Device                  | Count | OS Disk Size          | Data Disk Size                | Ram    | Purpose                                 |
|-------------------------|-------|-----------------------|-------------------------------|--------|-----------------------------------------|
| TrueNAS                 | 1     | 256GB NVMe            | 4x8TB ZFS, 8x12 TB ZFS        | 32GB   | shared storage                          |
| Intel NUC 10 i7FNH      | 4     | 256 GB NVMe (via USB) | 2TB NVMe Ceph, 2TB SDD Ceph   | 64GB   | Proxmox Nodes                           |
| Intel NUC 12 WSH i50002 | 1     | 256 GB                | 800TB NVMe Ceph, 2TB SSD Ceph | 64GB   | Proxmox Nodes                           |
| Raspberry PI 3 B        | 3     | 8GB MMC               | N/A                           | 512 MB | dns1, dns2, wan-lte-failover            |
| Raspberry PI 4          | 4     | 8GB MMC               | N/A                           | 2GB    | octoprint,  mycroft, zigbee2mqtt, pikvm |


### Networking

| Device                                                           | Count |
|------------------------------------------------------------------|-------|
| ISP Modem (1Gbit/100Mbit)                                        | 1     |
| Lenovo M720q VyOS router (i5-8400T, 8GB DDR4)                    | 1     |
| Unifi Switch 24 port POE                                         | 1     |
| Unifi Switch Pro 24 port                                         | 1     |
| Unifi Switch 8 port POE                                          | 2     |
| Unifi Switch Flex                                                | 2     |
| Unifi AP AC-lite                                                 | 2     |
| Unifi Access Point U6 Lite                                       | 1     |
| Unifi Cloud Key                                                  | 1     |
| Unifi In-Wall HD Access Point                                    | 1     |
| Mikrotik CRS309-1G-8S+IN 10GB Switch                             | 1     |
| Raspberry PI 3 B - [WAN2 failover - LTE](rpi-usg-4g-failover.md) | 1     |
| Raspberry PI 3 B - DNS nodes                                     | 2     |
| PiKVM Raspberry Pi 4 2GB                                         | 1     |
| TESMART Managed multiport KVM switch                             | 1     |

[:arrow_right: More info on my 10GbE setup](10GbE.md)


## :handshake:&nbsp; Thanks



Thanks to all the people who donate their time to the [Kubernetes @Home](https://discord.gg/k8s-at-home) Discord community. A lot of inspiration for my cluster comes from the people that have shared their clusters using the [k8s-at-home](https://github.com/topics/k8s-at-home) GitHub topic. Be sure to check out the [Kubernetes @Home search](https://nanne.dev/k8s-at-home-search/) for ideas on how to deploy applications or get ideas on what you can deploy.

And also a big thanks to the great community from the [Self-Hosted Podcast](https://www.jupiterbroadcasting.com/show/self-hosted/) (and Jupiter Broadcasting in general!). It's a friendly community of FOSS, Linux, Self-Hosting advocates.




### 🔏 License

Different parts of my [home-ops repo][0] have different licenses. Refer to the LICENSE file in the various subdirectories.

<div>Datacenter iconmade by <a href="https://creativemarket.com/eucalyp" title="Eucalyp">Eucalyp</a> from <a href="https://www.flaticon.com/" title="Flaticon">www.flaticon.com</a></div>

[0]: https://github.com/ramblurr/home-ops
