# How to Build a Raspberry Pi Cluster

![Header Image](images/header.png)

I know what you are asking. "Why ANOTHER guide to setting up a Raspberry
Pi cluster?" Because I couldn't find one that provided a step-by-step
guide that included all of the features I wanted. I had to piece together
these steps from mulitple guides across the internet. So, I put this
step-by-step together for myself and for others. I have included both
the manual steps and Ansible scripts so you can use either method to
setup your cluster. All Ansible scripts should be run from your localhost.

## What we are going to build

In this tutorial, we are going to build a 12-node cluster. The purpose
of this cluster is for a home lab learning environment, and not intended
to be used in a full scale production environment. As such, some shortcuts
have been made. These will be pointed out in the appropriate places.

All of the nodes will be powered using Power over Ethernet, and other
than the first node, will be booted using network booting. The first node
will be booted off of an SSD.

The first node will be referred to as the head node. It will run a
variety of utilities that will be useful for the cluster. The utilities
shown in this tutorial will be the follow:

-   DNS Server (for domain name resolution on the cluster)
-   DHCP Server (for IP address assignment on the cluster)
-   TFTP Server (for network booting on the cluster)

The rest of the nodes will be used for the Hashistack. We will use 3 nodes
for the servers and 8 nodes for the clients. The server
nodes will be named server1, server2, and server3. The client nodes will
be named client1 to client8.

Check the [Inventory](../inventory.yaml) for a list of the nodes

## What you will need

### Hardware

-   12 x Raspberry Pi 4
-   12 x Raspberry Pi PoE+ HAT
-   12 x Ethernet cables
-   12-port Gigabit PoE-enabled switch
-   USB 3 to Gigabit Ethernet adapter
-   USB 3 External SSD
-   Minimum 16 GB micro SD card
-   [Raspberry Pi 4/5 2U rack-mount bracket](https://www.thingiverse.com/thing:4078710)
    -   Disclaimer: This is not my design. I just used it for my own build
    -   I also customized it to use the 13 tray design. The can find the
        customized version in the [STLs](../STLs/) directory. The extra
        tray uses my [Hard Drive Mount](../STLs/raspberry-pi-rack-tray-ssd.stl)
        to hold the SSD
-   A couple zip ties to attach the SSD to the tray
-   Micro HDMI to HDMI cable
    -   Will be useful for debugging during setup, not required for normal operation
-   USB Keyboard
    -   Will be useful for debugging during setup, not required for normal operation

### Software

-   [Raspberry Pi Imager software](https://www.raspberrypi.com/software/)
-   SSH Client
-   Ansible (optional, only needed if using the Ansible scripts)

## Next Step

[Initial Setup](01_initial_setup.md)

## Reference Links

https://www.thingiverse.com/thing:4078710

## Reference Links

-   https://www.thingiverse.com/thing:4078710
-   https://www.raspberrypi.com/tutorials/cluster-raspberry-pi-tutorial/
-   https://netbeez.net/blog/how-to-set-up-dns-server-dnsmasq/
-   https://netbeez.net/blog/how-to-set-up-dns-server-dnsmasq-part-4/
-   https://netbeez.net/blog/read-only-tftp-dnsmasq/
-   https://linuxconfig.org/how-to-configure-a-raspberry-pi-as-a-pxe-boot-server
-   https://raspberrypi.stackexchange.com/questions/87262/netbooting-multiple-workers-rpi-from-a-master-rpi
-   https://linux-tips.com/t/dnsmasq-show-ip-lease-information/231
-   https://github.com/imthenachoman/How-To-Secure-A-Linux-Server?tab=readme-ov-file#the-network
-   https://unix.stackexchange.com/questions/575178/sharing-wifi-internet-through-ethernet-interface
-   https://www.digitalocean.com/community/tutorials/how-to-set-up-and-configure-a-certificate-authority-ca-on-ubuntu-20-04
-   https://easy-rsa.readthedocs.io/en/latest/intro-to-PKI/
-   https://www.digitalocean.com/community/tutorials/how-to-set-up-and-configure-an-openvpn-server-on-ubuntu-20-04

## TODO

-   [ ] Expand the explaination on all the steps
-   [ ] Add the steps to configure the OpenVPN client for each of the OSes
-   [ ] Move the Certificate Authority server off of the head node
