# Unifi USG LTE Failover

This document describes how to setup WAN failover for a Unifi USG to an LTE
network accesed via a 4G USB dongle plugged in to a Raspberry Pi.

Most of this guide is dedicated to configuring a Raspberry PI to act as a mini-router.

A few things of note:

* Despite using a LTE dongle, you won't get LTE speeds unless you use a PI with
  a gigabit NIC, which in October 2020 is only the RPI 4. [more info](https://www.jeffgeerling.com/blogs/jeff-geerling/getting-gigabit-networking)
  
* The PI and dongle are configured to NAT. This is ugly, but works for my use
  case. In a failover scenario, I'm ok with external access being cut.
  
  In theory it is possible to switch the dongle into modem mode
  [[0]](https://support.aa.net.uk/FireBrick_2700_with_4G_ZTE_MF823#Changing_the_ZTE_MF823_to_.27serial_modem.27_mode),
  but I haven't tried this. You'd need to alter this config anyways to remove the NAT on the PI.


## Hardware

* Unifi USG
* An extra switch (unmanaged, 100mb or 1gbit depending on if your PI supports gbit or not)
* Raspberry Pi
* ZTE MF823 LTE USB Dongle

## Software

* Unifi Controller
* TinyCoreLinux PiCore [download](http://tinycorelinux.net/ports.html) (v11 at time of writing)

## Address Space

* `192.168.0.1/24` for `usb0` - this is the default subnet on the MF823, your home LAN musn't overlap with this.
* <s>`192.168.73.1/24` for `usb0` - we will change the MF823 to use this subnet</s> editing the dongle's settings doesn't stick across reboots
* `192.168.12.1/24` for `eth0` - for USG<->PI

## Pre-setup - Test LTE dongle is working

Flash PiCore onto SD card

Boot PiCore, plug into ethernet

```
sudo /sbin/udhcp -v -i eth0 -x hostname:wan2 -p /var/run/udhcp.eth0.pid
ping 1.1.1.1
```

Insert dongle .. wait for it to settle ~60 seconds

Test

```
lsusb
```

While the dongle is booting it will show a red light and you will see
```
ID 19d2:1225
```

After it is ready the light will turn green and it will change to
```
ID 19d2:1405
```

Load the kernel module

```
modprobe cdc_ether
ifconfig -a
```

You should see `usb0`

Setup usb0

```
sudo /sbin/udhcp -v -i usb0 -x hostname:wan2 -p /var/run/udhcp.usb0.pid
ping 192.168.0.1
```

Use Socks proxy from your workstation to access MFG823's webui

```
# on workstation on same LAN as the pi
ssh -D 1337 tc@192.168.1.146
```

(192.168.1.146 was the ip on my local lan the pi got for eth0)

Use browser's socks settings to set socks 5 proxy 192.168.1.146 port 1337

Browse to 192.168.0.1 in browser, confirm the web ui is loading. If you have a
sim card in, you should see LTE network connection status.


## Setup of PI

Ok its working. Time to setup the router on the pi.

First, lets setup wifi on the pi. `eth0` will become the LAN port for the pi
router, but we need a headless/oob management channel, this will be over wifi.

SSH into the pi

Add ssh config and passwd to persistent config

```
mkdir ~/.ssh
vi ~/.ssh/authorized_keys
# paste your ssh key
sudo echo '/usr/local/etc/ssh' >> /opt/.filetool.lst 
sudo echo '/etc/shadow' >> /opt/.filetool.lst
sudo echo '/home/tc/.ssh/' >> /opt/.filetool.lst
filetool.sh -b
```

Download the wifi extension and reboot to load the module
```
tce-load -wi firmware-rpi-wifi.tcz
tce-load -wi wifi.tcz
sudo reboot
```

SSH again (using the key this time) and check for `wlan0`

```
iwconfig
```

Connect to your AP

```
sudo /usr/local/bin/wifi.sh 
```

Check `wlan0` connection

```
ifconfig wlan0
```

Configure auto wlan connect on system boot

```
sudo echo '/usr/local/bin/wifi.sh -a 2>&1 > /tmp/wifi.log' >> /opt/bootlocal.sh
filetool.sh -b
```

Reboot to test wlan0 auto config
```
sudo reboot
```

Quickly SSH in over the `eth0` interface, get the `wlan0` ip address and then ssh
back in over wifi.

From here on out I assume you are managing the pi over `wlan0`, as we will be
making changes to `eth0`.

NOTE: The following section is included, but does not seem to actually work. Everytime the dongle is rebooted, the settings are reverted.

> Next, let's change the subnet used by the ZTE MG 823 router so it doesn't use the common `192.168.0.1` subnet.
> 
> Ssh into the Pi, then telnet into the router
> 
> ```
> telnet 192.168.0.1
> # user: root
> # password: zte9x15
> ```
> 
> Edit the file at `/usr/zte/zte_conf/config/userseting_nvconfig.txt`
> 
> Change the values:
> 
> ```
> dhcpStart
> dhcpEnd
> lan_ipaddr
> lan_ipaddr_for_current
> ```
> 
> I assume in the rest of this that you are using the subnet `192.168.73.0/24`

Actually, we continue with `192.168.0.1`, since the above is not sticking.

Create `/opt/eth0.sh`

```
#!/bin/sh

sleep .5

sleep 1
if [ -f /var/run/udhcpc.eth0.pid ]; then
kill `cat /var/run/udhcpc.eth0.pid`
sleep 0.1
fi

ifconfig eth0 192.168.12.1 netmask 255.255.255.0 broadcast 192.168.12.255 up

sleep .1
sudo udhcpd /etc/eth0_udhcpd.conf &
```

Make it executable

```
chmod 775 /etc/eth0.sh
```

Create DHCP config for `eth0` in `/etc/eth0_udhcpd.conf`

```
start 192.168.12.100
end 192.168.12.200
interface eth0
option subnet 255.255.255.0
option router 192.168.12.1
option lease 43200
option dns 192.168.12.1
option domain wanfailover
```

Start and test dhcp server. You should see it listening on port udp 67.

```
sudo udhcpd /etc/eth0_udhcpd.conf
ps -ef | grep udhcpd
sudo netstat -anp | grep udhcpd
```

Create init script to manage `usb0` in `/etc/init.d/dhcp-usb0.sh`

Get file contets here [`dhcp-usb0.sh`](./dhcp-usb0.sh)

Make it executable

```
chmod 766 /etc/init.d/dhcp-usb0.sh
```

Create udev rule to auto connect to the `usb0` network  in `/etc/udev/rules.d/15-zte-mf823.rules`

```
SUBSYSTEM=="usb", ATTR{idProduct}=="1405", ATTR{idVendor}=="19d2", RUN+="/etc/init.d/dhcp-usb0.sh restart"
```

Reload udev rules

```
sudo udevadm control --reload-rules 
```

Unplug USB device, wait a few seconds, plug it back in. Check that `usb0` has an
ip in the `192.168.0.0/24` subnet.

Persist the config

```
sudo echo '/opt/eth0.sh' >> /opt/.filetool.lst
sudo echo '/etc/eth0_udhcpd.conf' >> /opt/.filetool.lst
sudo echo '/etc/init.d/dhcp-usb0.sh' >> /opt/.filetool.lst
sudo echo '/etc/udev/rules.d/15-zte-mf823.rules' >> /opt/.filetool.lst
sudo echo '/opt/eth0.sh &' >> /opt/bootlocal.sh
filetool.sh -b 
```

Reboot to test. You should see `eth0` with an ip address of `192.168.12.1`, and
`usb0` should be configured.

Enable ipv4 forwarding

```
sudo sysctl -w net.ipv4.ip_forward=1
sudo echo 'sysctl -w net.ipv4.ip_forward=1' >> /opt/bootlocal.sh
filetool.sh -b
```

Install dnsmasq and iptables

```
tce-load -wi dnsmasq
tce-load -wi iptables
```

Enable NAT

```
sudo iptables -t nat -A POSTROUTING -o usb0 -j MASQUERADE
```

Make it persistent

```
sudo echo 'iptables -t nat -A POSTROUTING -o usb0 -j MASQUERADE' >> /opt/bootlocal.sh
sudo echo 'dnsmasq' >> /opt/bootlocal.sh
```

Finally, add a little script to remove the wifi default gateway. Without this,
the wifi script will take over the default gateway. The actual default gateway
is set by our usb udev script.

`/opt/fix-gw.sh`

```
#!/bin/sh

gw=$(route -n|grep "UG"|grep -v "UGH"|cut -f 10 -d " ")

if [ ! -z "$gw" ]; then
  route del default gw "$gw"
fi
```

Save it

```
chmod 777 /opt/fix-gw.sh
sudo echo '/opt/fix-gw.sh' >> /opt/.filetool.lst
sudo echo '/opt/fix-gw.sh' >> /opt/bootlocal.sh
filetool.sh -b
```

Do a final reboot. Connect your pi to an empty switch, connect your laptop to the switch. You should have internet via the LTE dongle, verify with

```
curl https://iconfig.co/json | jq
```

You should see your LTE provider's info.

## Unifi USG WAN failover configuration

This is a small cluster-f*** depending on your Controller version and whether
you have the old or new settings interface. In short, any docs you read about
setting the "Port Remapping" feature are out of date since at least 2019.

You must not be using the WAN2 port for LAN traffic.

Assuming the old, non beta (as of Oct 2020) settings UI you can follow what is
below.

Are you from the future where the new beta UI is no longer beta, and the old UI
is gone? Good luck.


1. Create a WAN2 network

    Settings -> Networks -> [ + Create New Network ]
    Purpose: WAN
    Network Group: WAN2
    Load Balancing: dropdown, choose
        "Failover Only" to use the WAN2 port only if WAN has failed
        
2. Assign the USG's port to the WAN2 network

    Devices -> USG -> Ports tab -> [ Configure interfaces ]
    
    Port WAN2/LAN2 Network: WAN2
    
    Apply
    
Wait for the USG to re-provision.

Test it by sshing into the USG and execute:

```
ip addr # check eth2
show load-balance status
show load-balance watchdog
```

That's it. Unplug your WAN1, watch it failover to WAN2. Plug WAN1 back in and see WAN2 recover.

In case you're wondering: you do get email alerts and alerts in the Controller
UI whenever a WAN transition happens.

## Resources

- hacking MF 823's UI - https://www.development-cycle.com/2017/04/27/zte-mf823-inside/
- device info https://wiki.archlinux.org/index.php/ZTE_MF_823_(Megafon_M100-3)_4G_Modem
- tinycore ip router setup https://iotbytes.wordpress.com/configure-microcore-tiny-linux-as-router/
