# Primary Workstation

## Hardware

* Original Build Date: Spring 2023
* Chassis: SilverStone SST-RM51 (with mounting rails SilverStone RMS05-22)
* Motherboard: ASUS ProArt X670E-Creator
* RAM: 64GB, Kingston DDR5-6000 2x32 KF560C36BBEK2-64
* PSU: Seasonic Vertex GX 1000 W ATX
* CPU: AMD Ryzen 9 7950X3D 4.2 GHz 16-Core
* GPU: MSI GeForce RTX 4090 SUPRIM X – 24GB
* CPU Cooler: Noctua NH-D15
* Chassis Fans:
    * 1x Noctua NF-A14 PWM 140mm
    * 2x Noctua NF-A8 PWM 80mm
* Monitors:
    * Dell 27" S2722QC
    * Samsung 49" Super ultra wide C49RG9x
* OS: [NixOS][os]

[os]: https://github.com/ramblurr/nixcfg

## Build Notes

* The GPU graphics card has a a length of  336mm, which fits in the chassis without any adapters
* The workstation is rackmounted in my [server cabinet](./NetworkCabinet)
* I have a 10m Digitus DisplayPort and HDMI cables, plus a 10m USB C/USB 3.1 cable running from the rack to my desk where it is connected to a 7 port USB C 3.2 Gen 2 Hub
* IOMMU group listing:
    ```
    # produced with https://gist.github.com/r15ch13/ba2d738985fce8990a4e9f32d07c6ada
    Group 0:	[1022:14da]     00:01.0  Host bridge                              Device 14da
    Group 1:	[1022:14db] [R] 00:01.1  PCI bridge                               Device 14db
    Group 2:	[1022:14db] [R] 00:01.2  PCI bridge                               Device 14db
    Group 3:	[1022:14da]     00:02.0  Host bridge                              Device 14da
    Group 4:	[1022:14db] [R] 00:02.1  PCI bridge                               Device 14db
    Group 5:	[1022:14da]     00:03.0  Host bridge                              Device 14da
    Group 6:	[1022:14da]     00:04.0  Host bridge                              Device 14da
    Group 7:	[1022:14da]     00:08.0  Host bridge                              Device 14da
    Group 8:	[1022:14dd] [R] 00:08.1  PCI bridge                               Device 14dd
    Group 9:	[1022:14dd] [R] 00:08.3  PCI bridge                               Device 14dd
    Group 10:	[1022:790b]     00:14.0  SMBus                                    FCH SMBus Controller
        [1022:790e]     00:14.3  ISA bridge                               FCH LPC Bridge
    Group 11:	[1022:14e0]     00:18.0  Host bridge                              Device 14e0
        [1022:14e1]     00:18.1  Host bridge                              Device 14e1
        [1022:14e2]     00:18.2  Host bridge                              Device 14e2
        [1022:14e3]     00:18.3  Host bridge                              Device 14e3
        [1022:14e4]     00:18.4  Host bridge                              Device 14e4
        [1022:14e5]     00:18.5  Host bridge                              Device 14e5
        [1022:14e6]     00:18.6  Host bridge                              Device 14e6
        [1022:14e7]     00:18.7  Host bridge                              Device 14e7
    Group 12:	[10de:2684] [R] 01:00.0  VGA compatible controller                AD102 [GeForce RTX 4090]
        [10de:22ba]     01:00.1  Audio device                             AD102 High Definition Audio Controller
    Group 13:	[144d:a80a] [R] 02:00.0  Non-Volatile memory controller           NVMe SSD Controller PM9A1/PM9A3/980PRO
    Group 14:	[1022:43f4] [R] 03:00.0  PCI bridge                               Device 43f4
    Group 15:	[1022:43f5] [R] 04:00.0  PCI bridge                               Device 43f5
    Group 16:	[1022:43f5] [R] 04:08.0  PCI bridge                               Device 43f5
        [1022:43f4] [R] 06:00.0  PCI bridge                               Device 43f4
        [1022:43f5] [R] 07:00.0  PCI bridge                               Device 43f5
        [1022:43f5] [R] 07:01.0  PCI bridge                               Device 43f5
        [1022:43f5] [R] 07:02.0  PCI bridge                               Device 43f5
        [1022:43f5] [R] 07:03.0  PCI bridge                               Device 43f5
        [1022:43f5] [R] 07:04.0  PCI bridge                               Device 43f5
        [1022:43f5] [R] 07:08.0  PCI bridge                               Device 43f5
        [1022:43f5]     07:0c.0  PCI bridge                               Device 43f5
        [1022:43f5]     07:0d.0  PCI bridge                               Device 43f5
        [14c3:0616] [R] 08:00.0  Network controller                       MT7922 802.11ax PCI Express Wireless Network Adapter
        [8086:15f3] [R] 09:00.0  Ethernet controller                      Ethernet Controller I225-V
        [1d6a:94c0] [R] 0a:00.0  Ethernet controller                      AQC113CS NBase-T/IEEE 802.3bz Ethernet Controller [AQtion]
        [8086:1136] [R] 0c:00.0  PCI bridge                               Thunderbolt 4 Bridge [Maple Ridge 4C 2020]
        [8086:1136] [R] 0d:00.0  PCI bridge                               Thunderbolt 4 Bridge [Maple Ridge 4C 2020]
        [8086:1136]     0d:01.0  PCI bridge                               Thunderbolt 4 Bridge [Maple Ridge 4C 2020]
        [8086:1136]     0d:02.0  PCI bridge                               Thunderbolt 4 Bridge [Maple Ridge 4C 2020]
        [8086:1136]     0d:03.0  PCI bridge                               Thunderbolt 4 Bridge [Maple Ridge 4C 2020]
        [8086:1137] [R] 0e:00.0  USB controller                           Thunderbolt 4 NHI [Maple Ridge 4C 2020]
        [8086:1138] [R] 3a:00.0  USB controller                           Thunderbolt 4 USB Controller [Maple Ridge 4C 2020]
    USB:		[1d6b:0002]		 Bus 001 Device 001                       Linux Foundation 2.0 root hub 
    USB:		[1d6b:0003]		 Bus 002 Device 001                       Linux Foundation 3.0 root hub 
        [1022:43f7] [R] 67:00.0  USB controller                           Device 43f7
    USB:		[0b05:19af]		 Bus 003 Device 005                       ASUSTek Computer, Inc. AURA LED Controller 
    USB:		[0489:e0e2]		 Bus 003 Device 003                       Foxconn / Hon Hai Wireless_Device 
    USB:		[20b1:0008]		 Bus 003 Device 008                       XMOS Ltd HIFI DSD 
    USB:		[046d:c07e]		 Bus 003 Device 014                       Logitech, Inc. G402 Gaming Mouse 
    USB:		[3496:0006]		 Bus 003 Device 013                       Keyboardio Model 100 
    USB:		[046d:0aaf]		 Bus 003 Device 012                       Logitech, Inc. Yeti X 
    USB:		[046d:085b]		 Bus 003 Device 011                       Logitech, Inc. Logitech Webcam C925e 
    USB:		[05e3:0610]		 Bus 003 Device 010                       Genesys Logic, Inc. Hub 
    USB:		[2109:2822]		 Bus 003 Device 007                       VIA Labs, Inc. USB2.0 Hub 
    USB:		[2109:2822]		 Bus 003 Device 006                       VIA Labs, Inc. USB2.0 Hub 
    USB:		[1a40:0101]		 Bus 003 Device 004                       Terminus Technology Inc. Hub 
    USB:		[1a40:0101]		 Bus 003 Device 002                       Terminus Technology Inc. Hub 
    USB:		[1d6b:0002]		 Bus 003 Device 001                       Linux Foundation 2.0 root hub 
    USB:		[05e3:0612]		 Bus 004 Device 004                       Genesys Logic, Inc. Hub 
    USB:		[2109:0822]		 Bus 004 Device 003                       VIA Labs, Inc. USB3.1 Hub 
    USB:		[2109:0822]		 Bus 004 Device 002                       VIA Labs, Inc. USB3.1 Hub 
    USB:		[1d6b:0003]		 Bus 004 Device 001                       Linux Foundation 3.0 root hub 
        [1022:43f6] [R] 68:00.0  SATA controller                          Device 43f6
    Group 17:	[1022:43f5]     04:0c.0  PCI bridge                               Device 43f5
        [1022:43f7] [R] 69:00.0  USB controller                           Device 43f7
    USB:		[0bda:5411]		 Bus 005 Device 004                       Realtek Semiconductor Corp. RTS5411 Hub 
    USB:		[2109:0101]		 Bus 005 Device 003                       VIA Labs, Inc. USB 2.0 BILLBOARD 
    USB:		[2109:2813]		 Bus 005 Device 002                       VIA Labs, Inc. VL813 Hub 
    USB:		[1d6b:0002]		 Bus 005 Device 001                       Linux Foundation 2.0 root hub 
    USB:		[058f:8468]		 Bus 006 Device 004                       Alcor Micro Corp. Mass Storage Device 
    USB:		[0bda:8153]		 Bus 006 Device 005                       Realtek Semiconductor Corp. RTL8153 Gigabit Ethernet Adapter 
    USB:		[0bda:0411]		 Bus 006 Device 003                       Realtek Semiconductor Corp. Hub 
    USB:		[2109:0813]		 Bus 006 Device 002                       VIA Labs, Inc. VL813 Hub 
    USB:		[1d6b:0003]		 Bus 006 Device 001                       Linux Foundation 3.0 root hub 
    Group 18:	[1022:43f5]     04:0d.0  PCI bridge                               Device 43f5
        [1022:43f6] [R] 6a:00.0  SATA controller                          Device 43f6
    Group 19:	[1022:14de] [R] 6b:00.0  Non-Essential Instrumentation [1300]     Phoenix PCIe Dummy Function
    Group 20:	[1022:1649]     6b:00.2  Encryption controller                    VanGogh PSP/CCP
    Group 21:	[1022:15b6] [R] 6b:00.3  USB controller                           Device 15b6
    USB:		[1d6b:0002]		 Bus 007 Device 001                       Linux Foundation 2.0 root hub 
    USB:		[1d6b:0003]		 Bus 008 Device 001                       Linux Foundation 3.0 root hub 
    Group 22:	[1022:15b7] [R] 6b:00.4  USB controller                           Device 15b7
    USB:		[1d6b:0003]		 Bus 010 Device 001                       Linux Foundation 3.0 root hub 
    USB:		[1d6b:0002]		 Bus 009 Device 001                       Linux Foundation 2.0 root hub 
    Group 23:	[1022:15e3]     6b:00.6  Audio device                             Family 17h/19h HD Audio Controller
    Group 24:	[1022:15b8] [R] 6c:00.0  USB controller                           Device 15b8
    USB:		[1d6b:0002]		 Bus 011 Device 001                       Linux Foundation 2.0 root hub 
    USB:		[1d6b:0003]		 Bus 012 Device 001                       Linux Foundation 3.0 root hub 

    ```
