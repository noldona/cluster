# Initial Setup

## Step 1: Setup SSH config on your local machine

This SSH config will be used to SSH into the various cluster nodes in the
following steps. If you are using the Ansible playbooks, they will also
use this config to connect to them.

If you do not already have an SSH key created, run to following on your
localhost to generate a new key.

```bash
ssh-keygen -t ed25519
```

For the next step, we will need an unused IP address on your home network
that will be used to connect to the head node. We will refer to this as
`{{ head_node_ip }}` in the following documention. If you plan on using the
Ansible playbooks, update the `head_node_ip` variable in the
[General Main Vars File](../../vars/general/main.yaml) with this value as well.
You may also need to update the `head_node_gateway` variable as well if
your network does not use the 192.168.1.1/24 network addressing.

The variable `{{ username }}` is the username you will use when you setup
the Raspberry Pis. This should be updated in the
[General Main Vars File](../../vars/general/main.yaml) as well.

Additionally, many of the following steps will reference the various nodes.
Each node has a hostname, IP address, and MAC address associated with it.
These are set in the [General Main Vars File](../../vars/general/main.yaml)
for use in the Ansible scripts. The default values are the following,
and you will obtain the MAC addresses for your Raspberry Pis during the
[Configure DNS/DHCP/TFTP Step 2](02_dns_dhcp_tftp.md#step-2-get-the-mac-addresses).

| Hostname | Address   | MAC Address       |
| -------- | --------- | ----------------- |
| server1  | 10.0.0.2  | d8:38:dd:a7:34:33 |
| server2  | 10.0.0.3  | d8:38:dd:a7:34:79 |
| server3  | 10.0.0.4  | d8:38:dd:a7:34:fb |
| client1  | 10.0.0.5  | d8:38:dd:a7:33:e1 |
| client2  | 10.0.0.6  | d8:38:dd:a7:34:b2 |
| client3  | 10.0.0.7  | d8:38:dd:a7:33:ac |
| client4  | 10.0.0.8  | d8:38:dd:a7:34:3c |
| client5  | 10.0.0.9  | d8:38:dd:a7:34:46 |
| client6  | 10.0.0.10 | d8:38:dd:a7:33:0d |
| client7  | 10.0.0.11 | d8:38:dd:a7:33:e5 |
| client8  | 10.0.0.12 | d8:38:dd:a7:34:49 |

Add the following into your `~/.ssh/config` file on your localhost:

```
Host head
	HostName {{ head_node_ip }}
	User {{ username }}
	Port 22
	IdentityFile ~/.ssh/id_ed25519
Host {{ server1.hostname }}
	HostName {{ server1.address }}
	User {{ username }}
	Port 22
	IdentityFile ~/.ssh/id_ed25519
	ProxyCommand ssh head -W %h:%p
Host {{ server2.hostname }}
	HostName {{ server2.address }}
	User {{ username }}
	Port 22
	IdentityFile ~/.ssh/id_ed25519
	ProxyCommand ssh head -W %h:%p
Host {{ server3.hostname }}
	HostName {{ server3.address }}
	User {{ username }}
	Port 22
	IdentityFile ~/.ssh/id_ed25519
	ProxyCommand ssh head -W %h:%p
Host {{ client1.hostname }}
	HostName {{ client1.address }}
	User {{ username }}
	Port 22
	IdentityFile ~/.ssh/id_ed25519
	ProxyCommand ssh head -W %h:%p
Host {{ client2.hostname }}
	HostName {{ client2.address }}
	User {{ username }}
	Port 22
	IdentityFile ~/.ssh/id_ed25519
	ProxyCommand ssh head -W %h:%p
Host {{ client3.hostname }}
	HostName {{ client3.address }}
	User {{ username }}
	Port 22
	IdentityFile ~/.ssh/id_ed25519
	ProxyCommand ssh head -W %h:%p
Host {{ client4.hostname }}
	HostName {{ client4.address }}
	User {{ username }}
	Port 22
	IdentityFile ~/.ssh/id_ed25519
	ProxyCommand ssh head -W %h:%p
Host {{ client5.hostname }}
	HostName {{ client5.address }}
	User {{ username }}
	Port 22
	IdentityFile ~/.ssh/id_ed25519
	ProxyCommand ssh head -W %h:%p
Host {{ client6.hostname }}
	HostName {{ client6.address }}
	User {{ username }}
	Port 22
	IdentityFile ~/.ssh/id_ed25519
	ProxyCommand ssh head -W %h:%p
Host {{ client7.hostname }}
	HostName {{ client7.address }}
	User {{ username }}
	Port 22
	IdentityFile ~/.ssh/id_ed25519
	ProxyCommand ssh head -W %h:%p
Host {{ client8.hostname }}
	HostName {{ client8.address }}
	User {{ username }}
	Port 22
	IdentityFile ~/.ssh/id_ed25519
	ProxyCommand ssh head -W %h:%p
```

## Step 2: Configure your Raspberry Pi

To start, follow the [Getting Started documentaiton to setup your Raspberry Pi](https://www.raspberrypi.com/documentation/computers/getting-started.html#installing-the-operating-system).
For your operating system, choose Other general-purpose OS > Ubuntu >
Ubuntu Server 24.02.1 LTS (64-bit).

Instead of an SD card, choose the SSD as your destination. This will be
the SSD the head node boots from.

During the OS customization stage, edit the settings as follows:

-   Enter a hostname
    -   For this tutorial, we are going to use `head`
-   Enter a username and password
    -   Use the `{{ username }}` value as the username here
    -   Whatever name you choose will be used on all of the Hashistack
        nodes as well
-   Do NOT enable the WiFi option
    -   This is not enabled as we will be using this as a basis for the
        Hashistack nodes and don't want WiFi enabled on them as we will
        be routing all the traffic through the head node for security
        purposes. You can add the settings later if you want.
-   Enable SSH with key pair with id_ed25519.pub contents

## Step 3: Create SD card

After this finishes, write the same image to the micro SD card. This card
will be use temporarily to setup the nodes to boot from the network.
Using the same OS customization settings is fine as this will only be used
temporarily. I set my hostname to `client` just to help keep track.

## Step 4: Build your head node

### Step 4.1: Setup Static IP Address for head node

We will be setting up static IP addresses for the head node. The eth0
interface will be used to communicate with the rest of the cluster that
will all be on the 10.0.0.0/24 network. The eth1 interface will be used
to communicate with the rest of your home network which is being assumed
to run on the 192.168.1.1/24 network. You may need to adjust the IP
addresses apporpriate for your network setup. For the eth1 interface,
choose an unused IP address on your network to set this statically to.

On the head node, run the following to set the static IP addresses for
both network interfaces.

```bash
sudo apt update
sudo apt -y full-upgrade
sudo cat > /etc/network/interfaces.d/etho0 << EOF
auto eth0
iface eth0 inet static
address 10.0.0.1
netmask 255.255.255.0
gateway 10.0.0.1
dns-nameservers = 10.0.0.1
EOF
sudo cat > /etc/network/interfaces.d/eth1 << EOF
auto eth1
iface eth1 inet static
address {{ head_node_ip }}
netmask 255.255.255.0
gateway <head_node_gateway>
dns-nameservers = {{ head_node_gateway }}
EOF
sudo reboot
```

### Step 4.2: Setup drive for the Hashistack nodes

> [!NOTE]  
> **_Ansible Script:_** [01_setup_hashistack_nodes.yaml](../01_setup_hashistack_nodes.yaml)

#### Most noticable / important variables

| Variable          | Default value  | Description                             |
| ----------------- | -------------- | --------------------------------------- |
| username          | `pi`           | The username used on the cluster        |
| head_node_ip      | `192.168.1.31` | The IP address for the head node        |
| head_node_gateway | `192.168.1.1`  | The Gateway IP address for home network |

#### Variable Files

-   vars/general/main.yaml
-   vars/general/head.yaml

If you are using Ansible, set these variables appropriately, and run the
script now. Once it is done, go to [Step 4.3](#step-33-clear-ssh-keys-from-hashistack-nodes).

If you want to run the steps manually, continue here. Each of these steps
need to be run on the head node for each of the Hashistack nodes. The
nodes are listed above in [Step 1](#step-1-setup-ssh-config-on-your-local-machine)

We will be copying over the system files from the head node to the
directories that will be used for the network booting of the Hashistack nodes.

First, we create a the `/nfs/{{ node.hostname }}` directory which will contain the
files for the node.

```bash
sudo mkdir -p /nfs/{{ node.hostname }}
sudo chmod -R 777 /nfs
```

We then copy over everything from the head node into the `/nfs/{{ node.hostname }}`
directory except the `/nfs` directory for obvious reasons.

```bash
sudo rsync -xa --exclude /nfs / /nfs/{{ node.hostname }}
```

We then need to remove the unneeded setting for eth1, as the {{ node.hostname }} node
won't have an eth1 network interface. We also need to update the static
IP address for the eth0 network interface, hostname, hosts files to
contain the correct info for the {{ node.hostname }} node.

```bash
sudo rm /nfs/{{ node.hostname }}/etc/network/interfaces.d/eth1
sudo sed -i 's/address 10.0.0.1/address {{ node.address }}/' /nfs/{{ node.hostname }}/etc/network/interfaces.d/eth0
sudo sed -i 's/head/{{ node.hostname }}/' /nfs/{{ node.hostname }}/etc/hostname
sudo sed -i 's/head/{{ node.hostname }}/g' /nfs/{{ node.hostname }}/etc/hosts
```

Next, we are going to update the `/etc/resolv.conf` file for {{ node.hostname }} to
set it to do name resolution using the head node

```bash
sudo sed -i 's/192.168.1.1/10.0.0.1' /nfs/{{ node.hostname }}/etc/resolv.conf
```

Finally, we need to remove the partition points since they won't be used
with the network booting.

```bash
sudo sed -i 's/^PARTUUID=.*$//g' /nfs/{{ node.hostname }}/etc/fstab
```

### Step 4.3: Clear SSH Keys from Hashistack Nodes

We then need to execute some commands in the new nodes before we can
start the new node. To do this, we are going to use systemd-container.
It works similar to chroot, but more powerful.

> **_NOTE:_** This and the following step have to be run manually, due to Ansible
> not having a module for systemd-nspawn

```bash
sudo systemd-nspawn -D /nfs/{{ node.hostname }} /sbin/init
```

Login to the system container and run the following commands. These will
create new SSH2 server keys. It will also try to start the ssh.service,
but it will fail due to being run in a container and the network interface
is already in use. This is expected and fine. It will work start fine on
its own hardware.

```bash
sudo rm /etc/ssh/ssh_host_*
sudo dpkg-reconfigure openssh-server
logout
```

To exit the container, press `CTRL+]` 3 times.

## Next Step

[Configure DNS/DHCP/TFTP server](02_dns_dhcp_tftp.md)

## Reference Links

-   https://www.raspberrypi.com/tutorials/cluster-raspberry-pi-tutorial/
