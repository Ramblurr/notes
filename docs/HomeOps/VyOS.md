# VyOS

In 2023-03 I switched from my 5+ year old Unifi Security Gateway (USG) to a VyOS router built using a Lenovo Thinkcentre M720q with an aftermarket [10GbE Mellanox NIC](../10GbE) and [3d printed baffle](../10GbE/#lenovo-thinkcentre-m720q).

The newer "dream" line of Unifi routing products are very lack luster. Moving from the USG to a "dream" router would result in the loss of a bunch of features. So I finally decided to say goodbye to the fully unified unifi interface and built my own router.

As of 2023-03 I am using VyOS Rolling (based on 1.4/Saggita).

* **My VyOS config** gitops'd (sort of): [ramblurr/home-ops/vyos/router0](https://github.com/Ramblurr/home-ops/tree/main/vyos/router0).
* **Rolling ISO Build**: [ramblurr/vyos-custom](https://github.com/ramblurr/vyos-custom/)

#### Resources for M720q:

* [STH's Lenovo Thinkcentre/ThinkStation Tiny (Project TinyMiniMicro) Reference Thread](https://forums.servethehome.com/index.php?threads/lenovo-thinkcentre-thinkstation-tiny-project-tinyminimicro-reference-thread.34925/)
* [Lenovo M720Q Tiny router/firewall build with aftermarket 4 port NIC](https://smallformfactor.net/forum/threads/lenovo-m720q-tiny-router-firewall-build-with-aftermarket-4-port-nic.14793/)

## Bootstrap

* Get ISO from https://github.com/Ramblurr/vyos-custom/releases
* Flash to USB and boot
* `install image` - follow prompts
* Reboot, get shell
* Connect to wifi temporarily to be able to run the [ansible playbook](https://github.com/Ramblurr/home-ops/blob/01e529671be06e208757a7e097a28aaf4aac601d/ansible/run.yml#L2-L13)

    ```
    set interfaces wireless wlan0 type station
    set interfaces wireless wlan0 address dhcp
    set interfaces wireless wlan0 ssid XXX
    set interfaces wireless wlan0 security wpa passphrase 'XX'

    set service ssh port '22'
    ```


## Notes


### Diff previous configs

Show commits:

`run show system commit`


Compare a diff to the current:

`compare <N>`

Roll back to a diff

`rollback <N>`

Show container logs:

`show container log <container_name>`


Monitor firewall

```
monitor firewall name '*' | tee ~/fw.log | grep ...
```
