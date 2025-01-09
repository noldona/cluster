# How To Build a Raspberry Pi Cluster

![Header Image]()

I know what you are asking. "Why ANOTHER guide to setting up a Raspberry
Pi cluster?" Because I couldn't find one that provided a step-by-step
guide for setting one up using Dnsmasq. I had to piece together the steps
from multiple guides across the internet. So, I put this step-by-step
together for myself and for others.

## What we are going to build

![Image of cluster networking structure]()

In this tutorial, we are going to build a 12-node cluster. However, you
can scale this to whatever size you want. A simple 3-node cluster is a
good starting point and you can add additional nodes later as time/money
permit. The 12-node cluster was chosen because of the selected rack mount
being used.

The first node will be the head node. It will run a variety of utilities
that will be useful for the cluster. The utilities shown in this tutorial
will be the following:

-   DNS Server
-   DHCP Server
-   TFTP Server
-   NGINX Reverse Proxy
-   Bastion Host

The rest of the nodes will be used for a Hashistack cluster with 3 servers
and 7 client nodes. The details for setting this up will be given in the
[Hashistack](docs/hashistack.md) file.

## What you will need

### Supplies

-   12 x Raspberry Pi 4
-   12 x Raspberry Pi PoE+ HAT
-   12 x Ethernet cables
-   12-port Gigabit PoE-enabled switch
-   USB 3 to Gigabit Ethernet adapter
-   USB 3 External SSD
-   Minimum 16 GB micro SD card
-   [Raspberry Pi 4/5 2U rack-mount bracket](https://www.thingiverse.com/thing:4078710)
    -   Disclaimer: This is not my design, I just used it for my own build
    -   I also customized it to use the 13 tray design. The extra tray uses
        my [Hard Drive Mount]() to hold the SSD
-   Micro HDMI to HDMI cable
    -   Will be useful for debugging during setup, not required for normal operation
-   USB Keyboard
    -   Will be useful for debugging during setup, not required for normal operation

## Configure your Raspberry Pi

To start, follow the [Getting Started documentaiton to setup your Raspberry Pi](https://www.raspberrypi.com/documentation/computers/getting-started.html#installing-the-operating-system).
For your operating system, choose Raspberry Pi OS (other) > Raspberry Pi OS Lite (64-bit)
to run headless.

Instead of an SD card, choose the SSD as your destination.

During the OS customization stage, edit the settings as follows:

-   Enter a hostname
    -   For this tutorial, we are going to use _head_
-   Enter a username and password
    -   For this tutorial, we are going to use _pi_ as the username
    -   Whatever name you choose will the be used on all of the workers as well
-   Do NOT enable the WiFi option
    -   This is not enabled as we will be using this as a basis for the worker nodes
        and don't want WiFi enabled on the worker nodes for security purposes, you can
        add the settings later if you want
-   Enable SSH with key pair

## Build your head node

### Set Static IP Address

```bash
sudo su
apt update
apt -y full-upgrade
cat > /etc/network/interfaces.d/eth0 << EOF
auto eth0
iface eth0 inet static
address 10.0.0.1
netmask 255.255.255.0
gateway 10.0.0.1
dns-nameservers = 10.0.0.1
EOF
cat > /etc/network/interfaces.d/eth1 << EOF
auto eth0
iface eth0 inet static
address 192.168.1.31
netmask 255.255.255.0
gateway 192.168.1.1
dns-nameservers = 192.168.1.1
EOF
reboot
```

Update the IP address for eth1 to an IP address not currently in use on
your regular network.

### Set drive for worker1

```bash
sudo su
mkdir -p /nfs/worker1
chmod -R 777 /nfs
rsync -xa --exclude /nfs / /nfs/worker1
rm /nfs/worker1/etc/network/interfaces.d/eth1
sed -i 's/address 10.0.0.1/address 10.0.0.2/' /nfs/worker1/etc/network/interfaces.d/eth0
sed -i 's/head/worker1/' /nfs/worker1/etc/hostname
sed -i 's/head/worker1/g' /nfs/worker1/etc/hosts
sed -i 's/192.168.1.1/10.0.0.1/' /nfs/worker1/etc/resolv.conf
apt -y install systemd-container
systemd-nspawn -D /nfs/worker1 /sbin/init
sudo rm /etc/ssh/ssh_host_*
sudo dpkg-reconfigure openssh-server
logout
```

`CTRL+]` short 3 times

## Configure DNS/DHCP/TFTP server

```bash
apt -y install dnsmasq tcpdump nfs-kernel-server
tcpdump -i eth0 port bootpc
```

Boot worker1 node without an SD card and look for the request from the node
Grab the MAC address for the node (i.e. d8:3a:dd:a7:34:33)

```bash
cat > /etc/dnsmasq.conf << EOF
domain-needed
bogus-priv
strict-order
no-resolv
server=192.168.1.1
server=8.8.8.8
server=4.4.4.4
address=/head.cluster/10.0.0.1
address=/worker1.cluster/10.0.0.2
address=/worker2.cluster/10.0.0.3
address=/worker3.cluster/10.0.0.4
address=/worker4.cluster/10.0.0.5
address=/worker5.cluster/10.0.0.6
address=/worker6.cluster/10.0.0.7
address=/worker7.cluster/10.0.0.8
address=/worker8.cluster/10.0.0.9
address=/worker9.cluster/10.0.0.10
address=/worker10.cluster/10.0.0.11
address=/worker11.cluster/10.0.0.12
address=/rivercrest.cluster/10.0.0.2
address=/.cluster/10.0.0.1
address-/.consul/10.0.0.2
interface=eth0
interface=tun0
expand-hosts
domain=cluster
dhcp-range=10.0.0.50,10.0.0.150,12h
dhcp-range-10.0.0.0,static
dhcp=host=d8:3a:dd:a7:34:33,worker1,10.0.0.2,infinite
dhcp=host=d8:3a:dd:a7:34:79,worker2,10.0.0.2,infinite
dhcp=host=d8:3a:dd:a7:34:fb,worker3,10.0.0.2,infinite
dhcp=host=d8:3a:dd:a7:33:e1,worker4,10.0.0.2,infinite
dhcp=host=d8:3a:dd:a7:34:b2,worker5,10.0.0.2,infinite
dhcp=host=d8:3a:dd:a7:33:ac,worker6,10.0.0.2,infinite
dhcp=host=d8:3a:dd:a7:34:3c,worker7,10.0.0.2,infinite
dhcp=host=d8:3a:dd:a7:34:46,worker8,10.0.0.2,infinite
dhcp=host=d8:3a:dd:a7:33:0d,worker9,10.0.0.2,infinite
dhcp=host=d8:3a:dd:a7:33:e5,worker10,10.0.0.2,infinite
dhcp=host=d8:3a:dd:a7:34:49,worker11,10.0.0.2,infinite
pxe-service=0,"Raspberry Pi Boot"
enable-tftp
tftp-root=/tftpboot
tftp-unique-root=mac
EOF

mkdir -p /tftpboot/d8-3a-dd-a7-34-33
cp -r /boot/firmware/* /tftpboot/d8-3a-dd-a7-34-33
sed -i 's/root=.*$/root=\/dev\/nfs nfsroot=10.0.0.1:\/nfs\/worker1,vers=3 rw ip=dhcp rootwait elevator=deadline/' /tftpboot/d8-3a-dd-a7-34-79/cmdline.txt
```

```bash
chmod -R 777 /tftpboot
systemctl enable dnsmasq.service
systemctl restart dnsmasq.service
echo "/nfs *(rw,sync,no_subtree_check,no_root_squash)" | tee -a /etc/exports
systemctl enable rpcbind
systemctl restart rpcbind
systemctl enable nfs-kernel-server
systemctl restart nfs-kernel-server
```

Edit `/nfs/worker1/etc/fstab` and remove or comment the `PARTUUID=` lines

```bash
exit
```

### Configure SSH

```bash
ssh-keygen -t rsa
cat ~/.ssh/id_rsa.pub | tee -a /nfs/worker1/home/pi/.ssh/authorized_keys > /dev/null
cat > ~/.ssh/config << EOF
Host worker1
	User pi
	Port 22
	HostName 10.0.0.2
	IdentityFile ~/.ssh/id_rsa
	IdentitiesOnly yes
Host worker2
	User pi
	Port 22
	HostName 10.0.0.3
	IdentityFile ~/.ssh/id_rsa
	IdentitiesOnly yes
Host worker3
	User pi
	Port 22
	HostName 10.0.0.4
	IdentityFile ~/.ssh/id_rsa
	IdentitiesOnly yes
Host worker4
	User pi
	Port 22
	HostName 10.0.0.5
	IdentityFile ~/.ssh/id_rsa
	IdentitiesOnly yes
Host worker5
	User pi
	Port 22
	HostName 10.0.0.6
	IdentityFile ~/.ssh/id_rsa
	IdentitiesOnly yes
Host worker6
	User pi
	Port 22
	HostName 10.0.0.7
	IdentityFile ~/.ssh/id_rsa
	IdentitiesOnly yes
Host worker7
	User pi
	Port 22
	HostName 10.0.0.8
	IdentityFile ~/.ssh/id_rsa
	IdentitiesOnly yes
Host worker8
	User pi
	Port 22
	HostName 10.0.0.9
	IdentityFile ~/.ssh/id_rsa
	IdentitiesOnly yes
Host worker9
	User pi
	Port 22
	HostName 10.0.0.10
	IdentityFile ~/.ssh/id_rsa
	IdentitiesOnly yes
Host worker10
	User pi
	Port 22
	HostName 10.0.0.11
	IdentityFile ~/.ssh/id_rsa
	IdentitiesOnly yes
Host worker11
	User pi
	Port 22
	HostName 10.0.0.12
	IdentityFile ~/.ssh/id_rsa
	IdentitiesOnly yes
EOF
```

```bash
cat /var/lib/misc/dnsmasq.leases
journalctl --unit dnsmasq.service --follow
```

## Add First Node

Using the Raspberry Pi Imager software, create an SD card. This will be
used to temporarily boot the Raspberry Pi to set it to boot from the network.

During the OS customization stage, edit the settings as follows:

-   Enter a hostname
    -   For this tutorial, we are going to use _worker_
-   Enter a username and password
    -   For this tutorial, we are going to use _pi_ as the username
    -   Whatever name you choose will the be used on all of the workers as well
-   Do NOT enable the WiFi
-   Enable SSH with username/password

```bash
sudo tcpdump -i eth0 port bootpc
```

Boot the node using the SD card and note the IP address and MAC address

SSH to the IP address

```bash
sudo raspi-config
```

Go to Advanced Settings -> Boot Order and Select the Network Boot option

```bash
sudo reboot
```

After it reboots

```bash
sudo shutdown now
```

On the Head node run

```bash
journalctl --unit dnsmasq.service --follow
```

Remove the SD card and plug the worker node back in
It should automatically boot with the IP address of 10.0.0.2.

The IP Address should show in the journal, and can also be verified by

```bash
cat /var/lib/misc/dnsmasq.leases
```

## Add Second Node

```bash
sudo tcpdump -i eth0 port bootpc
```

Boot the second node with the previous made SD card and note the IP
address and MAC address

SSH to the IP address

```bash
sudo raspi-config
```

Go to Advanced Options -> Boot Order and Select the Network Boot option
Select Finish and the say No to the reboot

```bash
sudo shutdown now
```

Remove the SD card

On the Head node run

```bash
sudo su
mkdir -p /nfs/worker2
rsync -xa /nfs/worker1/* /nfs/worker2
sed -i 's/10.0.0.2/10.0.0.3/' /nfs/worker2/etc/network/interfaces.d/eth0
sed -i 's/worker1/worker2/' /nfs/worker2/etc/hostname
sed -i 's/worker1/worker2/g' /nfs/worker2/etc/hosts
systemd-nspawn -D /nfs/worker2 /sbin/init
sudo rm /etc/ssh/ssh_host_*
sudo dpkg-reconfigure openssh-server
logout
```

`CTRL+]` short 3 times

```bash
cat "dhcp=host=d8:3a:dd:a7:34:79,worker2,10.0.0.3,infinite" | tee -a /etc/dnsmasq.conf
systemctl restart dnsmasq.service
mkdir -p /tftpboot/d8-3a-dd-a7-34-79
cp -r /boot/firmware/* /tftpboot/d8-3a-dd-a7-34-79
sed -i 's/root=.*$/root=\/dev\/nfs nfsroot=10.0.0.1:\/nfs\/worker2,vers=3 rw ip=dhcp rootwait elevator=deadline/' /tftpboot/d8-3a-dd-a7-34-79/cmdline.txt
exit
```

## Add Additional Nodes

For each additional node, follow the steps for the second node.
Replace:

-   `worker2` for the appropriate numbered worker hostname
-   `10.0.0.3` with the appropriate IP address
-   `d8:3a:dd:a7:34:79` with the appropriate MAC Address

Example listing of values, make sure to use the correct ones for your devices
| Node HostName | MAC Address | IP Address |
| --- | --- | --- |
| worker1 | d8:3a:dd:a7:34:33 | 10.0.0.2 |
| worker2 | d8:3a:dd:a7:34:79 | 10.0.0.3 |
| worker3 | d8:3a:dd:a7:34:fb | 10.0.0.4 |
| worker4 | d8:3a:dd:a7:33:e1 | 10.0.0.5 |
| worker5 | d8:3a:dd:a7:34:b2 | 10.0.0.6 |
| worker6 | d8:3a:dd:a7:33:ac | 10.0.0.7 |
| worker7 | d8:3a:dd:a7:34:3c | 10.0.0.8 |
| worker8 | d8:3a:dd:a7:34:46 | 10.0.0.9 |
| worker9 | d8:3a:dd:a7:33:0d | 10.0.0.10 |
| worker10 | d8:3a:dd:a7:33:e5 | 10.0.0.11 |
| worker11 | d8:3a:dd:a7:34:49 | 10.0.0.12 |

## SSH Config

It may be useful to be able to SSH directly to one of the worker nodes.
This can be done by configuring SSH on your machine to proxy through the
head node to reach the worker nodes.

```
Host head
	User pi
	Port 22
	HostName 192.168.1.31
	IdentityFile ~/.ssh/id_rsa
	IdentitiesOnly yes
	PubKeyAuthentication yes
Host worker1
	User pi
	Port 22
	HostName 10.0.0.2
	ProxyCommand ssh head -W %h:%p
Host worker2
	User pi
	Port 22
	HostName 10.0.0.3
	ProxyCommand ssh head -W %h:%p
Host worker3
	User pi
	Port 22
	HostName 10.0.0.4
	ProxyCommand ssh head -W %h:%p
Host worker4
	User pi
	Port 22
	HostName 10.0.0.5
	ProxyCommand ssh head -W %h:%p
Host worker5
	User pi
	Port 22
	HostName 10.0.0.6
	ProxyCommand ssh head -W %h:%p
Host worker6
	User pi
	Port 22
	HostName 10.0.0.7
	ProxyCommand ssh head -W %h:%p
Host worker7
	User pi
	Port 22
	HostName 10.0.0.8
	ProxyCommand ssh head -W %h:%p
Host worker8
	User pi
	Port 22
	HostName 10.0.0.9
	ProxyCommand ssh head -W %h:%p
Host worker9
	User pi
	Port 22
	HostName 10.0.0.10
	ProxyCommand ssh head -W %h:%p
Host worker10
	User pi
	Port 22
	HostName 10.0.0.11
	ProxyCommand ssh head -W %h:%p
Host worker11
	User pi
	Port 22
	HostName 10.0.0.12
	ProxyCommand ssh head -W %h:%p
```

Be sure to update the HotName for head to whatever IP address you set the
eth1 interface to use.

## What's Next?

Now that your cluster is fully setup, you can use it for whatever you
decided to set it up for. Follow the links below for some examples.

[Secure your servers](https://github.com/imthenachoman/How-To-Secure-A-Linux-Server?tab=readme-ov-file#the-network)  
[Terraform/Consul/Nomad/Vault](docs/hashistack.md)

## Reference Links

https://www.thingiverse.com/thing:4078710

https://www.raspberrypi.com/tutorials/cluster-raspberry-pi-tutorial/

https://netbeez.net/blog/how-to-set-up-dns-server-dnsmasq/

https://netbeez.net/blog/how-to-set-up-dns-server-dnsmasq-part-4/

https://netbeez.net/blog/read-only-tftp-dnsmasq/

https://linuxconfig.org/how-to-configure-a-raspberry-pi-as-a-pxe-boot-server

https://raspberrypi.stackexchange.com/questions/87262/netbooting-multiple-workers-rpi-from-a-master-rpi

https://github.com/imthenachoman/How-To-Secure-A-Linux-Server?tab=readme-ov-file#the-network

https://linux-tips.com/t/dnsmasq-show-ip-lease-information/231

https://www.digitalocean.com/community/tutorials/how-to-set-up-and-configure-a-certificate-authority-ca-on-ubuntu-20-04

https://www.digitalocean.com/community/tutorials/how-to-set-up-and-configure-an-openvpn-server-on-ubuntu-20-04
