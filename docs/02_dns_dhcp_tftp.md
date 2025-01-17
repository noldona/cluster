# Configure DNS/DHCP/TFTP server

We will configure DNSMasq to act as our DNS, DHCP, and TFTP servers since
it can handle all of them. We will also need an NFS server to serve the
system files. For that we will be using nfs-kernel-server. Additionally,
since we will be assigning IP addresses by MAC address, we will need
tcpdump to get those.

## Step 1: Setup the Hashistack nodes for network booting

On each of the Hashistack nodes, boot the system with the micro SD card
you created during the [Initial Setup](01_initial_setup.md#step-3-create-sd-card).
When the node boots, we need to set the boot order.

```bash
sudo -E rpi-eeprom-config --edit
```

Edit the BOOT_ORDER value to `0xf2461`. This will add network booting to
the end of the list as detailed in the
[Raspberry Pi Documentation](https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#raspberry-pi-bootloader-configuration)
so it will attempt to boot from the network after checking for the SD card,
NVME, and USB-MSD methods first.

The reboot the system to apply the changes.

```bash
sudo reboot
```

Once the system has rebooted, you can shut down the node.

```bash
sudo shutdown now
```

## Step 2: Get the MAC addresses

If you are using the Ansible scripts, the required software will have
been installed at the end of the [Initial Setup](01_initial_setup.md#step-41-setup-static-ip-address-for-head-node).

If you are following the steps manually, install the required software
and start the tcpdump so we can watch for the MAC addresses on the head
node.

```bash
sudo apt -y install dnsmasq tcpdump nfs-kernel-server
sudo tcpdump -i eth0 port bootpc
```

One by one, boot the nodes without an SD card. You should see the MAC
address show in the tpcdump log. It should look something like
d8:3a:dd:a7:34:33. Make note of the MAC addresses for each of the nodes.
Update the [General Main Vars File](../../vars/general/main.yaml) in the
`nodes.mac_address` variables.

> [!NOTE]  
> **_Ansible Script:_** [02_dns_dhcp_tftp.yaml](../02_dns_dhcp_tftp.yaml)

#### Most noticable / important variables

| Variable          | Description                                            |
| ----------------- | ------------------------------------------------------ |
| nodes             | A list of the Hashistack nodes                         |
| nodes.hostname    | The hostname of the node                               |
| nodes.address     | The IP Address of the node                             |
| nodes.mac_address | The MAC Address of the node found in the previous step |

#### Variable Files

-   vars/general/main.yaml
-   vars/general/dns.yaml

If you are running the Ansible script, esnure the MAC addresses are set
and run the script now. Once it is done, go to [Step 5](#step-5-start-the-hashistack-nodes).

If you want to run the steps manually, continue here.

## Step 3: Configure DNSMasq

With the MAC addresses, we will now configure the server.

```bash
sudo cat > /etc/dnsmasq.conf << EOF
domain-needed
bogus-priv
strict-order
no-resolv
server={{ head_node_gateway }}
server=8.8.8.8
server=4.4.4.4
address=/head.cluster/10.0.0.1
address=/{{ server1.hostname }}.cluster/{{ server1.address }}
address=/{{ server2.hostname }}.cluster/{{ server2.address }}
address=/{{ server3.hostname }}.cluster/{{ server3.address }}
address=/{{ client1.hostname }}.cluster/{{ client1.address }}
address=/{{ client2.hostname }}.cluster/{{ client2.address }}
address=/{{ client3.hostname }}.cluster/{{ client3.address }}
address=/{{ client4.hostname }}.cluster/{{ client4.address }}
address=/{{ client5.hostname }}.cluster/{{ client5.address }}
address=/{{ client6.hostname }}.cluster/{{ client6.address }}
address=/{{ client7.hostname }}.cluster/{{ client7.address }}
address=/{{ client8.hostname }}.cluster/{{ client8.address }}
address=/.cluster/10.0.0.1
address-/.consul/{{ server1.address }}
interface=eth0
interface=tun0
expand-hosts
domain=cluster
dhcp-range=10.0.0.50,10.0.0.150,12h
dhcp-range-10.0.0.0,static
dhcp=host={{ server1.mac_address }},{{ server1.hostname }},{{ server1.address }},infinite
dhcp=host={{ server2.mac_address }},{{ server2.hostname }},{{ server2.address }},infinite
dhcp=host={{ server3.mac_address }},{{ server3.hostname }},{{ server3.address }},infinite
dhcp=host={{ client1.mac_address }},{{ client1.hostname }},{{ client1.address }},infinite
dhcp=host={{ client2.mac_address }},{{ client2.hostname }},{{ client2.address }},infinite
dhcp=host={{ client3.mac_address }},{{ client3.hostname }},{{ client3.address }},infinite
dhcp=host={{ client4.mac_address }},{{ client4.hostname }},{{ client4.address }},infinite
dhcp=host={{ client5.mac_address }},{{ client5.hostname }},{{ client5.address }},infinite
dhcp=host={{ client6.mac_address }},{{ client6.hostname }},{{ client6.address }},infinite
dhcp=host={{ client7.mac_address }},{{ client7.hostname }},{{ client7.address }},infinite
dhcp=host={{ client8.mac_address }},{{ client8.hostname }},{{ client8.address }},infinite
pxe-service=0,"Raspberry Pi Boot"
enable-tftp
tftp-root=/tftpboot
tftp-unique-root=mac
EOF
```

## Step 4: Create the boot folders

Next we need to create the where the nodes will look for the boot files in.
These steps need to be run for each of the nodes.

```bash
mkdir -p /tftpboot/{{ node.mac_address }}
cp -r /boot/firmware/* /tftpboot/{{ node.mac_address }}
sed -i 's/root=.*$/root=\/dev\/nfs nfsroot=10.0.0.1:\/nfs\/{{ node.hostname }},vers=3 rw ip=dhcp rootwait elevator=deadline/' /tftpboot/{{ node.mac_address }}/cmdline.txt
```

Next, we will set the permissions for the boot directories and restart
DNSMasq to pick up the changes

```bash
chmod -R 777 /tftpboot
systemctl enable dnsmasq.service
systemctl restart dnsmasq.service
```

Then, we need to export the files systems to NFS, so they are avaible to
the nodes to use. And then restart the services to pick up the changes.

```bash
echo "/nfs *(rw,sync,no_subtree_check,no_root_squash)" | tee -a /etc/exports
systemctl enable rpcbind
systemctl restart rpcbind
systemctl enable nfs-kernel-server
systemctl restart nfs-kernel-server
```

## Step 5: Start the Hashistack nodes

Now, you can start up each of the Hashistack nodes without an SD card,
and they should boot up using the network boot.

On the head node, you can run the following to watch as each node boots
up and gets assigned the appropriate IP address.

```bash
journalctl --unit dnsmasq.service --follow
```

## Next Step

[Configure SSH](03_configure_ssh.md)

## Refence Links

-   https://netbeez.net/blog/how-to-set-up-dns-server-dnsmasq/
-   https://netbeez.net/blog/how-to-set-up-dns-server-dnsmasq-part-4/
-   https://netbeez.net/blog/read-only-tftp-dnsmasq/
-   https://linuxconfig.org/how-to-configure-a-raspberry-pi-as-a-pxe-boot-server
-   https://raspberrypi.stackexchange.com/questions/87262/netbooting-multiple-workers-rpi-from-a-master-rpi
-   https://linux-tips.com/t/dnsmasq-show-ip-lease-information/231
