# Proxmox

I run Proxmox VE 7 in a 3 node cluster. Each node has 2x 2TB disk in ZFS RAID 1 (mirror). Each node also has access to NFS via my TrueNAS for shared storage. I've found running Ceph at home to be more trouble that its worth.

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
* Enable backports
* Remove pve-enterprise repo
* Disable IPV6
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


Add 

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
   
5. Storage > Poosl > NFS Dataset > Edit Perms

    Owner: nfs user
    Group: Wheel
    Remove other permissions
6. In proxmox: Datacenter > Storage > Add NFS

source: https://www.youtube.com/watch?v=zeOe26fw7lo

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
