# Raspberry Pi

I use a lot of Raspberry PIs. I want bootstraping them from a fresh SD card to be quick and painless, but I want to preconfigure the network settings and the SSH authentication config from first boot.



## Raspbian First Boot Setup


1. Download `Raspberry Pi OS Lite` from https://www.raspberrypi.com/software/operating-systems/
2. Uncompress with `xz -d `
2. Use [`main.go`]({{ homeops_url }}/pi/main.go)  to get the mount point offsets 

    `go run main.go ./2023<imagename>`

3. Mount first mount point (this is /boot). Example (Your offsets may vary!):
  
      `mount -v -o offset=272629760,loop ./2022-09-22-raspios-bullseye-arm64-lite.img /mnt`

4. Inside the mountpoint add the following files
    * Setup userconf (see password manager for contents) - this creates the default user. It looks like this: `admin:$<PASSWORED HASH>`. The contents can be generated with [`password.py`]({{ homeops_url }}/pi/password.py)

    `vim /mnt/userconf`

5. Enable SSH on boot:

    `touch /mnt/ssh`

6. Copy [firstboot.sh]({{ homeops_url }}/pi/firstboot.sh) setup script:

    `cp firstboot.sh /mnt/firstboot.sh`

7. umount the boot partition
8. Then mount the second mount point (this is the root / partition)
9. Add [`firstboot.service`]({{ homeops_url }}/pi/firstboot.service) to `/mnt/lib/systemd/system/firstboot.service`
10. Enable the service:

    `cd /mnt/etc/systemd/system/multi-user.target.wants && ln -s /lib/systemd/system/firstboot.service .`

10. Edit `/mnt/etc/ssh/sshd_config`, add these lines:

     ```
         PasswordAuthentication no
         PermitRootLogin no
     ```

11. Setup `pi` user's SSH config. **Note!** Even if your user is not `pi`, put it in `/home/pi` anyways, the system will rename it on first boot.

    ```
    cd /mnt/home/pi
    mkdir .ssh
    chmod 0700 .ssh
    chown 1000:1000 .ssh
    # add your keys to .ssh/authorized_keys
    chown 1000:1000 .ssh/authorized_keys
    chmod 0600 .ssh/authorized_keys
    ```

Finally, umount the partition, then rename your `.img` file to something you'll recognize as being first-boot ready:

```bash
mv 2022-04-04-raspios-bullseye-armhf-lite.img 2022-04-04-raspios-bullseye-armhf-lite-firstboot-ready.img
```
