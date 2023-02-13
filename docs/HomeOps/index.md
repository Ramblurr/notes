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

Welcome to my home operations repo.

This repo contains the configuration for my bare-metal servers, virtual
machines, containers, and proxmox cluster.

## :wrench:&nbsp; Tools

My primary tools for managing my infra:

| Tool     | Purpose                              |
| -------- | ------------------------------------ |
| ansible  | configure the  servers         |
| sops     | encrypt secrets on disk              |

## :computer:&nbsp; Hardware

### Compute and Storage

| Device              | Count | OS Disk Size | Data Disk Size             | Ram    | Purpose        |
|---------------------|-------|--------------|----------------------------|--------|----------------|
| TrueNAS             | 1     | 256GB NVMe   | 4x8TB ZFS, 8x12 TB ZFS     | 32GB   | shared storage |
| Intel NUCNUC10i7FNH | 3     | -            | 2TB NVMe, 2TB SATA SDD ZFS | 64GB   | Proxmox Nodes  |
| Raspberry PI 3 B    | 2     | 8GB MMC      | N/A                        | 512 MB | dns1 and dns2  |


### Networking

| Device                                                            | Count |
|-------------------------------------------------------------------|-------|
| Unifi Security Gateway (USG)                                      | 1     |
| Unifi Switch 24 port POE                                          | 1     |
| Unifi Switch Pro 24 port POE                                      | 1     |
| Unifi Switch 8 port POE                                           | 2     |
| Unifi Switch Flex                                                 | 2     |
| Unifi AP AC-lite                                                  | 2     |
| Unifi Access Point U6 Lite                                        | 1     |
| Unifi Cloud Key                                                   | 1     |
| ISP Modem                                                         | 1     |
| Raspberry PI 3 B - [WAN2 failover - LTE](rpi-usg-4g-failover.md) | 1     |
| Mikrotik CRS309-1G-8S+IN 10GB Switch                              | 1     |
| PiKVM Raspberry Pi 4 2GB                                          | 1     |
| TESMART Managed multiport KVM switch                              | 1     |


#### 10GbE Network Hardware
| Device                               | Connection        | Card                  |
|--------------------------------------|-------------------|-----------------------|
| USW-24                               | SFP+              | built-in              |
| USW-Pro-24                           | SFP+              | built-in              |
| NAS                                  | SFP+              | Intel x520            |
| Mikrotik CRS309-1G-8S+IN 10GB Switch | builtin           |                       |
| NUC1                                 | SFP+/Thunderbolt3 | Sonnet ‎SOLO10G-SFP-T3 |
| NUC2                                 | SFP+/Thunderbolt3 | Sonnet ‎SOLO10G-SFP-T3 |
| NUC3                                 | SFP+/Thunderbolt3 | Sonnet ‎SOLO10G-SFP-T3 |


## :handshake:&nbsp; Thanks

Many thanks to the [Self-Hosted](https://selfhosted.show/) community ([Discord](https://discord.gg/U3Gvr54VRp)).

<div>Datacenter iconmade by <a href="https://creativemarket.com/eucalyp" title="Eucalyp">Eucalyp</a> from <a href="https://www.flaticon.com/" title="Flaticon">www.flaticon.com</a></div>
