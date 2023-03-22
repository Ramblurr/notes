# VyOS

I build my VyOS image using [ramblurr/vyos-modular](https://github.com/ramblurr/vyos-modular), the build config itself lives at [ramblurr/vyos-custom](https://github.com/ramblurr/vyos-custom/).

As of 2023-03 I am using VyOS Rolling (based on 1.4/Saggita).

The runtime configuration lines in [ramblurr/home-ops/vyos/router0](https://github.com/Ramblurr/home-ops/tree/main/vyos/router0).


## Bootstrap

* Get ISO from https://github.com/Ramblurr/vyos-custom
* Flash to USB and boot
* `install image` - follow prompts
* Reboot, get shell
* Connect to wifi temporarily to be able to run ansible playbook

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
