# Proxmox

I run Proxmox VE 7 in a 3 node cluster. Each node has 2x 2TB disk in ZFS RAID 1 (mirror). Each node also has access to NFS via my TrueNAS for shared storage. I've found running Ceph at home to be more trouble that its worth.

## Install With External Boot Drive

Assumed setup:

* External NVME-via-USB boot disk
* Internal M.2 NVME for ceph
* Internal SATA SSD for ceph

Ensure the internal disks are wiped, any remnants of a GPT partition table or
ZFS will cause problems. See the section about wiping disks.

When installing:

* Choose external disk as the install disk
* Use ZFS RAID-0
* English keyboard layout
* Use mgmt vlan as the network config
* Use fully qualified domain as the hostname

After install, setup zfs encryption:

[source](https://forum.proxmox.com/threads/encrypting-proxmox-ve-best-methods.88191/#post-387731)

* Use F10 to PXE boot from `Ubuntu 22.04`
* Follow create an encrypted pool ([source](https://gist.github.com/yvesh/ae77a68414484c8c79da03c4a4f6fd55))

    ```
    # Import the old 
    zpool import -f -NR /tmp rpool
    
    # check Status
    zpool status

    # Make a snapshot of the current one
    zfs snapshot -r rpool/ROOT@copy

    # Send the snapshot to a temporary root
    zfs send -R rpool/ROOT@copy | zfs receive rpool/copyroot

    # Destroy the old unencrypted root
    zfs destroy -r rpool/ROOT

    # Create a new zfs root, with encryption turned on
    zfs create -o encryption=aes-256-gcm -o keyformat=passphrase rpool/ROOT
    
    # enter passphrase

    # Copy the files from the copy to the new encrypted zfs root
    zfs send -R rpool/copyroot/pve-1@copy | zfs receive -o encryption=on rpool/ROOT/pve-1

    # Set the Mountpoint
    zfs set mountpoint=/ rpool/ROOT/pve-1
    
    # Check which ZFS pools are encrypted
    zfs get encryption
    
    # Enable autotrim
    zpool set autotrim=on rpool
    
    # Enable compression
    zfs set recordsize=1M compression=zstd-3 rpool


    # Export the pool again, so you can boot from it
    zpool export rpool
    
    # Reboot into PVE
    
    # Cleanup old root
    zfs destroy -r rpool/copyroot

    # Check which ZFS pools are encrypted
    zfs get encryption
    
    # Don't forget to run the rmblr.proxmox_setup role to enable zfs decryption at boot over ssh

    ```



After boot:

1.Run setup playbook in bootstrap mode
    ```
    ansible-playbook run.yml --tags proxmox-setup --limit peirce.mgmt.socozy.casa -e '{"proxmox_acme_enabled": false, "proxmox_upgrade": true }' --ask-pass
    ```
3. `systemctl restart networking`
4. `systemctl reboot`
5. Join node to cluster (see below)

## Wiping disks for clean install

1. PXE boot into System Rescue CD
2. Use gparted to
  - delete all partitions
  - format with "clear"
  - create a fresh gpt partition
3. Reboot and PXE boot into Proxmox VE to continue the install

## Reinstall A Node

Goal: Reinstall Proxmox on a node and reintroduce it to the cluster with the *same* name and network settings.

Relevant docs: https://pve.proxmox.com/pve-docs/pve-admin-guide.html#_remove_a_cluster_node

```
# 1. poweroff node
# 2. delete the node (from another node)
pvecm delnode <NODE NAME>
# 3. reinstall proxmox on the node
# 4. ssh into the node you want to rejoin
pvecm add <ANOTHER-NODE-IP> --use_ssh 1 --link0 address=<MY-DATA-IP>

# 5. update certs
pvecm updatecerts

# 6. munge known hosts
#    from every  node (including the new one), run `ssh <othernode>` and delete the corresponding lines,
#    until you don't get any more known host errors.

# 7. If the old node was part of the ceph cluster then you need to scrube any
#    mention of that node from /etc/pve/ceph.conf



```

### Install checklist

From Proxmox VE 7 the install is straightforward, just choose your settings and go.

When prompted for the hostname, use a FQDN.

    # yes
    mynode.mydomain.com
    
    # no
    mynode

### Post-install checklist

This checklist is automated with my [`rmblr-proxmox-setup` role]({{ homeops_url }}/ansible/roles/local/rmblr-proxmox-setup/tasks/main.yml) (it might be more up to date than this list!).

* Install pve-no-subscription repo
* Configure the network interfaces
* Install CPU microcode to mitigate CPU bugs
* Enable backports
* Remove pve-enterprise repo
* Disable IPV6
* Disable Wifi and Bluetooth
* Setup dropbear-initramfs to provide root zfs encryption key over ssh at boot time
* Setup encrypted ZFS data storage for guests
* Install my admin tools
* Install acme plugin and cloudflare DNS configuration
* Install borg+borgmatic and configure backups with Healthchecks


### Configuring Cluster

1. Install Proxmox VE on three nodes, use ZFS as the fs.
2. Run the bootstrap ansible role
3. From one node create the cluster
4. Join the other nodes to the cluster
5. Run the bootstrap ansible role again, because the joined nodes lose their ACME config, this re-adds it so you have valid certs


### Replicating VMs

From the *Datacenter* menu, go to *Replication* and add manual replication settings for each vm


### Replacing a ZFS Boot Disk

You might need to replace a proxmox boot disk that is in the ZFS pool.

You should note that the Proxmox partition convention is:

    Partition 1 = BIOS Boot
    Partition 2 = EFI Boot
    Partition 3 = ZFS
    
    
This is the replacement procedure

Given `/dev/sda` and `/dev/sdb`. `/dev/sdb` is the disk you want to replace.

Pull your `/dev/sdb` from the chassis. Insert your new disk.

Now `/dev/sdb` is a fresh disk that needs to join the pool


Copy the partition table from `/dev/sda` to `/dev/sdb` and initialize new GUIDS for the partitions.

```bash
# WARNING the order of these flags is very important. If not careful you'll wipe your good drive.
sgdisk /dev/sda -R /dev/sdb
sgdisk -G /dev/sdb
```

Next you should replace the bad disk in the ZFS pool. Get the id of the old disk using `zpool status` it should be marked as offline.

```bash
# Important, use partition 3!
zpool replace -f rpool <OLD DISK> /dev/disk/by-id/sdb-part3
```

Now ZFS will start resilvering. You can check the status of the resilver process with:

```bash
zpool status -v rpool
```

After resilvering is complete, we need to install the boot environment on the EFI partition (partition # 2).

```bash
proxmox-boot-tool format /dev/sdb2
proxmox-boot-tool init /dev/sdb2
proxmox-boot-tool refresh
```

This refreshes the boot environments on all EFI/BIOS boot partitions in the
system. All disks are now bootable.

### Tailscale in a container:

To run tailscale succesfully in an LXC container you must add the following to the container's config:

    lxc.cgroup.devices.allow: c 10:200 rwm
    lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file

### Setting up NFS Share

Use an NFS share for storing snippets, isos, etc

1. Create dataset in freenas
2. Create NFS share in freenas
   Add authorized IPs
3. Create nfs user with dataset as home dir
   Set wheel as the primary group for the user
   Disable password
4. Edit the nfs share
   MapallUser -> nfs user
   
5. Storage > Pools > NFS Dataset > Edit Perms

    Owner: nfs user
    Group: Wheel
    Remove other permissions
6. In proxmox: Datacenter > Storage > Add NFS

source: https://www.youtube.com/watch?v=zeOe26fw7lo

### Single NIC on Trunk Port but using VLAN

```
auto lo
iface lo inet loopback

iface enp60s0 inet manual

auto vmbr0
iface vmbr0 inet manual
    bridge-ports enp60s0
    bridge-stp off
    bridge-fd 0
    bridge-vlan-aware yes
    bridge-vids 2-4094
    bridge-pvid 1

auto vmbr0.11 
iface vmbr0.11 inet static
    address 10.9.10.21/23
    gateway 10.9.10.1
```

### Multiple VLANs with Single NIC

Goals:

* proxmox web ui and ssh port is on vlan 10
* VMs and LXC containers assigned addreses on vlan 20


Edit `/etc/network/interfaces`

```
auto lo
iface lo inet loopback

auto eno1
iface eno1 inet static
        address  0.0.0.0
        netmask  0.0.0.0

auto eno1.10
iface eno1.1 inet static
        address  0.0.0.0
        netmask  0.0.0.0

auto eno1.20
iface eno1.2 inet static
        address  0.0.0.0
        netmask  0.0.0.0

auto vmbr10
iface vmbr10 inet static
	address 10.8.10.10/24
	gateway 10.8.10.1
        bridge_ports eno1.10
        bridge_stp off
        bridge_fd 0

auto vmbr20
iface vmbr20 inet static
        address  10.8.20.5/24
        bridge_ports eno1.20
        bridge_stp off
        bridge_fd 0
```


### Installing Proxmox as a VM in FreeNAS

When you create the proxmox virtual machine and boot it the boot process will fail after obtaining a dhcp lease

```
Starting a root shell on tty3
\nInstallation aborted - unable to continue 
```

To fix this, use the provided shell to
```
chmod 1777 /tmp   
apt update
apt upgrade
Xorg -configure   
mv /xorg.conf.new /etc/X11/xorg.conf
vim /etc/X11/xorg.conf
# change the Screen Driver to "fbdev"
startx
```

Then the installer will start. Install. Then X will exit. Power off the VM. Remove the cdrom device.

### Import a cloudimg 

This has been wrapped in the ansible role `proxmox-template`.

```
wget https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img
qm create 101 --memory 1024 --net0 virtio,bridge=vmbr20
qm importdisk 101 ./focal-server-cloudimg-amd64.img local-zfs
qm set 101 --scsihw virtio-scsi-pci --scsi0 local-zfs:vm-101-disk-0
qm set 101 --ide2 local-zfs:cloudinit
qm set 101 --boot c --bootdisk scsi0
qm set 101 --serial0 socket --vga serial0
qm set 101 --cipassword test --ciuser ubuntu
qm set 101 --ipconfig0 ip=dhcp
qm set 101 -agent 1

qm template 101

qm clone 101 201 --name dagon 
qm set 201 --memory 8192
qm set 201 -agent 1
qm set 201 --ipconfig0 ip=dhcp
qm set 201 --net0 virtio,bridge=vmbr0,tag=10,firewall=1
qm set 201 --net1 virtio,bridge=vmbr0,tag=20,firewall=1
qm set 201 --cicustom "user=snippets:snippets/user-data"
qm resize 201 scsi0 20G
cat << EOF > /etc/pve/firewall/201.fw
[OPTIONS]
enable: 1
[RULES]
GROUP allowssh
EOF


qm clone 101 202 --name hydra
qm set 202 --memory 8192
qm set 202 -agent 1
qm set 202 --ipconfig0 ip=dhcp
qm set 202 --net0 virtio,bridge=vmbr0,tag=10
qm set 202 --cicustom "user=snippets:snippets/user-data"
qm resize 202 scsi0 20G

qm clone 101 203 --name deepone
qm set 203 --memory 8192
qm set 203 -agent 1
qm set 203 --ipconfig0 ip=dhcp
qm set 203 --net0 virtio,bridge=vmbr0,tag=10
qm set 203 --cicustom "user=snippets:snippets/user-data"
qm resize 203 scsi0 20G


qm set 201 --sshkey ~/casey.pub 
```

https://pve.proxmox.com/wiki/Cloud-Init_Support


### Custom cloud init userdata


1. Go to Storage View -> Storage -> Add -> Directory
2. Give it an ID such as snippets, and specify any path on your host such as /srv/snippets
3. Under Content choose Snippets and de-select Disk image
4. Upload (scp/rsync/whatever) your user-data, meta-data, network-config files to your proxmox server in /srv/snippets/snippets/

```
qm set XXX --cicustom "user=snippets:snippets/user-data"

OR 

qm set XXX --cicustom "user=snippets:snippets/user-data,network=snippets:snippets/network-config,meta=snippets:snippets/meta-data"

qm cloudinit dump 204 user
```

If you following the "Import a cloudimg" above, the vm should already have a cloudinit drive.


https://gist.github.com/aw/ce460c2100163c38734a83e09ac0439a


### Remove all containers


    for i in $(pct list | awk '/\d/{print $1}'); do pct destroy "$i" -purge ; done


## Deploy fedora coreos template

fedora core os on proxmox

on workstation:
```bash
cd workspace/
coreos-installer download -s stable -p qemu -f qcow2.xz --decompress -C .
scp fedora-coreos-34.20210904.3.0-qemu.x86_64.qcow2 PROXMOX_HOST:
```

on proxmox host:
1. (in ui) create a vm and remove the default disks
2. import the image

   ```bash
   qm importdisk 9996 ./fedora-coreos-34.20210904.3.0-qemu.x86_64.qcow2 local-zfs
   qm set 9996 --scsi0 local-zfs:vm-9996-disk-1
   qm set 9996 --boot order=scsi0
   qm template 9996
   ```
3. create vms from the template, then for each one:

   ```bash
   vi /etc/pve/qemu-server/VMID.conf
   add:
     args: -fw_cfg name=opt/com.coreos/config,file=/mnt/pve/mali/snippets/server-1.ign
   ```

4. make sure the snippet file exists, and edit the file for the corresponding server+client number


## ZFS Cannot import rpool at boot

source0: https://www.thomas-krenn.com/en/wiki/ZFS_cannot_import_rpool_no_such_pool_available_-_fix_Proxmox_boot_problem
source1: https://forum.proxmox.com/threads/failed-to-import-rpool-on-bootup-after-system-update.37884/


### Problem 

The Proxmox system does not boot because the rpool created by Proxmox could not be imported because it was not found.

```
Command: /sbin/zpool import -N "rpool"
Message: cannot import 'rpool' : no such pool available
Error: 1
Failed to import pool 'rpool'.
Manually import the pool and exit.
```

### Cause

The disks are not fully addressable at the time of the ZFS pool import and
therefore the rpool cannot be imported.[1]​ 

### Solution

Manually import the zpool with the name rpool and then boot the system again
with exit. Afterwards you can change the ZFS defaults, so that before and after
the mounting of the ZFS pool 5 seconds will be waited.

```
# ZFS rpool is imported manually

zpool import -N rpool
exit

# ZFS defaults are changed

nano etc/default/zfs

# ZFS sleep parameters are set to 5

ZFS_INITRD_PRE_MOUNTROOT_SLEEP='5'
ZFS_INITRD_POST_MODPROBE_SLEEP='5'

# initramfs is updated

update-initramfs -u
```

Afterwards you can reboot the system with reboot and observe the boot process.
Before and after the import of the rpool now up to 5 seconds are waited, so
that the system can start now properly. 


## Terraform Provider for Proxmox

Configure the terraform api user:

```sh
pveum role add Terraform -privs "Datastore.AllocateSpace Datastore.Audit Pool.Allocate Sys.Audit VM.Allocate VM.Audit VM.Clone VM.Config.CDROM VM.Config.CPU VM.Config.Cloudinit VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Monitor VM.PowerMgmt"
pveum user add terraform@pve --password changeme
pveum aclmod / -user terraform@pve -role Terraform
```
